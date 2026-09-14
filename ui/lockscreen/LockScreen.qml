pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/*
    LockScreen — point d'entrée du lockscreen, intégré au shell principal
    (chargé depuis shell.qml, pas de process séparé).

    Usage typique depuis shell.qml :

        import qs.ui.lockscreen
        LockScreen { id: lockScreen }

    Et depuis n'importe où dans le shell (ex: MenuBar -> AppleMenu.onLockRequested,
    ou un raccourci clavier) :

        lockScreen.lock()

    Intégration système (hypridle) :
    Pour que `loginctl lock-session` / le `lock_cmd` de hypridle déclenchent
    ce lockscreen, appeler l'IPC Quickshell exposé ci-dessous (target "lock",
    fonction "lock") depuis hypridle.conf, par exemple :

        general {
            lock_cmd = quickshell ipc call lock lock
        }

    Adapter `quickshell` si le shell principal est lancé via une autre
    invocation (ex: `quickshell -p /chemin/vers/shell.qml ipc call lock lock`
    si plusieurs instances peuvent tourner en parallèle). Vérifier la
    syntaxe exacte avec `quickshell ipc --help` sur votre version installée.

    Sécurité : l'IPC n'expose volontairement qu'un verrou "lock" et une
    lecture d'état "isLocked" — pas de fonction "unlock". Le seul chemin
    de déverrouillage est LockContext (PAM). Exposer un déverrouillage par
    IPC permettrait à n'importe quel processus local tournant sous le même
    utilisateur de contourner l'authentification (`quickshell ipc call`
    n'a pas de contrôle d'accès dédié au-delà des permissions Unix du
    socket) ; ce n'est pas un compromis acceptable pour un lockscreen.

    WlSessionLock instancie automatiquement un WlSessionLockSurface par
    écran connecté dès que `locked` passe à true — voir LockSurface.qml
    pour le rendu par écran. Aucune boucle manuelle sur Quickshell.screens
    n'est nécessaire ni souhaitable ici (Quickshell gère déjà le cycle de
    vie par sortie ; le refaire à la main est une source classique de
    surfaces dupliquées / non nettoyées).
*/
Scope {
    id: root

    readonly property alias locked: lock.locked

    signal lockRequested
    signal unlockRequested

    // -----------------------------------------------------------------
    // Verrouillage différé : on ne pose lock.locked = true qu'une fois
    // le wallpaper et l'avatar réellement décodés (readyForLock), pas
    // immédiatement. Le vrai lock Wayland (surface opaque, saisie
    // capturée) intervient donc seulement quand il n'y a plus rien à
    // faire apparaître après coup — pas d'écran vide/pop visible, sans
    // recourir à une animation qui masquerait artificiellement l'attente.
    //
    // Sécurité : le bureau reste visible pendant ce court délai de
    // préparation (quelques dizaines à centaines de ms typiquement).
    // C'est un compromis assumé — lockTimeoutTimer borne ce délai à 1.5s
    // maximum pour ne jamais laisser le bureau exposé indéfiniment si un
    // fichier est corrompu/introuvable ou si le décodage traîne pour une
    // raison quelconque ; passé ce délai, on verrouille quand même avec
    // ce qui est prêt.
    // -----------------------------------------------------------------
    property bool lockPending: false

    // Horodatage du dernier appel à lock(), pour mesurer dans les traces
    // combien de temps s'est réellement écoulé jusqu'au commitLock().
    property real lockRequestedAt: 0

    function dbg(msg) {
        console.log("[LockScreen]", (Date.now() - root.lockRequestedAt) + "ms:", msg)
    }

    // "Prêt" signifie explicitement Ready ou Error (échec définitif, le
    // repli visuel prendra le relais) — jamais se fier à "différent de
    // Loading" seul : au tout premier appel après démarrage du shell,
    // le décodage peut ne pas avoir encore démarré du tout, auquel cas
    // status vaut Null (pas Loading), ce qui aurait fait passer
    // readyForLock à true à tort avant même que le travail commence.
    // C'était le bug réel expliquant pourquoi le timeout de secours
    // était systématiquement atteint plutôt que le mécanisme normal.
    function imageIsSettled(img) {
        return img.status === Image.Ready || img.status === Image.Error
    }

    readonly property bool wallpaperPreloadReady: root.imageIsSettled(wallpaperPreloader) && lockContext.wallpaperCacheAttempted
    readonly property bool avatarPreloadReady: lockContext.avatarDetectionDone
        && (lockContext.avatarUrl.toString().length === 0 || root.imageIsSettled(avatarPreloader))
    readonly property bool readyForLock: wallpaperPreloadReady && avatarPreloadReady

    onWallpaperPreloadReadyChanged: root.dbg("wallpaperPreloadReady -> " + root.wallpaperPreloadReady
        + " (status=" + wallpaperPreloader.status + ")")
    onAvatarPreloadReadyChanged: root.dbg("avatarPreloadReady -> " + root.avatarPreloadReady
        + " (detectionDone=" + lockContext.avatarDetectionDone
        + ", url=" + lockContext.avatarUrl
        + ", status=" + avatarPreloader.status + ")")
    onReadyForLockChanged: {
        root.dbg("readyForLock -> " + root.readyForLock)
        if (root.lockPending && root.readyForLock) {
            root.dbg("readyForLock reached while pending -> commitLock() via normal path")
            root.commitLock()
        }
    }

    function lock() {
        root.lockRequestedAt = Date.now()
        root.dbg("lock() called. locked=" + lock.locked + " lockPending=" + root.lockPending
            + " readyForLock=" + root.readyForLock
            + " wallpaperStatus=" + wallpaperPreloader.status
            + " avatarStatus=" + avatarPreloader.status
            + " avatarUrl=" + lockContext.avatarUrl
            + " avatarDetectionDone=" + lockContext.avatarDetectionDone)

        if (lock.locked || root.lockPending) {
            root.dbg("lock() ignored: already locked or already pending")
            return
        }
        lockContext.checkFprintAvailable()

        if (root.readyForLock) {
            root.dbg("already ready -> commitLock() immediately")
            root.commitLock()
        } else {
            root.dbg("not ready yet -> waiting (lockPending=true), timeout in " + lockTimeoutTimer.interval + "ms")
            root.lockPending = true
            lockTimeoutTimer.restart()
        }
    }

    function commitLock() {
        root.dbg("commitLock() -> lock.locked = true"
            + " (wallpaperReady=" + root.wallpaperPreloadReady
            + " avatarReady=" + root.avatarPreloadReady + ")")
        root.lockPending = false
        lockTimeoutTimer.stop()
        lock.locked = true
    }

    Timer {
        id: lockTimeoutTimer
        // Augmenté de 800ms à 1500ms : la correction ci-dessus
        // (imageIsSettled distinguant Null de Ready/Error) était le vrai
        // fix pour la majorité des cas, mais un wallpaper volumineux ou
        // un disque lent peut légitimement dépasser 800ms de décodage.
        // Pas plus haut que ça : un lockscreen doit rester perçu comme
        // "instantané", et au-delà d'~1.5s le délai devient lui-même le
        // problème plutôt que la solution.
        interval: 1500
        onTriggered: {
            if (root.lockPending) {
                root.dbg("TIMEOUT reached (" + lockTimeoutTimer.interval + "ms) -> commitLock() via timeout path"
                    + " (wallpaperReady=" + root.wallpaperPreloadReady
                    + " avatarReady=" + root.avatarPreloadReady + ")")
                root.commitLock()
            }
        }
    }

    LockContext {
        id: lockContext

        onUnlocking: unlockCloseTimer.restart()
        onUnlocked: {
            lock.locked = false
        }
    }

    // -----------------------------------------------------------------
    // Préchargement réel (pas juste un complément cosmétique) : lock()
    // attend que ces deux Image terminent leur décodage (readyForLock
    // ci-dessus) avant de poser lock.locked = true. C'est ce qui élimine
    // le "pop" à l'écran — le contenu est déjà prêt au moment où l'écran
    // apparaît verrouillé, plutôt que de verrouiller immédiatement et de
    // masquer l'attente par une animation.
    // -----------------------------------------------------------------
    readonly property var primaryScreen: Quickshell.screens[0] ?? null

    // Déclenche la génération du cache disque (voir LockContext) dès que
    // la taille de l'écran principal est connue, sans attendre la
    // création de LockSurface — sinon le tout premier lock après
    // démarrage du shell ne pourrait jamais bénéficier du cache déjà
    // prêt, exactement le problème qu'on cherche à éliminer.
    onPrimaryScreenChanged: {
        if (root.primaryScreen) {
            lockContext.setWallpaperTargetSize(root.primaryScreen.width, root.primaryScreen.height)
        }
    }
    Component.onCompleted: {
        if (root.primaryScreen) {
            lockContext.setWallpaperTargetSize(root.primaryScreen.width, root.primaryScreen.height)
        }
    }

    Image {
        id: wallpaperPreloader
        visible: false
        asynchronous: true
        cache: true
        source: lockContext.wallpaperSource
        sourceSize: root.primaryScreen
            ? Qt.size(root.primaryScreen.width * (root.primaryScreen.devicePixelRatio ?? 1),
                       root.primaryScreen.height * (root.primaryScreen.devicePixelRatio ?? 1))
            : undefined
        onStatusChanged: root.dbg("wallpaperPreloader.status -> " + status + " (source=" + source + ")")
        onSourceChanged: root.dbg("wallpaperPreloader.source changed -> " + source)
    }

    // Même principe que le wallpaper ci-dessus, pour l'avatar : la
    // détection (Process sur ~/.face etc., voir LockContext) tourne déjà
    // dès le démarrage, mais le décodage de l'image elle-même ne démarre
    // que lorsqu'une Image la référence — ce préchargeur s'en charge en
    // amont. sourceSize fixé à 56px (taille d'affichage réelle dans
    // LockSurface), même raisonnement que ci-dessus pour la cohérence du
    // cache. source est vide tant que la détection n'a rien trouvé ; une
    // Image avec une source vide reste directement dans un état "not
    // Loading" (Null), donc n'empêche jamais readyForLock de passer à
    // true.
    Image {
        id: avatarPreloader
        visible: false
        asynchronous: true
        cache: true
        source: lockContext.avatarUrl
        sourceSize: root.primaryScreen
            ? Qt.size(56 * (root.primaryScreen.devicePixelRatio ?? 1), 56 * (root.primaryScreen.devicePixelRatio ?? 1))
            : undefined
    }

    // Laisse les LockSurface (une par écran) jouer leur animation de
    // sortie en parallèle, puis ferme réellement le verrou une fois
    // qu'elle est terminée partout. Centralisé ici plutôt que dans
    // chaque LockSurface pour n'émettre "unlocked" qu'une seule fois,
    // peu importe le nombre d'écrans connectés.
    Timer {
        id: unlockCloseTimer
        interval: lockContext.unlockAnimDuration
        onTriggered: lockContext.unlocked()
    }

    WlSessionLock {
        id: lock

        onLockedChanged: {
            if (locked) {
                root.lockRequested()
            } else {
                lockContext.reset()
                root.unlockRequested()
            }
        }

        LockSurface {
            lock: lock
            context: lockContext
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock()
        }

        function isLocked(): bool {
            return lock.locked
        }
    }

    // Raccourci clavier natif Hyprland (GlobalShortcut, module
    // Quickshell.Hyprland). Optionnel — le lock reste accessible sans
    // ça via l'AppleMenu (déjà câblé dans shell.qml) et via l'IPC
    // ci-dessus. Nécessite d'assigner un bind côté Hyprland pointant
    // vers ce raccourci nommé, par ex. dans hyprland.conf :
    //
    //   bind = SUPER, L, global, lickintosh:lock
    //
    // (le nom après ":" est "appid:name", donc ici "lickintosh:lock" —
    // doit correspondre exactement aux valeurs appid/name ci-dessous).
    // Si ce bind n'est pas déclaré, ce bloc ne fait simplement rien —
    // pas besoin de le retirer si vous ne l'utilisez pas.
    GlobalShortcut {
        appid: "lickintosh"
        name: "lock"
        description: "Verrouille la session"
        onPressed: root.lock()
    }
}
