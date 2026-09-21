pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services

/*
    LockContext — état d'authentification du lockscreen.

    Deux PamContext natifs Quickshell en parallèle (async, non-bloquant :
    aucun ne tient le thread principal, donc pas de risque de déclencher
    le dialogue "ANR" de Hyprland) :
      - pam        mot de passe, déclenché par tryUnlock()
      - fprint     empreinte digitale (fprintd), tentée automatiquement
                   dès que la surface est prête, en fond, tant que
                   l'utilisateur n'a pas commencé à taper.

    Les deux partagent la même instance de LockContext, donc le
    succès de l'un ou l'autre déverrouille de la même façon.

    Séquence mot de passe :
      1. L'utilisateur tape -> LockSurface appelle updateText() -> currentText
         change et showFailure repasse à false
      2. Entrée / bouton -> tryUnlock() démarre pam.start()
      3. PamContext demande une réponse -> on renvoie currentText
      4. Succès -> signal unlocking() (l'anim de sortie peut démarrer côté
         LockSurface), puis unlocked() une fois l'anim terminée (voir
         LockScreen, qui centralise ce timing)
      5. Échec -> showFailure=true puis currentText vidé (dans cet ordre,
         via un appel interne qui ne repasse pas par updateText) ->
         déclenche le wiggle côté LockSurface.

    Séquence empreinte :
      1. checkFprintAvailable() lance `fprintd-list $USER` ; si un doigt
         est enregistré (code de sortie 0), fprintAvailable devient true.
      2. startFprint() est appelé automatiquement (voir LockSurface) tant
         qu'aucune saisie mot de passe n'est en cours ; en cas d'échec on
         relance jusqu'à fprintMaxTries tentatives, avec un léger délai.
      3. Succès -> même chemin de sortie que le mot de passe (unlocking).
      4. Toute frappe côté mot de passe annule une tentative fprint en
         cours (abortFprint()), pour éviter les deux prompts PAM
         concurrents sur le même terminal virtuel.
*/
Scope {
    id: root

    signal unlocked
    signal unlocking
    signal failed

    // Durée de l'animation de sortie jouée par chaque LockSurface au
    // succès de l'auth. Centralisée ici (plutôt que dupliquée en dur
    // dans LockSurface et dans le timer de fermeture de LockScreen) pour
    // qu'un seul endroit contrôle le timing du unlock.
    readonly property int unlockAnimDuration: 320

    // Construction d'un objet url Qt à partir d'un chemin de fichier
    // local, avec encodage correct des espaces/caractères spéciaux
    // (Qt.resolvedUrl() n'encode rien ; une simple concaténation
    // "file://" + chemin assignée à une property string est sujette à
    // une double conversion imprévisible au moment de l'assignation à
    // Image.source). Centralisé ici (plutôt que dupliqué dans chaque
    // LockSurface et dans LockScreen) puisque LockContext est déjà le
    // singleton partagé entre tous ces composants.
    function toFileUrl(path) {
        return Qt.url("file://" + encodeURI(path))
    }

    // -----------------------------------------------------------------
    // Wallpaper de lockscreen : chemin source brut + cache disque
    // pré-redimensionné (via ImageMagick), pour contourner une limite
    // structurelle de WlSessionLockSurface confirmée par des logs de
    // debug réels (voir historique) : le cache mémoire Qt (cache: true
    // sur Image) ne survit PAS à la destruction de la surface — chaque
    // nouveau lock recrée un tout nouvel arbre QML, dont la nouvelle
    // Image démarre à status = Loading, pas Ready, et redécode le
    // fichier depuis zéro (mesuré à ~800ms pour ce projet). C'est le
    // protocole Wayland ext-session-lock-v1 lui-même qui impose cette
    // destruction (doc Quickshell : "SessionLock Surfaces will never
    // become invisible, they will only be destroyed"), donc aucune
    // astuce de cache mémoire seule ne peut le contourner.
    //
    // Le cache est régénéré uniquement quand le fichier source ou la
    // taille cible change (nom de fichier cache dérivé des deux), donc
    // le coût de conversion n'est payé qu'une fois par wallpaper/taille
    // d'écran, pas à chaque lock.
    //
    // Dépendance externe : ImageMagick (`convert` ou `magick`). Si
    // absent, la conversion échoue proprement (voir onExited) et le
    // fichier original est utilisé tel quel — dégradation propre, pas
    // de blocage du lockscreen (juste retour au pop mesuré).
    // -----------------------------------------------------------------
    readonly property string wallpaperRawPath: {
        const configured = ShellConfig.options.wallpaper.lockscreenPath
        if (configured.length > 0) return configured
        return Quickshell.shellDir + "/assets/wallpapers/macOS Tahoe 26 Dark Wallpaper.png"
    }

    readonly property string wallpaperCacheDir: (Quickshell.env("HOME") || "") + "/.cache/quickshell/lockscreen-wallpaper"

    // Taille cible de conversion : mise à jour par LockScreen dès qu'un
    // écran est connu (voir setWallpaperTargetSize()). Tant qu'elle est
    // nulle, on affiche l'original sans attendre une conversion inutile.
    property int wallpaperTargetWidth: 0
    property int wallpaperTargetHeight: 0

    function setWallpaperTargetSize(w, h) {
        const iw = Math.round(w)
        const ih = Math.round(h)
        if (iw === root.wallpaperTargetWidth && ih === root.wallpaperTargetHeight) return
        root.wallpaperTargetWidth = iw
        root.wallpaperTargetHeight = ih
    }

    // Nom de fichier cache dérivé du chemin source + de la taille cible
    // (hash simple, suffisant ici : pas besoin de cryptographique, juste
    // d'éviter les collisions entre wallpapers différents).
    function simpleHash(str) {
        let h = 0
        for (let i = 0; i < str.length; i++) {
            h = ((h << 5) - h + str.charCodeAt(i)) | 0
        }
        return (h >>> 0).toString(16)
    }

    readonly property string wallpaperCacheFileName: root.wallpaperTargetWidth > 0
        ? root.simpleHash(root.wallpaperRawPath + "|" + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight) + ".png"
        : ""
    readonly property string wallpaperCachePath: root.wallpaperCacheFileName.length > 0
        ? root.wallpaperCacheDir + "/" + root.wallpaperCacheFileName
        : ""

    property bool wallpaperCacheReady: false

    // true dès que la vérification/conversion s'est terminée au moins
    // une fois (peu importe le résultat) : distinct de
    // wallpaperCacheReady, qui ne veut dire que "le fichier caché est
    // disponible". LockScreen.readyForLock a besoin de savoir que la
    // tentative a eu lieu, pas seulement qu'elle a réussi — sinon on
    // pourrait considérer "prêt" avant même d'avoir essayé.
    property bool wallpaperCacheAttempted: false

    // mtime (epoch, secondes) du fichier de cache au moment ou on l'a
    // constate pret, utilise pour casser le cache Image de Qt (voir
    // wallpaperSource plus bas). Necessaire car Qt garde l'etat Error
    // associe a une URL de facon permanente pour la duree de vie du
    // processus, meme apres qu'un fichier devenu valide a ete ecrit au
    // meme chemin (confirme par la doc Qt — "Images are cached and
    // shared internally... if several Image items have the same
    // source, only one copy... will be loaded" — et par les forums Qt :
    // reassigner la meme URL ne redeclenche jamais de rechargement).
    // Scenario reproduit et confirme par logs reels : le tout premier
    // essai d'un wallpaper dont la conversion n'a pas encore fini
    // d'ecrire son fichier au moment ou wallpaperPreloader tente de le
    // charger termine en Image.Error ; toute reutilisation ulterieure
    // de cette meme URL (meme apres regeneration reussie du fichier)
    // reste bloquee sur Error jusqu'au redemarrage du shell.
    property string wallpaperCacheMtime: ""

    // Resultats des Process wallpaper : chaque run porte son propre chemin.
    // Bug reproduit et confirme par logs reels : wallpaperCacheCheckProc et
    // wallpaperConvertProc sont des instances uniques. Reaffecter
    // running = true pendant qu'elles tournent met un redemarrage en file
    // (le binding command est reevalue au redemarrage), mais le resultat
    // du run EN COURS arrive d'abord et etait applique au chemin courant,
    // meme quand celui-ci avait change entre-temps. Deux symptomes :
    //  - un "exists" + mtime de l'ancien chemin colle sur le nouveau
    //    chemin (fichier absent) -> URL en Error, ensuite bloquee par le
    //    cache Image de Qt ;
    //  - une conversion terminee pour l'ancien chemin declaree "prete"
    //    pour le nouveau (wallpaperConvertTargetPath, variable partagee,
    //    etait ecrasee par une verification plus recente).
    //  - onWallpaperCachePathChanged s'execute avant la reevaluation du
    //    binding command : un run demarre tout de suite partait avec
    //    l'ancien chemin (d'ou le demarrage differe par Qt.callLater).
    // Correctif : chaque run imprime lui-meme le chemin qu'il a traite en
    // premiere ligne de stdout ; le resultat n'est applique que s'il
    // correspond encore a wallpaperCachePath, sinon il est ignore et le
    // run mis en file pour le chemin courant prend le relais.

    // Noms de propriétés sans underscore de tête : la syntaxe du handler
    // généré on<Property>Changed pour un nom commençant par un
    // underscore n'est pas documentée comme fiable, donc toute propriété
    // qui a besoin d'un handler nommé a un nom qui commence par une
    // lettre (leçon du premier essai de ce système, plus tôt).
    onWallpaperCachePathChanged: {
        root.wallpaperCacheReady = false
        root.wallpaperCacheAttempted = false
        root.triggerWallpaperCache()
    }

    function triggerWallpaperCache() {
        if (root.wallpaperCachePath.length === 0) return
        root.dbg("triggerWallpaperCache: checking " + root.wallpaperCachePath)
        // Differe au tour de boucle suivant : onWallpaperCachePathChanged
        // s'execute AVANT que le binding Process.command soit reevalue
        // (constate en logs reels : le run partait avec l'ANCIEN chemin).
        // Qt.callLater regroupe aussi plusieurs declenchements rapproches.
        Qt.callLater(root.startWallpaperCheck)
    }

    function startWallpaperCheck() {
        if (root.wallpaperCachePath.length === 0) return
        wallpaperCacheCheckProc.running = true
    }

    function dbg(msg) {
        console.log("[LockContext]", Date.now() + "ms:", msg)
    }

    // 1) Vérifie si le fichier cache existe déjà (évite de relancer une
    //    conversion coûteuse à chaque changement mineur, ex: reload du
    //    shell) ; 2) si absent, lance la conversion. Recupere aussi le
    //    mtime du fichier dans le meme appel (voir wallpaperCacheMtime
    //    plus bas — necessaire pour casser le cache Image de Qt).
    Process {
        id: wallpaperCacheCheckProc
        command: ["sh", "-c",
            "mkdir -p '" + root.wallpaperCacheDir.replace(/'/g, "'\\''") + "'; " +
            "F='" + root.wallpaperCachePath.replace(/'/g, "'\\''") + "'; " +
            "echo \"$F\"; if [ -f \"$F\" ]; then echo exists; stat -c %Y \"$F\"; else echo missing; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                // lines[0] = chemin verifie par CE run, lines[1] = exists|missing,
                // lines[2] = mtime (si exists).
                const lines = text.trim().split("\n")
                const checkedPath = lines[0]
                const state = lines.length > 1 ? lines[1] : ""
                root.dbg("wallpaperCacheCheckProc result: " + state +
                    " (path=" + checkedPath + ", current=" + root.wallpaperCachePath + ")")
                if (checkedPath !== root.wallpaperCachePath) {
                    // Ignore, mais rien d'autre ne relancera forcement une
                    // verification pour le chemin actuel : on la relance.
                    root.dbg("wallpaperCacheCheckProc: resultat perime, ignore (relance)")
                    Qt.callLater(root.startWallpaperCheck)
                    return
                }
                if (state === "exists") {
                    root.wallpaperCacheMtime = lines.length > 2 ? lines[2] : ""
                    root.wallpaperCacheReady = true
                    root.wallpaperCacheAttempted = true
                } else {
                    wallpaperConvertProc.running = true
                }
            }
        }
    }

    Process {
        id: wallpaperConvertProc
        command: ["sh", "-c",
            "SRC=" + JSON.stringify(root.wallpaperRawPath) + "; " +
            "DST=" + JSON.stringify(root.wallpaperCachePath) + "; " +
            "echo \"$DST\"; " +
            "TMP=\"$DST.tmp.$$\"; " +
            "if command -v magick >/dev/null 2>&1; then " +
            "  magick \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "elif command -v convert >/dev/null 2>&1; then " +
            "  convert \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "else " +
            "  echo 'NO_IMAGEMAGICK' >&2; exit 42; " +
            "fi; " +
            "[ -f \"$DST\" ] && stat -c %Y \"$DST\""]
        stdout: StdioCollector { id: wallpaperConvertOut }
        onExited: code => {
            // stdout : ligne 1 = chemin cible traite par CE run,
            // ligne 2 = son mtime (seulement si le fichier existe).
            const out = wallpaperConvertOut.text.trim().split("\n")
            const convertedPath = out[0]
            root.dbg("wallpaperConvertProc exited with code " + code +
                " (target=" + convertedPath + ", current=" + root.wallpaperCachePath + ")")

            // Le chemin a change pendant cette conversion : le resultat
            // concerne un autre fichier. On ne touche a rien :
            // onWallpaperCachePathChanged a deja remis ready a false et
            // mis en file une nouvelle verification pour le chemin actuel.
            if (convertedPath !== root.wallpaperCachePath) {
                root.dbg("wallpaperConvertProc: resultat perime, ignore")
                return
            }

            // code 42 = ImageMagick absent : le cache n'est pas "pret",
            // wallpaperSource retombe sur l'original (repli voulu). Tout
            // autre echec a le meme effet. Le mtime n'est lu qu'en cas de
            // succes reel.
            if (code === 0) {
                root.wallpaperCacheMtime = out.length > 1 ? out[1] : ""
            }
            root.wallpaperCacheReady = (code === 0)
            root.wallpaperCacheAttempted = true
        }
    }

    // Source finale effectivement affichée : le fichier caché
    // pré-redimensionné une fois qu'il est prêt, sinon l'original tel
    // quel (comportement de repli, jamais d'écran vide en attendant).
    // Le fragment #mtime rend chaque nouvelle version du fichier
    // visible comme une URL differente pour le cache Qt (le fragment
    // n'affecte jamais la resolution du chemin de fichier reel).
    readonly property url wallpaperSource: root.wallpaperCacheReady && root.wallpaperCachePath.length > 0
        ? Qt.url(root.toFileUrl(root.wallpaperCachePath) + (root.wallpaperCacheMtime.length > 0 ? "#" + root.wallpaperCacheMtime : ""))
        : root.toFileUrl(root.wallpaperRawPath)

    // -----------------------------------------------------------------
    // Avatar : détecté une seule fois ici, dès le démarrage du shell
    // (pas au moment du lock), pour la même raison que le wallpaper
    // ci-dessus — éviter un délai visible d'apparition à l'écran de
    // verrouillage. Premier chemin existant parmi les emplacements
    // standards, dans l'ordre de priorité usuel. ~/.face seul ne suffit
    // pas : c'est un standard ancien (LightDM historique), la plupart
    // des DE/distros récents (dont NixOS via accountsservice) stockent
    // plutôt l'avatar dans /var/lib/AccountsService/icons/<user>.
    // `test -r` vérifie aussi la lisibilité, pas juste l'existence.
    //
    // HOME/USER sont interpolés depuis Quickshell.env() directement dans
    // la commande (pas laissés en $HOME/$USER shell) : Process n'hérite
    // pas forcément d'un environnement utilisateur complet selon comment
    // le compositeur lance Quickshell (ex: exec-once avec un
    // environnement minimal).
    // -----------------------------------------------------------------
    property string avatarSource: ""
    readonly property url avatarUrl: root.avatarSource.length > 0 ? root.toFileUrl(root.avatarSource) : ""

    // true une fois la détection terminée, peu importe le résultat
    // (avatar trouvé ou non) : sert à LockScreen pour savoir s'il faut
    // encore attendre avant de considérer le lockscreen "prêt" à
    // apparaître verrouillé, plutôt que de se fier uniquement au statut
    // de l'Image (qui resterait "Null", pas "Loading", tant qu'aucune
    // source n'est encore connue — cas ambigu à éviter).
    property bool avatarDetectionDone: false

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _user: Quickshell.env("USER") || ""

    // Si HOME est indisponible (cas extrême), la détection ne peut pas
    // tourner du tout : on la considère "terminée" immédiatement plutôt
    // que de dépendre uniquement du timeout de sécurité de LockScreen.
    Component.onCompleted: {
        if (root._home.length === 0) root.avatarDetectionDone = true
    }

    Process {
        id: avatarDetectProc
        running: root._home.length > 0
        command: ["sh", "-c",
            "for f in " +
            "\"" + root._home + "/.face\" " +
            "\"" + root._home + "/.face.icon\" " +
            "\"/var/lib/AccountsService/icons/" + root._user + "\"" +
            "; do [ -r \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length > 0) root.avatarSource = path
                root.avatarDetectionDone = true
            }
        }
    }

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Dernier message informatif renvoyé par PAM (ex: "compte verrouillé
    // pendant N minutes" via pam_faillock). Vide sinon, et remis à zéro
    // au succès (voir onCompleted) et via reset(). Copié depuis
    // pam.message plutôt qu'aliasé directement pour garder le contrôle
    // du cycle de vie (PAM ne garantit pas de remettre message à "" tout
    // seul entre deux tentatives).
    property string lockMessage: ""

    // Nombre d'échecs consécutifs (remis à zéro dès qu'une tentative
    // réussit). Purement informatif pour l'UI (ex: ralentir les
    // nouvelles tentatives visuellement) ; pam_faillock gère le vrai
    // verrouillage côté système si configuré.
    property int failCount: 0

    // --- Empreinte digitale (fprintd) ---------------------------------
    // Désactivable si vous n'avez pas de lecteur d'empreintes ou ne
    // voulez pas de ce chemin d'auth.
    property bool fprintEnabled: true
    readonly property int fprintMaxTries: 3

    // true une fois qu'on a confirmé qu'un doigt est enregistré pour cet
    // utilisateur (fprintd-list). Tant que c'est indéterminé/false, on
    // ne tente rien : lancer pam_fprintd sans doigt enregistré produirait
    // juste une erreur PAM à chaque fois, inutilement.
    property bool fprintAvailable: false
    readonly property bool fprintActive: fprint.active
    property int fprintTries: 0
    readonly property bool fprintCanAttempt: root.fprintEnabled
        && root.fprintAvailable
        && root.fprintTries < root.fprintMaxTries
        && !root.unlockInProgress

    // Appelé par LockSurface à chaque frappe utilisateur (pas par le
    // code interne qui vide currentText après une tentative) : c'est
    // volontairement une fonction dédiée plutôt qu'un simple binding sur
    // onCurrentTextChanged, pour ne pas effacer showFailure au moment
    // même où onCompleted le positionne à true en vidant currentText.
    function updateText(text) {
        root.currentText = text
        root.showFailure = false
        if (text.length > 0) root.abortFprint()
    }

    function tryUnlock() {
        if (root.unlockInProgress) return
        if (root.currentText.length === 0) return

        root.abortFprint()
        root.unlockInProgress = true
        pam.start()
    }

    function checkFprintAvailable() {
        if (!root.fprintEnabled) return
        fprintAvailProc.running = true
    }

    function startFprint() {
        if (!root.fprintCanAttempt) return
        if (fprint.active) return
        fprint.start()
    }

    function abortFprint() {
        if (fprint.active) fprint.abort()
    }

    function reset() {
        pam.abort()
        root.abortFprint()
        root.currentText = ""
        root.showFailure = false
        root.unlockInProgress = false
        root.lockMessage = ""
        root.fprintTries = 0
    }

    PamContext {
        id: pam

        // Livré à côté de ce composant (ui/lockscreen/pam.d/), pas dans
        // /etc/pam.d : Quickshell charge directement ce fichier comme
        // stack PAM, donc la config reste versionnée avec le lockscreen
        // lui-même, aucune install système requise pour ce fichier.
        configDirectory: Quickshell.shellDir + "/ui/lockscreen/pam.d"
        config: "lickintosh-lock"

        onMessageChanged: {
            if (message.length > 0) root.lockMessage = message
        }

        onResponseRequiredChanged: {
            if (!responseRequired) return
            respond(root.currentText)
        }

        onCompleted: result => {
            root.unlockInProgress = false

            if (result === PamResult.Success) {
                root.failCount = 0
                root.currentText = ""
                root.lockMessage = ""
                root.unlocking()
                return
            }

            root.failCount += 1
            root.showFailure = true
            root.currentText = ""
            root.failed()
        }
    }

    // Vérifie une fois au démarrage si fprintd connaît un doigt pour cet
    // utilisateur. Ne bloque jamais le thread QML (Process est async).
    // Le résultat est capturé depuis le paramètre `code` du signal
    // onExited plutôt que via une éventuelle propriété exitCode
    // persistante, pour ne pas dépendre d'une API Process non confirmée.
    Process {
        id: fprintAvailProc
        command: ["sh", "-c", "fprintd-list \"$USER\""]
        onExited: code => {
            root.fprintAvailable = (code === 0)
            if (root.fprintAvailable) root.startFprint()
        }
    }

    PamContext {
        id: fprint

        configDirectory: Quickshell.shellDir + "/ui/lockscreen/pam.d"
        config: "lickintosh-lock-fprint"

        onResponseRequiredChanged: {
            // pam_fprintd ne demande normalement pas de texte de
            // réponse (le scan se fait hors bande), mais on répond vide
            // par sécurité si jamais le module le demandait quand même —
            // éviter de rester bloqué en attente indéfiniment.
            if (responseRequired) respond("")
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.fprintTries = 0
                root.unlocking()
                return
            }

            root.fprintTries += 1
            if (root.fprintCanAttempt) {
                fprintRetryTimer.restart()
            }
        }
    }

    Timer {
        id: fprintRetryTimer
        interval: 600
        onTriggered: root.startFprint()
    }
}
