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
        wallpaperCacheCheckProc.running = true
    }

    function dbg(msg) {
        console.log("[LockContext]", Date.now() + "ms:", msg)
    }

    // 1) Vérifie si le fichier cache existe déjà (évite de relancer une
    //    conversion coûteuse à chaque changement mineur, ex: reload du
    //    shell) ; 2) si absent, lance la conversion.
    Process {
        id: wallpaperCacheCheckProc
        command: ["sh", "-c",
            "mkdir -p '" + root.wallpaperCacheDir.replace(/'/g, "'\\''") + "'; " +
            "[ -f '" + root.wallpaperCachePath.replace(/'/g, "'\\''") + "' ] && echo exists || echo missing"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.dbg("wallpaperCacheCheckProc result: " + text.trim())
                if (text.trim() === "exists") {
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
            "TMP=\"$DST.tmp.$$\"; " +
            "if command -v magick >/dev/null 2>&1; then " +
            "  magick \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "elif command -v convert >/dev/null 2>&1; then " +
            "  convert \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "else " +
            "  echo 'NO_IMAGEMAGICK' >&2; exit 42; " +
            "fi"]
        onExited: code => {
            root.dbg("wallpaperConvertProc exited with code " + code)
            // code 42 = ImageMagick absent : on ne considère pas le
            // cache "prêt", wallpaperSource retombera sur l'original.
            // Tout autre échec (fichier source invalide, etc.) a le
            // même effet, ce qui est le comportement de repli voulu.
            root.wallpaperCacheReady = (code === 0)
            root.wallpaperCacheAttempted = true
        }
    }

    // Source finale effectivement affichée : le fichier caché
    // pré-redimensionné une fois qu'il est prêt, sinon l'original tel
    // quel (comportement de repli, jamais d'écran vide en attendant).
    readonly property url wallpaperSource: root.wallpaperCacheReady && root.wallpaperCachePath.length > 0
        ? root.toFileUrl(root.wallpaperCachePath)
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
