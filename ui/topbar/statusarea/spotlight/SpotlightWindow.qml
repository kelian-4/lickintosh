import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components.glass
import qs.services
import "SpotlightEmojiData.js" as EmojiData
import "SpotlightCalc.js" as Calc

Scope {
    id: root

    property bool opened: false
    signal closeRequested()
    signal openRequested()

    GlobalShortcut {
        name: "spotlight"
        description: "Basculer Spotlight"
        onPressed: {
            if (root.opened) {
                if (spotlightLoader.item) spotlightLoader.item.closeGracefully()
            } else {
                root.openRequested()
            }
        }
    }

    readonly property color glassColor: "#c01e1e1e"
    readonly property color textColor:  "#dfdfdf"

    FontLoader { id: sfRounded;       source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf") }
    FontLoader { id: sfRoundedMedium; source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Medium.otf") }

    property var fileIndex:  []
    property bool indexReady: false

    // Le quoting simple protege des espaces et de l'injection, mais empeche
    // aussi l'expansion du ~ par le shell ('~/Pictures' est un chemin
    // litteral). On resout donc le ~ initial cote QML avant de quoter,
    // via Quickshell.env("HOME") (meme pattern que LockContext.qml).
    function _safeShellPath(p) {
        var s = String(p)
        var home = Quickshell.env("HOME") || ""
        if (home !== "") {
            if (s === "~") s = home
            else if (s.indexOf("~/") === 0) s = home + s.slice(1)
        }
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    readonly property string findExcludes: {
        var parts = ["-not -path '*/.*'"]
        var excludes = ShellConfig.options.spotlight.indexing.excludePaths
        for (var i = 0; i < excludes.length; i++) {
            var safe = String(excludes[i]).replace(/'/g, "")
            if (safe.length === 0) continue
            parts.push("-not -path '*/" + safe + "/*'")
        }
        return parts.join(" ")
    }
    readonly property string fileIndexCache: "~/.cache/quickshell/spotlight_file_index.txt"

    function applyIndexOutput(text) {
        var lines = text.trim().split("\n")
        var out = []
        for (var i = 0; i < lines.length; i++) { if (lines[i]) out.push(lines[i]) }
        root.fileIndex  = out
        root.indexReady = true
    }

    Process {
        id: indexLoadProc
        running: true
        command: ["bash", "-c", "idx=" + root.fileIndexCache + "; [ -s \"$idx\" ] && cat \"$idx\" || echo __EMPTY__"]
        stdout: StdioCollector { id: indexLoadOut }
        onExited: {
            var text = indexLoadOut.text.trim()
            if (text === "" || text === "__EMPTY__") {
                indexProc.running = true
            } else {
                root.applyIndexOutput(text)
            }
        }
    }

    Process {
        id: indexProc
        command: ["bash", "-c",
            "idx=" + root.fileIndexCache + "; mkdir -p ~/.cache/quickshell; " +
            "find ~ " + root.findExcludes + " -type f -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | tee \"$idx\""
        ]
        stdout: StdioCollector { id: indexOut }
        onExited: root.applyIndexOutput(indexOut.text)
    }

    Process {
        id: incrementalIndexProc
        command: ["bash", "-c",
            "idx=" + root.fileIndexCache + "; mkdir -p ~/.cache/quickshell; touch \"$idx\"; " +
            "new=$(find ~ " + root.findExcludes + " -type f -mmin -6 -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2-); " +
            "if [ -n \"$new\" ]; then " +
            "tmp=$(mktemp); printf '%s\\n' \"$new\" > \"$tmp\"; " +
            "grep -vFxf <(printf '%s\\n' \"$new\") \"$idx\" >> \"$tmp\"; " +
            "mv \"$tmp\" \"$idx\"; " +
            "fi; " +
            "cat \"$idx\""
        ]
        stdout: StdioCollector { id: incrementalIndexOut }
        onExited: root.applyIndexOutput(incrementalIndexOut.text)
    }

    function startReindex() { indexProc.running = true }

    property var wallpaperList: []

    Process {
        id: wallProc
        running: false
        command: ["sh", "-c", "find " + root._safeShellPath(ShellConfig.options.spotlight.indexing.wallpaperDir) + " -maxdepth 2 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null | head -40"]
        stdout: StdioCollector { id: wallOut }
        onExited: {
            var lines = wallOut.text.trim().split("\n")
            var out = []
            for (var i = 0; i < lines.length; i++) {
                var p = lines[i]
                if (!p || p === "") continue
                out.push({ title: p.split("/").pop(), description: "Prefix: >~ ou >wall | Fond d'écran", path: p, isWallpaper: true })
            }
            root.wallpaperList = out

            // Aucun wallpaper n'a jamais ete applique (ShellConfig.options
            // .wallpaper.path vaut "" par defaut) : le PanelWindow de fond
            // existe mais reste noir. Des qu'une liste exploitable arrive,
            // on applique la premiere image et on la persiste, pour que le
            // shell ait un fond sense des la premiere utilisation.
            if (root.currentWallpaper === "" && out.length > 0) {
                root.setWallpaper(out[0].path, true)
            }
        }
    }

    Connections {
        target: ShellConfig
        function onReadyChanged() {
            if (ShellConfig.ready) root.refreshWallpaperList()
        }
    }

    function refreshWallpaperList() { wallProc.running = true }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refreshWallpaperList()
    }

    Timer {
        interval: ShellConfig.options.spotlight.indexing.incrementalMinutes * 60 * 1000
        running: true
        repeat: true
        onTriggered: incrementalIndexProc.running = true
    }

    Timer {
        interval: ShellConfig.options.spotlight.indexing.fullReindexHours * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: indexProc.running = true
    }

    function searchIndex(query, limit) {
        var q = query.toLowerCase()
        var out = []
        for (var i = 0; i < root.fileIndex.length; i++) {
            if (root.fileIndex[i].toLowerCase().indexOf(q) !== -1) {
                out.push(root.fileIndex[i])
                if (out.length >= (limit || 30)) break
            }
        }
        return out
    }

    property var recentFiles: []

    Process {
        id: recentXbelProc
        command: ["bash", "-c",
            "f=~/.local/share/recently-used.xbel; " +
            "[ -f \"$f\" ] || exit 0; " +
            "awk '/<bookmark / { href=\"\"; visited=\"\"; if (match($0, /href=\"[^\"]*\"/)) { href=substr($0, RSTART+6, RLENGTH-7) } if (match($0, /visited=\"[^\"]*\"/)) { visited=substr($0, RSTART+9, RLENGTH-10) } if (href != \"\") print visited \"\\t\" href }' \"$f\" " +
            "| sort -r | cut -f2- | sed 's#^file://##' " +
            "| while IFS= read -r p; do printf '%b\\n' \"${p//%/\\\\x}\"; done"
        ]
        stdout: StdioCollector { id: recentXbelOut }
        onExited: {
            var lines = recentXbelOut.text.trim().split("\n")
            var out = []
            for (var i = 0; i < lines.length; i++) { if (lines[i]) out.push(lines[i]) }
            root.recentFiles = out
        }
    }

    onOpenedChanged: {
        if (root.opened) {
            recentXbelProc.running = true
            root.refreshClipHistory()
            root.refreshUserActions()
            root.refreshWallpaperList()
        }
    }

    readonly property string clipDir: "$HOME/.cache/quickshell/spotlight_clip"

    Component.onCompleted: {
        if (ShellConfig.ready) root.refreshWallpaperList()

        var textScript =
            "#!/usr/bin/env bash\n" +
            "content=$(cat)\n" +
            "[ -z \"$content\" ] && exit 0\n" +
            "dir=\"$HOME/.cache/quickshell/spotlight_clip\"\n" +
            "mkdir -p \"$dir\"\n" +
            "last=$(ls -t \"$dir\"/*.txt 2>/dev/null | head -1)\n" +
            "if [ -n \"$last\" ] && [ \"$(cat \"$last\")\" = \"$content\" ]; then exit 0; fi\n" +
            "printf '%s' \"$content\" > \"$dir/$(date +%s%N).txt\"\n" +
            "ls -t \"$dir\" | tail -n +61 | while IFS= read -r old; do rm -f \"$dir/$old\"; done\n"

        var imageScript =
            "#!/usr/bin/env bash\n" +
            "dir=\"$HOME/.cache/quickshell/spotlight_clip\"\n" +
            "mkdir -p \"$dir\"\n" +
            "f=\"$dir/$(date +%s%N).png\"\n" +
            "cat > \"$f\"\n" +
            "[ -s \"$f\" ] || { rm -f \"$f\"; exit 0; }\n" +
            "ls -t \"$dir\" | tail -n +61 | while IFS= read -r old; do rm -f \"$dir/$old\"; done\n"

        var lensScript =
            "#!/usr/bin/env bash\n" +
            "exec > \"$HOME/.cache/quickshell/spotlight_lens_debug.log\" 2>&1\n" +
            "echo \"=== $(date) ===\"\n" +
            "sleep 0.5\n" +
            "echo \"lancement de slurp...\"\n" +
            "geom=$(slurp)\n" +
            "echo \"resultat slurp: [$geom]\"\n" +
            "if [ -z \"$geom\" ]; then echo \"slurp annule ou echoue\"; exit 1; fi\n" +
            "grim -g \"$geom\" /tmp/lens.png\n" +
            "echo \"code retour grim: $?\"\n" +
            "if [ ! -s /tmp/lens.png ]; then echo \"capture manquante ou vide\"; exit 1; fi\n" +
            "echo \"upload vers uguu.se...\"\n" +
            "response=$(curl -sS --max-time 20 -F \"files[]=@/tmp/lens.png\" https://uguu.se/upload)\n" +
            "echo \"code retour curl: $?\"\n" +
            "echo \"reponse upload: $response\"\n" +
            "imageLink=$(echo \"$response\" | grep -o '\"url\"[[:space:]]*:[[:space:]]*\"[^\"]*\"' | head -1 | sed -e 's/.*\"url\"[[:space:]]*:[[:space:]]*\"//' -e 's/\"$//' -e 's#\\\\/#/#g')\n" +
            "echo \"lien extrait: $imageLink\"\n" +
            "if [ -z \"$imageLink\" ] || [ \"$imageLink\" = \"null\" ]; then echo \"upload echoue, abandon\"; exit 1; fi\n" +
            "xdg-open \"https://lens.google.com/uploadbyurl?url=${imageLink}\"\n" +
            "echo \"code retour xdg-open: $?\"\n" +
            "rm -f /tmp/lens.png\n" +
            "echo \"termine\"\n"

        var textB64  = root.toBase64(textScript)
        var imageB64 = root.toBase64(imageScript)
        var lensB64  = root.toBase64(lensScript)
        clipScriptWriteProc.command = ["bash", "-c",
            "mkdir -p ~/.cache/quickshell && " +
            "echo " + textB64 + " | base64 -d > ~/.cache/quickshell/spotlight_clip_watch.sh && " +
            "echo " + imageB64 + " | base64 -d > ~/.cache/quickshell/spotlight_clip_watch_img.sh && " +
            "echo " + lensB64 + " | base64 -d > ~/.cache/quickshell/spotlight_lens.sh && " +
            "chmod +x ~/.cache/quickshell/spotlight_clip_watch.sh ~/.cache/quickshell/spotlight_clip_watch_img.sh ~/.cache/quickshell/spotlight_lens.sh"
        ]
        clipScriptWriteProc.running = true
    }

    Process {
        id: clipScriptWriteProc
        command: ["true"]
        onExited: {
            clipWatchTextProc.running = true
            clipWatchImageProc.running = true
        }
    }

    Process { id: clipWatchTextProc;  command: ["bash", "-c", "wl-paste --type text --watch bash ~/.cache/quickshell/spotlight_clip_watch.sh"] }
    Process { id: clipWatchImageProc; command: ["bash", "-c", "wl-paste --type image/png --watch bash ~/.cache/quickshell/spotlight_clip_watch_img.sh"] }

    property var clipHistory: []

    function refreshClipHistory() {
        clipListProc.command = ["bash", "-c",
            "dir=" + root.clipDir + "; " +
            "[ -d \"$dir\" ] || exit 0; " +
            "ls -t \"$dir\" | head -n " + ShellConfig.options.spotlight.clipboard.maxEntries + " | while IFS= read -r f; do " +
            "case \"$f\" in " +
            "*.png) printf 'image\\t%s/%s\\t\\n' \"$dir\" \"$f\" ;; " +
            "*.txt) line=$(tr '\\n' ' ' < \"$dir/$f\" | cut -c1-80); printf 'text\\t%s/%s\\t%s\\n' \"$dir\" \"$f\" \"$line\" ;; " +
            "esac; done"
        ]
        clipListProc.running = true
    }

    Process {
        id: clipListProc
        stdout: StdioCollector { id: clipListOut }
        onExited: {
            var lines = clipListOut.text.split("\n")
            var out = []
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i]
                if (!l) continue
                var parts = l.split("\t")
                if (parts.length < 2) continue
                out.push({ type: parts[0], ref: parts[1], preview: parts[2] || "" })
            }
            root.clipHistory = out
        }
    }

    readonly property var systemActions: [
        { title: "Screenshot région",    description: "Prefix: > | Capture zone",             cmd: "sleep 0.5 && grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png", icon: "screenshot/region.svg",  keywords: ["screenshot", "capture", "zone", "region"], instantClose: true },
        { title: "Screenshot écran",     description: "Prefix: > | Capture totale",           cmd: "sleep 0.5 && grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png", icon: "screenshot/monitor.svg", keywords: ["screenshot", "capture", "ecran", "screen", "full"], instantClose: true },
        { title: "Screenshot fenêtre",   description: "Prefix: > | Capture fenêtre active",   cmd: "sleep 0.5 && geom=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'); grim -g \"$geom\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png", icon: "screenshot/monitor.svg", keywords: ["screenshot", "capture", "fenetre", "window", "active"], instantClose: true },
        { title: "Sélecteur de couleur", description: "Prefix: > | Copier une couleur (hex)", cmd: "sleep 0.5 && hyprpicker -a", icon: "color-picker", keywords: ["color", "couleur", "picker", "hex", "pipette"], instantClose: true },
        { title: "Google Lens",          description: "Prefix: > | Recherche visuelle",       cmd: "~/.cache/quickshell/spotlight_lens.sh", icon: "search.svg", keywords: ["lens", "image", "visuelle"], instantClose: true },
        { title: "Lock",                 description: "Prefix: > | Verrouiller",              cmd: "hyprlock", icon: "lock.svg", keywords: ["lock", "verrouiller", "verrou"] },
        { title: "Sleep",                description: "Prefix: > | Veille",                   cmd: "systemctl suspend", icon: "indicator.svg", keywords: ["sleep", "veille", "suspend"] },
        { title: "Hibernate",            description: "Prefix: > | Veille prolongée",         cmd: "systemctl hibernate", icon: "system-suspend-hibernate", keywords: ["hibernate", "hiberner", "veille prolongee"] },
        { title: "Reboot",               description: "Prefix: > | Redémarrer (fermeture propre des apps)", cmd: "hyprshutdown -t 'Redémarrage...' --post-cmd 'systemctl reboot'", icon: "arrow-counterclockwise.svg", keywords: ["reboot", "redemarrer", "restart"] },
        { title: "Redémarrer vers le BIOS", description: "Prefix: > | Reboot vers le firmware/UEFI (fermeture propre des apps)", cmd: "hyprshutdown -t 'Redémarrage vers le BIOS...' --post-cmd 'systemctl reboot --firmware-setup'", icon: "system-reboot", keywords: ["bios", "uefi", "firmware", "reboot"] },
        { title: "Shutdown",             description: "Prefix: > | Éteindre (fermeture propre des apps)",   cmd: "hyprshutdown -t 'Extinction...' --post-cmd 'systemctl poweroff'", icon: "system-shutdown", keywords: ["shutdown", "eteindre", "poweroff", "arret"] },
        { title: "Déconnexion",          description: "Prefix: > | Quitter la session (fermeture propre des apps)", cmd: "hyprshutdown -t 'Déconnexion...'", icon: "system-log-out", keywords: ["logout", "deconnexion", "exit", "session"] },
        { title: "Vider le presse-papier", description: "Prefix: > | Efface tout l'historique", cmd: "rm -rf ~/.cache/quickshell/spotlight_clip/*", icon: "edit-clear-all", keywords: ["wipe", "vider", "clipboard", "presse-papier", "clear"] },
        { title: "Fond d'écran aléatoire", description: "Prefix: > | Change le fond d'écran au hasard", icon: "media-playlist-shuffle", randomWallpaper: true, keywords: ["random", "aleatoire", "wallpaper", "hasard", "wall"] },
        { title: "Réindexer les fichiers", description: "Prefix: > | Actualiser l'index de recherche", icon: "view-refresh", reindex: true, keywords: ["reindex", "index", "actualiser", "refresh"] }
    ]

    property var userActions: []

    Process {
        id: userActionsProc
        running: true
        command: ["bash", "-c", "dir=~/.config/quickshell/spotlight/actions; mkdir -p \"$dir\"; find \"$dir\" -maxdepth 1 -type f -executable -printf '%f\\n' 2>/dev/null | sort"]
        stdout: StdioCollector { id: userActionsOut }
        onExited: {
            var lines = userActionsOut.text.trim().split("\n")
            var out = []
            for (var i = 0; i < lines.length; i++) {
                var fname = lines[i]
                if (!fname) continue
                var name = fname.replace(/\.[^.]+$/, "")
                out.push({ title: name, description: "Action perso: >" + name.toLowerCase(), icon: "system-run", cmd: "~/.config/quickshell/spotlight/actions/" + fname, keywords: [name.toLowerCase()] })
            }
            root.userActions = out
        }
    }

    function refreshUserActions() { userActionsProc.running = true }

    readonly property var allActions: root.systemActions.concat(root.userActions).filter(function(a) {
        return ShellConfig.options.spotlight.disabledActions.indexOf(a.title) === -1
    })

    function emojiCdnUrl(emoji) {
        var codes = []
        var arr = Array.from(emoji)
        for (var i = 0; i < arr.length; i++) {
            var cp = arr[i].codePointAt(0)
            if (cp === 0xFE0F) continue
            codes.push(cp.toString(16))
        }
        return "https://cdn.jsdelivr.net/npm/emoji-datasource-apple@15.1.2/img/apple/64/" + codes.join("-") + ".png"
    }

    readonly property var calcAliases:   [ShellConfig.options.spotlight.aliases.calc,   "calc "]
    readonly property var searchAliases: [ShellConfig.options.spotlight.aliases.search, "search "]
    readonly property var wallAliases:   [ShellConfig.options.spotlight.aliases.wall,   "wall"]
    readonly property var emojiAliases:  [ShellConfig.options.spotlight.aliases.emoji,  "emoji "]
    readonly property var shellAliases:  [ShellConfig.options.spotlight.aliases.sh,     "sh "]
    readonly property var todoAliases:   [ShellConfig.options.spotlight.aliases.todo,   "todo "]
    readonly property var prefixWords:   ["calc ", "search ", "wall", "emoji ", "sh ", "todo "]

    function extractRest(sub, aliases) {
        var lower = sub.toLowerCase()
        for (var i = 0; i < aliases.length; i++) {
            if (lower.indexOf(aliases[i]) === 0) return sub.substring(aliases[i].length)
        }
        return null
    }

    function computeTabHint(sub) {
        var lower = sub.toLowerCase()
        if (lower === "") return ""
        for (var i = 0; i < root.prefixWords.length; i++) {
            var w = root.prefixWords[i]
            if (w.indexOf(lower) === 0 && lower.length < w.length) return w.substring(lower.length)
        }
        return ""
    }

    readonly property var appCategoryOrder: [
        "Réseaux sociaux", "Internet", "Bureautique", "Finance", "Développement",
        "Graphisme", "Audio", "Vidéo", "Jeux", "Éducation", "Science",
        "Système", "Utilitaires", "Accessibilité", "Autres"
    ]

    function categoryForApp(entry) {
        var cats = (entry.categories || []).map(function(c) { return c.toLowerCase() })
        function has(list) { for (var i = 0; i < list.length; i++) if (cats.indexOf(list[i]) !== -1) return true; return false }
        if (has(["chat", "instantmessaging"])) return "Réseaux sociaux"
        if (has(["network", "webbrowser", "email", "filetransfer", "videoconference"])) return "Internet"
        if (has(["finance"])) return "Finance"
        if (has(["office"])) return "Bureautique"
        if (has(["development"])) return "Développement"
        if (has(["graphics", "photography"])) return "Graphisme"
        if (has(["audio"])) return "Audio"
        if (has(["video", "audiovideo"])) return "Vidéo"
        if (has(["game"])) return "Jeux"
        if (has(["education"])) return "Éducation"
        if (has(["science"])) return "Science"
        if (has(["settings", "system"])) return "Système"
        if (has(["accessibility"])) return "Accessibilité"
        if (has(["utility"])) return "Utilitaires"
        return "Autres"
    }

    readonly property var fileCategoryOrder: [
        "PDF", "Word", "Tableurs", "Présentations", "Texte", "Markdown",
        "Web", "Code", "Scripts", "Configuration", "Données", "Bases de données",
        "Images", "Images RAW", "Vidéos", "Audio", "Polices",
        "Archives", "Exécutables", "Disques & ISO", "Livres numériques",
        "Modèles 3D", "CAO", "SIG & Cartes", "Certificats & Clés",
        "Jeux & ROM", "IA & Machine Learning", "Torrents", "Autres"
    ]

    readonly property var fileCategoryMap: ({
        pdf: "PDF", xps: "PDF", oxps: "PDF",
        doc: "Word", docx: "Word", docm: "Word", odt: "Word", ott: "Word", rtf: "Word", wpd: "Word", pages: "Word",
        xls: "Tableurs", xlsx: "Tableurs", xlsm: "Tableurs", xlsb: "Tableurs", ods: "Tableurs", ots: "Tableurs", csv: "Tableurs", tsv: "Tableurs", numbers: "Tableurs", gnumeric: "Tableurs",
        ppt: "Présentations", pptx: "Présentations", pptm: "Présentations", odp: "Présentations", key: "Présentations", gslides: "Présentations",
        txt: "Texte", log: "Texte", nfo: "Texte", readme: "Texte",
        md: "Markdown", markdown: "Markdown", mkd: "Markdown", rst: "Markdown", adoc: "Markdown", asciidoc: "Markdown", org: "Markdown",
        html: "Web", htm: "Web", xhtml: "Web", css: "Web", scss: "Web", sass: "Web", less: "Web", vue: "Web", svelte: "Web", astro: "Web",
        js: "Code", mjs: "Code", cjs: "Code", jsx: "Code", ts: "Code", tsx: "Code",
        c: "Code", h: "Code", cpp: "Code", hpp: "Code", cc: "Code", cs: "Code",
        java: "Code", kt: "Code", kts: "Code", swift: "Code", qml: "Code", lua: "Code",
        dart: "Code", scala: "Code", clj: "Code", ex: "Code", exs: "Code", erl: "Code", hrl: "Code",
        hs: "Code", ml: "Code", mli: "Code", rkt: "Code", lisp: "Code", jl: "Code", nim: "Code",
        fs: "Code", fsx: "Code", vb: "Code", pas: "Code", asm: "Code", s: "Code", f90: "Code", f95: "Code", cob: "Code", cbl: "Code", r: "Code",
        sh: "Scripts", bash: "Scripts", zsh: "Scripts", fish: "Scripts", csh: "Scripts", ksh: "Scripts",
        py: "Scripts", pyw: "Scripts", pl: "Scripts", pm: "Scripts", rb: "Scripts", rake: "Scripts",
        ps1: "Scripts", psm1: "Scripts", bat: "Scripts", cmd: "Scripts", vbs: "Scripts", awk: "Scripts", tcl: "Scripts",
        json: "Configuration", jsonc: "Configuration", json5: "Configuration", yaml: "Configuration", yml: "Configuration",
        toml: "Configuration", ini: "Configuration", conf: "Configuration", cfg: "Configuration", config: "Configuration",
        nix: "Configuration", env: "Configuration", properties: "Configuration", plist: "Configuration",
        gitignore: "Configuration", gitattributes: "Configuration", dockerignore: "Configuration", editorconfig: "Configuration",
        xml: "Données", jsonl: "Données", ndjson: "Données", parquet: "Données", orc: "Données", avro: "Données",
        arrow: "Données", feather: "Données", xsd: "Données", dtd: "Données", rdf: "Données", ttl: "Données",
        db: "Bases de données", sqlite: "Bases de données", sqlite3: "Bases de données", mdb: "Bases de données",
        accdb: "Bases de données", mdf: "Bases de données", ldf: "Bases de données", bak: "Bases de données",
        dbf: "Bases de données", dump: "Bases de données", rdb: "Bases de données", sql: "Bases de données",
        png: "Images", jpg: "Images", jpeg: "Images", jfif: "Images", gif: "Images", bmp: "Images",
        webp: "Images", avif: "Images", heic: "Images", heif: "Images", tiff: "Images", tif: "Images",
        ico: "Images", svg: "Images", svgz: "Images", psd: "Images", xcf: "Images", kra: "Images", ora: "Images",
        raw: "Images RAW", cr2: "Images RAW", cr3: "Images RAW", nef: "Images RAW", arw: "Images RAW",
        dng: "Images RAW", orf: "Images RAW", rw2: "Images RAW", raf: "Images RAW", pef: "Images RAW", srw: "Images RAW",
        mp4: "Vidéos", m4v: "Vidéos", mkv: "Vidéos", webm: "Vidéos", avi: "Vidéos", mov: "Vidéos", qt: "Vidéos",
        wmv: "Vidéos", asf: "Vidéos", mpg: "Vidéos", mpeg: "Vidéos", mts: "Vidéos", m2ts: "Vidéos", mxf: "Vidéos",
        vob: "Vidéos", ogv: "Vidéos", flv: "Vidéos", f4v: "Vidéos", "3gp": "Vidéos", "3g2": "Vidéos", rm: "Vidéos", rmvb: "Vidéos", divx: "Vidéos",
        mp3: "Audio", wav: "Audio", wave: "Audio", aiff: "Audio", aif: "Audio", flac: "Audio", alac: "Audio",
        m4a: "Audio", aac: "Audio", ac3: "Audio", ogg: "Audio", oga: "Audio", opus: "Audio", wma: "Audio",
        amr: "Audio", ape: "Audio", mid: "Audio", midi: "Audio",
        ttf: "Polices", otf: "Polices", ttc: "Polices", woff: "Polices", woff2: "Polices", eot: "Polices",
        pfb: "Polices", pfm: "Polices", fon: "Polices",
        zip: "Archives", zipx: "Archives", rar: "Archives", "7z": "Archives", tar: "Archives", gz: "Archives",
        tgz: "Archives", bz2: "Archives", xz: "Archives", zst: "Archives", lz4: "Archives", cab: "Archives",
        arj: "Archives", ace: "Archives", lzh: "Archives", lha: "Archives",
        exe: "Exécutables", msi: "Exécutables", msix: "Exécutables", appx: "Exécutables", deb: "Exécutables",
        rpm: "Exécutables", appimage: "Exécutables", pkg: "Exécutables", apk: "Exécutables", aab: "Exécutables",
        ipa: "Exécutables", bin: "Exécutables", run: "Exécutables", com: "Exécutables",
        iso: "Disques & ISO", dmg: "Disques & ISO", vhd: "Disques & ISO", vhdx: "Disques & ISO", vdi: "Disques & ISO",
        vmdk: "Disques & ISO", qcow: "Disques & ISO", qcow2: "Disques & ISO", cue: "Disques & ISO", nrg: "Disques & ISO", toast: "Disques & ISO",
        epub: "Livres numériques", mobi: "Livres numériques", azw: "Livres numériques", azw3: "Livres numériques",
        fb2: "Livres numériques", cbz: "Livres numériques", cbr: "Livres numériques", cb7: "Livres numériques",
        cbt: "Livres numériques", chm: "Livres numériques", djvu: "Livres numériques", djv: "Livres numériques",
        obj: "Modèles 3D", fbx: "Modèles 3D", gltf: "Modèles 3D", glb: "Modèles 3D", dae: "Modèles 3D",
        blend: "Modèles 3D", "3ds": "Modèles 3D", "3dm": "Modèles 3D", stl: "Modèles 3D", ply: "Modèles 3D",
        usd: "Modèles 3D", usdz: "Modèles 3D", max: "Modèles 3D", c4d: "Modèles 3D",
        dwg: "CAO", dxf: "CAO", dwf: "CAO", dgn: "CAO", step: "CAO", stp: "CAO", iges: "CAO", igs: "CAO",
        sldprt: "CAO", sldasm: "CAO", ipt: "CAO", iam: "CAO",
        shp: "SIG & Cartes", shx: "SIG & Cartes", gpx: "SIG & Cartes", kml: "SIG & Cartes", kmz: "SIG & Cartes",
        geojson: "SIG & Cartes", gpkg: "SIG & Cartes", mbtiles: "SIG & Cartes",
        pem: "Certificats & Clés", crt: "Certificats & Clés", cer: "Certificats & Clés", der: "Certificats & Clés",
        gpg: "Certificats & Clés", asc: "Certificats & Clés", pfx: "Certificats & Clés", p12: "Certificats & Clés",
        csr: "Certificats & Clés", jks: "Certificats & Clés", ppk: "Certificats & Clés",
        nes: "Jeux & ROM", sfc: "Jeux & ROM", smc: "Jeux & ROM", gba: "Jeux & ROM", gbc: "Jeux & ROM", gb: "Jeux & ROM",
        nds: "Jeux & ROM", n64: "Jeux & ROM", z64: "Jeux & ROM", unity: "Jeux & ROM", unitypackage: "Jeux & ROM",
        uasset: "Jeux & ROM", umap: "Jeux & ROM", godot: "Jeux & ROM", pck: "Jeux & ROM",
        onnx: "IA & Machine Learning", pt: "IA & Machine Learning", pth: "IA & Machine Learning", ckpt: "IA & Machine Learning",
        safetensors: "IA & Machine Learning", gguf: "IA & Machine Learning", ggml: "IA & Machine Learning",
        tflite: "IA & Machine Learning", h5: "IA & Machine Learning", keras: "IA & Machine Learning",
        pkl: "IA & Machine Learning", pickle: "IA & Machine Learning", npy: "IA & Machine Learning", npz: "IA & Machine Learning",
        torrent: "Torrents"
    })

    function categoryForFile(path) {
        var name = path.split("/").pop()
        var ext  = name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
        return root.fileCategoryMap[ext] || "Autres"
    }

    property var appUsage: ({})

    function cloneMap(m) { var o = {}; for (var k in m) o[k] = m[k]; return o }

    function toBase64(str) {
        var encoded = encodeURIComponent(str)
        var bytes = []
        for (var i = 0; i < encoded.length; i++) {
            if (encoded[i] === '%') {
                bytes.push(parseInt(encoded.substr(i + 1, 2), 16))
                i += 2
            } else {
                bytes.push(encoded.charCodeAt(i))
            }
        }
        return Qt.btoa(bytes)
    }

    property var todos: []

    Process {
        id: todoLoadProc
        running: true
        command: ["bash", "-c", "cat ~/.cache/quickshell/spotlight_todos.json 2>/dev/null || echo '[]'"]
        stdout: StdioCollector { id: todoLoadOut }
        onExited: {
            try { root.todos = JSON.parse(todoLoadOut.text.trim() || "[]") } catch(e) { root.todos = [] }
        }
    }

    Process { id: todoSaveProc; command: ["true"] }

    function saveTodos() {
        var b64 = root.toBase64(JSON.stringify(root.todos))
        todoSaveProc.command = ["bash", "-c", "mkdir -p ~/.cache/quickshell && echo " + b64 + " | base64 -d > ~/.cache/quickshell/spotlight_todos.json"]
        todoSaveProc.running = true
    }

    function addTodo(text) {
        var list = root.todos.slice()
        list.unshift({ id: Date.now(), text: text, done: false })
        root.todos = list
        root.saveTodos()
    }

    function toggleTodo(id) {
        var list = []
        for (var i = 0; i < root.todos.length; i++) {
            var t = root.todos[i]
            list.push(t.id === id ? { id: t.id, text: t.text, done: !t.done } : t)
        }
        root.todos = list
        root.saveTodos()
    }

    function removeTodo(id) {
        var list = []
        for (var i = 0; i < root.todos.length; i++) {
            if (root.todos[i].id !== id) list.push(root.todos[i])
        }
        root.todos = list
        root.saveTodos()
    }

    Process { id: shellExecProc; command: ["true"] }

    function runShellCommand(cmd) {
        var script = "#!/usr/bin/env bash\n" + cmd + "\nstatus=$?\necho\nif [ $status -eq 0 ]; then echo '[terminé]'; else echo \"[erreur, code $status]\"; fi\nread -p 'Appuyez sur Entrée pour fermer'\n"
        var scriptB64 = root.toBase64(script)
        shellExecProc.command = ["bash", "-c",
            "mkdir -p ~/.cache/quickshell && echo " + scriptB64 + " | base64 -d > ~/.cache/quickshell/spotlight_shell_run.sh && chmod +x ~/.cache/quickshell/spotlight_shell_run.sh && " +
            "term=$(command -v foot || command -v kitty || command -v alacritty || command -v wezterm || command -v xterm); " +
            "\"$term\" -e ~/.cache/quickshell/spotlight_shell_run.sh"
        ]
        shellExecProc.running = true
    }

    function recordAppUsage(data) {
        if (!data || typeof data.execute !== "function") return
        var key = data.name
        if (!key) return
        var counts = root.cloneMap(root.appUsage)
        counts[key] = (counts[key] || 0) + 1
        root.appUsage = counts
        var b64 = root.toBase64(JSON.stringify(counts))
        usageSaveProc.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell && echo " + b64 + " | base64 -d > ~/.cache/quickshell/spotlight_app_usage.json"]
        usageSaveProc.running = true
    }

    function sortAppsByUsage(apps) {
        var usage = root.appUsage
        return apps.slice().sort(function(a, b) {
            var ca = usage[a.name] || 0
            var cb = usage[b.name] || 0
            if (ca !== cb) return cb - ca
            return a.name.localeCompare(b.name)
        })
    }

    function wrapApp(entry, cat) {
        return { name: entry.name, icon: entry.icon, _category: cat, execute: function() { entry.execute() } }
    }

    Process {
        id: usageLoadProc
        running: true
        command: ["sh", "-c", "cat ~/.cache/quickshell/spotlight_app_usage.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector { id: usageLoadOut }
        onExited: {
            try { root.appUsage = JSON.parse(usageLoadOut.text.trim() || "{}") } catch(e) { root.appUsage = {} }
        }
    }

    Process { id: usageSaveProc; command: ["sh", "-c", "true"] }

    // Wallpaper du bureau : source de vérité unique = ShellConfig.options
    // .wallpaper.path (services/shell-config.json). Deux endroits le
    // modifient : ce Spotlight (setWallpaper(..., true)) et la page
    // Réglages > Fond d'écran (WallpaperPage.apply). Les deux doivent
    // se refléter mutuellement sur le bureau.
    //
    // Bug corrigé : currentWallpaper était une propriété avec binding
    // (ShellConfig.options.wallpaper.path) mais setWallpaper() et la
    // restauration après aperçu lui ASSIGNAIENT une valeur, ce qui casse
    // définitivement le binding en QML. Dès que Spotlight avait touché au
    // fond une fois (y compris le fond par défaut appliqué au premier
    // lancement), un changement fait depuis les Réglages n'atteignait
    // plus le bureau.
    //
    // Maintenant : currentWallpaper est en lecture seule et garde son
    // binding. L'aperçu en direct du picker (persist: false, sans écrire
    // sur le disque à chaque image survolée) passe par previewWallpaper,
    // "" = pas d'aperçu en cours. Seul persist: true écrit dans
    // ShellConfig.
    property string previewWallpaper: ""

    readonly property string currentWallpaper: root.previewWallpaper !== ""
        ? root.previewWallpaper
        : ShellConfig.options.wallpaper.path

    function setWallpaper(path, persist) {
        if (persist) {
            // Écrire la config AVANT d'effacer l'aperçu : sinon
            // currentWallpaper repasserait un instant par l'ancien chemin.
            ShellConfig.options.wallpaper.path = path
            root.previewWallpaper = ""
        } else {
            root.previewWallpaper = path
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bgWin
            required property var modelData
            screen: modelData
            WlrLayershell.layer:     WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"
            exclusiveZone: -1
            anchors { top: true; left: true; right: true; bottom: true }
            color: "#000000"

            property string source: root.currentWallpaper
            property var currentImg: null

            onSourceChanged: {
                if (source === "") { currentImg = null; return }
                currentImg = imgComp.createObject(bgContent, { path: source })
            }

            Component.onCompleted: {
                if (source !== "") currentImg = imgComp.createObject(bgContent, { path: source })
            }

            Item {
                id: bgContent
                anchors.fill: parent
            }

            Component {
                id: imgComp
                Image {
                    id: img
                    property string path
                    anchors.fill: parent
                    source: path !== "" ? "file://" + path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // cache: true (plutôt que false comme avant) : cette
                    // fenêtre reste vivante en permanence, donc rebasculer
                    // vers un wallpaper déjà vu (ex: annuler un aperçu
                    // dans le picker) sert depuis le cache Qt au lieu de
                    // redécoder le fichier. sourceSize borne le décodage
                    // à la taille d'affichage réelle de cet écran plutôt
                    // que la résolution native du fichier — c'est ce qui
                    // coûte le plus cher en temps de décodage, largement
                    // plus que la lecture disque elle-même (même
                    // stratégie que CachingImage de caelestia).
                    cache: true
                    sourceSize: Qt.size(bgWin.width * (bgWin.screen?.devicePixelRatio ?? 1),
                                         bgWin.height * (bgWin.screen?.devicePixelRatio ?? 1))
                    opacity: 0

                    onStatusChanged: if (status === Image.Ready) fadeAnim.start()

                    NumberAnimation on opacity {
                        id: fadeAnim
                        running: false
                        from: 0
                        to: 1
                        duration: 350
                    }

                    Timer {
                        running: bgWin.currentImg !== img && bgWin.currentImg !== null && bgWin.currentImg.status === Image.Ready
                        interval: 360
                        onTriggered: img.destroy()
                    }
                }
            }
        }
    }

    Loader {
        id: spotlightLoader
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: win

                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.namespace:     "quickshell:spotlight"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; left: true; right: true; bottom: true }

                property bool   actionsShown:   false
                property string selectedAction: ""
                property string hoveredAction:  ""
                property int    currentIdx:     0
                property var    fileAnswers:    []
                property var    clipAnswers:    []

                readonly property bool gridMode: (selectedAction === "applications" || selectedAction === "files") && searchField.text === ""
                readonly property bool wallpaperMode: win.answers.length > 0 && win.answers[0].isWallpaper === true

                onAnswersChanged: {
                    if (win.currentIdx >= win.answers.length) win.currentIdx = Math.max(0, win.answers.length - 1)
                }

                onWallpaperModeChanged: {
                    if (win.wallpaperMode) {
                        if (win.answers.length > 0) wallPreviewDebounce.trigger(win.answers[win.currentIdx].path)
                    } else {
                        wallPreviewDebounce.stop()
                        root.previewWallpaper = ""
                    }
                }
                onCurrentIdxChanged: {
                    if (win.wallpaperMode && win.answers[win.currentIdx]) wallPreviewDebounce.trigger(win.answers[win.currentIdx].path)
                }

                Timer {
                    id: wallPreviewDebounce
                    interval: 120
                    repeat: false
                    property string pendingPath: ""
                    function trigger(path) { pendingPath = path; restart() }
                    onTriggered: root.setWallpaper(pendingPath, false)
                }

                property var unifiedSections: {
                    if (win.selectedAction !== "search") return []
                    var t = searchField.text
                    if (t === "") return []
                    var tl = t.toLowerCase()
                    var sections = []

                    var apps = DesktopEntries.applications.values
                        .filter(function(a) { return a.name.toLowerCase().indexOf(tl) !== -1 })
                        .sort(function(a, b) {
                            var ca = root.appUsage[a.name] || 0, cb = root.appUsage[b.name] || 0
                            if (ca !== cb) return cb - ca
                            var ai = a.name.toLowerCase().indexOf(tl), bi = b.name.toLowerCase().indexOf(tl)
                            return ai !== bi ? ai - bi : a.name.localeCompare(b.name)
                        })
                        .slice(0, 5)
                    if (apps.length > 0) sections.push({ title: "Applications", items: apps })

                    var filePaths = root.searchIndex(t, 6)
                    if (filePaths.length > 0) {
                        var fileEntries = []
                        for (var fi = 0; fi < filePaths.length; fi++) fileEntries.push(win.makeFileEntry(filePaths[fi]))
                        sections.push({ title: "Fichiers", items: fileEntries })
                    }

                    var sys = root.allActions.filter(function(a) {
                        if (a.title.toLowerCase().indexOf(tl) !== -1) return true
                        if (a.keywords) {
                            for (var ki = 0; ki < a.keywords.length; ki++) {
                                if (a.keywords[ki].indexOf(tl) !== -1) return true
                            }
                        }
                        return false
                    }).slice(0, 4)
                    if (sys.length > 0) sections.push({ title: "Actions", items: sys })

                    var mathStripped = t.trim().replace(/\b(pi|tau|e|phi)\b/gi, "").replace(/\b(sqrt|cbrt|abs|sin|cos|tan|asin|acos|atan|sinh|cosh|tanh|ln|log2|log|exp|floor|ceil|round|sign|min|max|pow|atan2|hypot)\b/gi, "")
                    if (ShellConfig.options.spotlight.sources.calculator && /[0-9]/.test(t) && /^[0-9+\-*/^%!().,\s]*$/.test(mathStripped)) {
                        var calcRes = Calc.evaluate(t)
                        if (calcRes.ok) {
                            sections.push({ title: "Calculatrice", items: [{ title: calcRes.display, description: "Entrée pour copier", icon: "accessories-calculator", isCalc: true, value: calcRes.display }] })
                        } else {
                            sections.push({ title: "Calculatrice", items: [{ title: calcRes.error, description: "Expression invalide", icon: "dialog-error", isCalcError: true }] })
                        }
                    }

                    sections.push({ title: "Web", items: [{ title: "Rechercher '" + t + "'", description: "Recherche", icon: "internet-web-browser", isWeb: true, query: t }] })

                    return sections
                }

                property list<var> answers: {
                    var t = searchField.text
                    var action = win.selectedAction

                    if (t.startsWith(">")) {
                        var sub = t.substring(1)
                        var out = []

                        var calcRest = root.extractRest(sub, root.calcAliases)
                        if (calcRest !== null) {
                            var expr = calcRest.trim()
                            if (expr !== "") {
                                var calcRes2 = Calc.evaluate(expr)
                                if (calcRes2.ok) {
                                    out.push({ title: calcRes2.display, description: "Calculatrice (Entrée pour copier)", icon: "accessories-calculator", isCalc: true, value: calcRes2.display })
                                } else {
                                    out.push({ title: calcRes2.error, description: "Expression invalide", icon: "dialog-error", isCalcError: true })
                                }
                            }
                        }
                        else {
                            var searchRest = root.extractRest(sub, root.searchAliases)
                            if (searchRest !== null) {
                                var q = searchRest.trim()
                                if (q !== "") {
                                    out.push({ title: "Rechercher '" + q + "'", description: "Recherche", icon: "internet-web-browser", isWeb: true, query: q })
                                }
                            }
                            else {
                                var wallRest = root.extractRest(sub, root.wallAliases)
                                if (wallRest !== null) {
                                    var wq = wallRest.trim().toLowerCase()
                                    for (var i = 0; i < root.wallpaperList.length; i++) {
                                        if (wq === "" || root.wallpaperList[i].title.toLowerCase().indexOf(wq) !== -1) {
                                            out.push(root.wallpaperList[i])
                                        }
                                    }
                                }
                                else {
                                    var emojiRest = root.extractRest(sub, root.emojiAliases)
                                    if (emojiRest !== null) {
                                        var eq = emojiRest.trim().toLowerCase()
                                        var edata = EmojiData.list()
                                        for (var ei = 0; ei < edata.length && out.length < 40; ei++) {
                                            var erow = edata[ei]
                                            if (eq === "" || erow[1].indexOf(eq) !== -1 || erow[2].indexOf(eq) !== -1) {
                                                out.push({ title: erow[1], description: "Emoji · Entrée pour copier", isEmoji: true, value: erow[0], emojiUrl: root.emojiCdnUrl(erow[0]) })
                                            }
                                        }
                                    }
                                    else {
                                        var shellRest = root.extractRest(sub, root.shellAliases)
                                        if (shellRest !== null) {
                                            var scmd = shellRest.trim()
                                            if (scmd !== "") {
                                                out.push({ title: scmd, description: "Commande shell · Entrée pour exécuter dans un terminal", icon: "utilities-terminal", isShellCmd: true, value: scmd })
                                            }
                                        }
                                        else {
                                            var todoRest = root.extractRest(sub, root.todoAliases)
                                            if (todoRest !== null) {
                                                var task = todoRest.trim()
                                                if (task !== "") {
                                                    out.push({ title: "Ajouter : '" + task + "'", description: "Entrée pour enregistrer", icon: "task-due", isTodoAdd: true, value: task })
                                                } else if (root.todos.length === 0) {
                                                    out.push({ title: "Aucune tâche", description: "Tape du texte après >todo pour en ajouter", icon: "task-due", dummy: true, targetPrefix: ">todo " })
                                                } else {
                                                    for (var ti = 0; ti < root.todos.length; ti++) {
                                                        var td = root.todos[ti]
                                                        out.push({
                                                            title: td.text,
                                                            description: td.done ? "Terminé · Entrée pour supprimer" : "Entrée pour marquer comme terminé",
                                                            icon: td.done ? "checkbox-checked" : "checkbox",
                                                            isTodoItem: true,
                                                            todoId: td.id,
                                                            todoDone: td.done
                                                        })
                                                    }
                                                }
                                            }
                                            else {
                                                var filter = sub.trim().toLowerCase()
                                                if (filter === "") {
                                                    out.push({ title: "Calculatrice",    description: "Prefix: >= ou >calc — pi, e, sin, sqrt, log, ^, !, %...", icon: "accessories-calculator", dummy: true, targetPrefix: ">calc " })
                                                    out.push({ title: "Recherche", description: "Prefix: >? ou >search",  icon: "internet-web-browser",   dummy: true, targetPrefix: ">search " })
                                                    out.push({ title: "Fonds d'écran",   description: "Prefix: >~ ou >wall",    icon: "image-x-generic",        dummy: true, targetPrefix: ">wall " })
                                                    out.push({ title: "Emoji",           description: "Prefix: >: ou >emoji",   icon: "face-smile",             dummy: true, targetPrefix: ">emoji " })
                                                    out.push({ title: "Commande shell",  description: "Prefix: >$ ou >sh",      icon: "utilities-terminal",     dummy: true, targetPrefix: ">sh " })
                                                    out.push({ title: "Todo",            description: "Prefix: >+ ou >todo — vide pour voir la liste",    icon: "task-due",               dummy: true, targetPrefix: ">todo " })
                                                }
                                                var sys2 = root.allActions.filter(function(a) {
                                                    if (filter === "") return true
                                                    if (a.title.toLowerCase().indexOf(filter) !== -1) return true
                                                    if (a.keywords) {
                                                        for (var ki = 0; ki < a.keywords.length; ki++) {
                                                            if (a.keywords[ki].indexOf(filter) !== -1) return true
                                                        }
                                                    }
                                                    return false
                                                })
                                                for (var j = 0; j < sys2.length; j++) out.push(sys2[j])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        return out
                    }

                    if (action === "search") {
                        if (t === "") return []
                        var flat = []
                        for (var s = 0; s < win.unifiedSections.length; s++) {
                            var sec = win.unifiedSections[s]
                            for (var it = 0; it < sec.items.length; it++) {
                                var item = sec.items[it]
                                var tagged = { _section: sec.title }
                                for (var key in item) tagged[key] = item[key]
                                flat.push(tagged)
                            }
                        }
                        return flat
                    }

                    if (action === "applications") {
                        if (t === "") {
                            var allApps = DesktopEntries.applications.values.slice().sort(function(a, b) { return a.name.localeCompare(b.name) })
                            return allApps
                        }
                        return DesktopEntries.applications.values
                            .filter(function(a) { return a.name.toLowerCase().indexOf(t.toLowerCase()) !== -1 })
                            .sort(function(a, b) {
                                var ai = a.name.toLowerCase().indexOf(t.toLowerCase())
                                var bi = b.name.toLowerCase().indexOf(t.toLowerCase())
                                return ai !== bi ? ai - bi : a.name.localeCompare(b.name)
                            })
                            .slice(0, 12)
                    }

                    if (action === "files")     return win.fileAnswers
                    if (action === "clipboard") return win.clipAnswers
                    return []
                }

                readonly property string topHitLabel: {
                    if (searchField.text === "" || win.answers.length === 0) return ""
                    var a = win.answers[win.currentIdx] || win.answers[0]
                    if (!a || a.dummy) return ""
                    if (typeof a.execute === "function") return "Ouvrir"
                    if (a.isWallpaper) return "Appliquer"
                    if (a.isCalc) return "Copier"
                    if (a.isWeb) return "Rechercher"
                    if (a.clipFile) return "Copier"
                    if (a.clipImage) return "Copier"
                    if (a.isEmoji) return "Copier"
                    if (a.isShellCmd) return "Exécuter"
                    if (a.isTodoAdd) return "Enregistrer"
                    if (a.isTodoItem) return a.todoDone ? "Supprimer" : "Marquer fait"
                    if (a.randomWallpaper) return "Changer"
                    if (a.reindex) return "Actualiser"
                    if (a.cmd) return "Exécuter"
                    if (a.path) return "Ouvrir"
                    return ""
                }

                property var appItems: {
                    if (win.selectedAction !== "applications" || searchField.text !== "") return []
                    var apps = DesktopEntries.applications.values.slice()
                    var sorted = root.sortAppsByUsage(apps)
                    var out = []
                    for (var i = 0; i < sorted.length; i++) out.push(root.wrapApp(sorted[i], root.categoryForApp(sorted[i])))
                    return out
                }
                property var fileItems: {
                    if (win.selectedAction !== "files" || searchField.text !== "") return []
                    return win.fileAnswers
                }

                function makeFileEntry(p) {
                    var parts = p.split("/")
                    var name  = parts[parts.length - 1]
                    var ext   = name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
                    var cat   = root.categoryForFile(p)
                    return {
                        name: name, title: name, description: p,
                        icon: ext === "pdf" ? "application-pdf"
                            : cat === "Images" ? "image-x-generic"
                            : (ext === "mp4" || ext === "mkv") ? "video-x-generic"
                            : (ext === "mp3" || ext === "flac") ? "audio-x-generic"
                            : "text-x-generic",
                        path: p,
                        isImage: cat === "Images",
                        _category: cat
                    }
                }

                function refreshFiles(query) {
                    var paths
                    if (query === "") {
                        var seen = {}
                        var combined = []
                        for (var ri = 0; ri < root.recentFiles.length; ri++) {
                            var rp = root.recentFiles[ri]
                            if (!seen[rp]) { seen[rp] = true; combined.push(rp) }
                        }
                        for (var fi = 0; fi < root.fileIndex.length && combined.length < 150; fi++) {
                            var fp = root.fileIndex[fi]
                            if (!seen[fp]) { seen[fp] = true; combined.push(fp) }
                        }
                        paths = combined.slice(0, 150)
                    } else {
                        paths = root.searchIndex(query, 30)
                    }
                    var out = []
                    for (var i = 0; i < paths.length; i++) out.push(win.makeFileEntry(paths[i]))
                    win.fileAnswers = out
                    win.currentIdx  = 0
                }

                function clickAction(action) {
                    if (action === "applications" && !ShellConfig.options.spotlight.sources.applications) return
                    if (action === "files" && !ShellConfig.options.spotlight.sources.files) return
                    if (action === "actions" && !ShellConfig.options.spotlight.sources.actions) return
                    hoveredAction  = ""
                    selectedAction = action
                    actionsShown   = false
                    currentIdx     = 0
                    if (action === "clipboard") { root.refreshClipHistory(); win.refreshClipboard(searchField.text) }
                    if (action === "files") win.refreshFiles(searchField.text)
                    if (action === "actions") {
                        if (!searchField.text.startsWith(">")) searchField.text = ">"
                    }
                    if (action === "wallpapers") {
                        searchField.text = ">wall "
                    }
                }

                function doClose() {
                    searchField.text = ""
                    actionsShown     = false
                    hoveredAction    = ""
                    selectedAction   = ""
                    currentIdx       = 0
                    fileAnswers      = []
                    clipAnswers      = []
                    root.closeRequested()
                }

                function closeGracefully() { hideAnim.start() }

                function refreshClipboard(query) {
                    var q = query.toLowerCase()
                    var out = []
                    for (var i = 0; i < root.clipHistory.length; i++) {
                        var e = root.clipHistory[i]
                        if (e.type === "image") {
                            if (!ShellConfig.options.spotlight.clipboard.enableImage) continue
                            if (q !== "") continue
                            out.push({ name: "Image copiée", title: "Image copiée", description: "Presse-papier · Image", clipImage: e.ref })
                        } else {
                            if (!ShellConfig.options.spotlight.clipboard.enableText) continue
                            if (q !== "" && e.preview.toLowerCase().indexOf(q) === -1) continue
                            out.push({ name: e.preview, title: e.preview, description: "Presse-papier · Texte", icon: "edit-paste", clipFile: e.ref })
                        }
                    }
                    win.clipAnswers = out
                    win.currentIdx  = 0
                }

                property string shellOutput:    ""
                property string shellOutputCmd: ""
                property bool   showingShellOutput: false

                function runInlineShell(cmd) {
                    win.shellOutputCmd = cmd
                    shellCaptureProc.command = ["bash", "-c", cmd]
                    shellCaptureProc.running = true
                }

                Process {
                    id: shellCaptureProc
                    stdout: StdioCollector { id: shellCaptureOut }
                    stderr: StdioCollector { id: shellCaptureErr }
                    onExited: {
                        var out = shellCaptureOut.text
                        var err = shellCaptureErr.text
                        var combined = out
                        if (err.trim() !== "") combined += (combined.trim() !== "" ? "\n\n--- erreurs ---\n" : "") + err
                        if (combined.trim() === "") combined = "(aucune sortie)"
                        win.shellOutput = combined
                        win.showingShellOutput = true
                    }
                }

                Component.onCompleted: {
                    showAnim.start()
                    searchField.forceActiveFocus()
                }

                SequentialAnimation {
                    id: showAnim
                    ParallelAnimation {
                        PropertyAnimation { target: bgPanel; property: "opacity";  from: 0;   to: 1;   duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 }
                        PropertyAnimation { target: bgPanel; property: "bgScaleX"; from: 1.3; to: 1.0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 }
                    }
                }
                SequentialAnimation {
                    id: hideAnim
                    ParallelAnimation {
                        PropertyAnimation { target: bgPanel; property: "opacity";  from: 1; to: 0;   duration: 200 }
                        PropertyAnimation { target: bgPanel; property: "bgScaleX"; from: 1; to: 1.1; duration: 130 }
                    }
                    ScriptAction { script: win.doClose() }
                }

                MouseArea { anchors.fill: parent; onClicked: hideAnim.start() }

                BoxGlass {
                    id: bgPanel
                    property real bgScaleX: 1.0
                    z: 1; opacity: 0
                    anchors.top:              parent.top
                    anchors.topMargin:        200
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: (win.gridMode || win.showingShellOutput) ? 680 : (win.actionsShown ? 340 : 540)
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                    implicitHeight: panelCol.implicitHeight + 8
                    radius: 30; color: root.glassColor; rimStrength: 1.7
                    light: "#20ffffff"; lightDir: Qt.vector2d(1, 1); layer.enabled: true
                    transform: Scale { xScale: bgPanel.bgScaleX; origin.x: bgPanel.width / 2 }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked:    mouse.accepted = true
                        onPositionChanged: {
                            if (win.selectedAction !== "") return
                            win.actionsShown  = true
                            win.hoveredAction = ""
                        }

                        ColumnLayout {
                            id:              panelCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 4
                            spacing:         0

                            Item {
                                Layout.fillWidth:       true
                                Layout.preferredHeight: 56

                                VectorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     14
                                    width: 24; height: 24
                                    source: {
                                        var b = Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/")
                                        var t = searchField.text
                                        if (t.startsWith(">")) return b + "spotlight/actions.svg"
                                        if (win.selectedAction === "applications") return b + "spotlight/applications.svg"
                                        if (win.selectedAction === "files")        return b + "spotlight/files.svg"
                                        if (win.selectedAction === "actions")      return b + "spotlight/actions.svg"
                                        if (win.selectedAction === "clipboard")    return b + "spotlight/clipboard.svg"
                                        return b + "search.svg"
                                    }
                                    preferredRendererType: VectorImage.CurveRenderer
                                    layer.enabled: true
                                    layer.effect: MultiEffect { colorization: 1; colorizationColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5) }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     48
                                    anchors.right:          parent.right
                                    anchors.rightMargin:    8
                                    font.family:    sfRoundedMedium.name
                                    font.pixelSize: 26
                                    font.weight:    Font.Medium
                                    color:          root.textColor
                                    opacity:        0.5
                                    renderType:     Text.NativeRendering
                                    visible:        searchField.text === ""
                                    elide:          Text.ElideRight
                                    text: {
                                        if (win.hoveredAction === "" && win.selectedAction === "") return "Spotlight Search"
                                        var act = win.hoveredAction !== "" ? win.hoveredAction : win.selectedAction
                                        if (act === "applications") return "Applications"
                                        if (act === "files")        return "Fichiers"
                                        if (act === "actions")      return "Actions"
                                        if (act === "clipboard")    return "Presse-papier"
                                        return "Spotlight Search"
                                    }
                                }

                                TextMetrics {
                                    id:   typedMetrics
                                    font: searchField.font
                                    text: searchField.text
                                }
                                Text {
                                    anchors.verticalCenter: searchField.verticalCenter
                                    x: 48 + typedMetrics.width + 2
                                    text: searchField.text.startsWith(">") ? root.computeTabHint(searchField.text.substring(1)) : ""
                                    visible: text !== "" && searchField.activeFocus
                                    color:   root.textColor
                                    opacity: 0.35
                                    font.family:    sfRoundedMedium.name
                                    font.pixelSize: 26
                                    font.weight:    Font.Medium
                                    renderType:     Text.NativeRendering
                                }

                                Rectangle {
                                    id: topHitBadge
                                    visible: !searchField.text.startsWith(">") && win.topHitLabel !== "" && searchField.activeFocus
                                    anchors.verticalCenter: searchField.verticalCenter
                                    x: 48 + typedMetrics.width + 10
                                    width: badgeLabel.implicitWidth + 16
                                    height: 24
                                    radius: 12
                                    color: "#22ffffff"
                                    Text {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: "—  " + win.topHitLabel
                                        color: root.textColor
                                        opacity: 0.7
                                        font.family:    sfRoundedMedium.name
                                        font.pixelSize: 13
                                        renderType:     Text.NativeRendering
                                    }
                                }

                                TextField {
                                    id: searchField
                                    anchors.fill:        parent
                                    anchors.leftMargin:  48
                                    anchors.rightMargin: 14
                                    font.family:         sfRoundedMedium.name
                                    font.pixelSize:      26
                                    color:               root.textColor
                                    renderType:          Text.NativeRendering
                                    background:          Item {}
                                    focus:               true

                                    function applyPrefix(p) {
                                        text = p
                                        cursorPosition = p.length
                                    }

                                    onTextChanged: {
                                        var t = text
                                        if (win.showingShellOutput) win.showingShellOutput = false
                                        if (t.startsWith(">")) {
                                            if (win.selectedAction !== "actions") {
                                                win.hoveredAction = ""; win.selectedAction = "actions"; win.actionsShown = false; win.currentIdx = 0
                                            }
                                            return
                                        }
                                        if (t === "") {
                                            if (win.selectedAction === "files") { win.refreshFiles(""); return }
                                            if (win.selectedAction === "applications") { return }
                                            if (win.selectedAction === "clipboard") { win.refreshClipboard(""); return }
                                            win.clickAction("")
                                            win.fileAnswers = []
                                            return
                                        }
                                        if (win.selectedAction === "" || win.selectedAction === "actions") {
                                            if (t.length > 0) win.clickAction("search")
                                        }
                                        if (win.selectedAction === "files") win.refreshFiles(t)
                                        if (win.selectedAction === "clipboard") win.refreshClipboard(t)
                                    }

                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Escape) {
                                            if (win.showingShellOutput) { win.showingShellOutput = false; event.accepted = true; return }
                                            hideAnim.start(); event.accepted = true; return
                                        }
                                        if (event.key === Qt.Key_Tab) {
                                            var t = searchField.text
                                            if (t.startsWith(">")) {
                                                var hint = root.computeTabHint(t.substring(1))
                                                if (hint !== "") searchField.applyPrefix(t + hint)
                                            } else if (win.topHitLabel !== "") {
                                                var top = win.answers[win.currentIdx] || win.answers[0]
                                                var full = top && (top.name || top.title)
                                                if (full) searchField.applyPrefix(full)
                                            }
                                            event.accepted = true; return
                                        }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_1) { searchField.text = ""; win.clickAction("applications"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_2) { searchField.text = ""; win.clickAction("files"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_3) { win.clickAction("actions"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_4) { searchField.text = ""; win.clickAction("clipboard"); event.accepted = true; return }
                                        if (event.key === Qt.Key_Down)   { win.currentIdx = Math.min(win.currentIdx+1, Math.max(0, win.answers.length - 1)); event.accepted = true; return }
                                        if (event.key === Qt.Key_Up)     { win.currentIdx = Math.max(win.currentIdx-1, 0); event.accepted = true; return }
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            var current = win.answers[win.currentIdx]
                                            if (current && current.dummy && current.targetPrefix) {
                                                searchField.applyPrefix(current.targetPrefix)
                                            } else {
                                                results.activateIndex(win.currentIdx)
                                            }
                                            event.accepted = true; return
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth:   true
                                Layout.leftMargin:  12
                                Layout.rightMargin: 12
                                height: 1; radius: 1; color: "#40555555"
                                visible: win.gridMode || win.answers.length > 0
                            }

                            Item {
                                id: resultsContainer
                                Layout.fillWidth: true
                                Layout.preferredHeight: win.showingShellOutput
                                    ? 320
                                    : win.gridMode
                                        ? 480
                                        : (win.answers.length > 0 ? Math.min(400, results.implicitHeight + 20) : 0)
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 } }
                                clip: true

                                SpotlightCategoryGrid {
                                    id: grid
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: win.gridMode && !win.showingShellOutput
                                    items:         win.selectedAction === "applications" ? win.appItems : win.fileItems
                                    categoryOrder: win.selectedAction === "applications" ? root.appCategoryOrder : root.fileCategoryOrder
                                    sectioned:     win.selectedAction === "files"
                                    mode:          win.selectedAction === "applications" ? "apps" : "files"
                                    fontFamily:       sfRounded.name
                                    fontFamilyMedium: sfRoundedMedium.name
                                    onItemClicked: function(data) { root.recordAppUsage(data); hideAnim.start() }
                                }

                                SpotlightResults {
                                    id: results
                                    anchors.fill: parent
                                    visible: !win.gridMode && !win.showingShellOutput
                                    searchText:       searchField.text
                                    answers:          win.answers
                                    fontFamily:       sfRounded.name
                                    fontFamilyMedium: sfRoundedMedium.name
                                    currentIdx:       win.currentIdx
                                    showWhenEmpty:    win.selectedAction === "clipboard"
                                    sectioned:        win.selectedAction === "search"
                                    onHoveredIdx:     function(idx) { win.currentIdx = idx }
                                    onItemClicked:    function(data) {
                                        if (data.isWallpaper) { root.setWallpaper(data.path, true) } else { root.recordAppUsage(data) }
                                        if (data.instantClose) { win.doClose() } else { hideAnim.start() }
                                    }
                                    onReindexRequested: root.startReindex()
                                    onShellCmdRequested: function(cmd) {
                                        if (/^\s*sudo\b/.test(cmd)) {
                                            root.runShellCommand(cmd)
                                            hideAnim.start()
                                        } else {
                                            win.runInlineShell(cmd)
                                        }
                                    }
                                    onTodoAddRequested: function(text) { root.addTodo(text); hideAnim.start() }
                                    onTodoItemActivated: function(id, done) {
                                        if (done) root.removeTodo(id); else root.toggleTodo(id)
                                    }
                                    onRandomWallpaperRequested: {
                                        if (root.wallpaperList.length > 0) {
                                            var pick = root.wallpaperList[Math.floor(Math.random() * root.wallpaperList.length)]
                                            root.setWallpaper(pick.path, true)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6
                                    visible: win.showingShellOutput

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: "$ " + win.shellOutputCmd
                                            color: "#ffffff"
                                            font.family: sfRoundedMedium.name
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            width: copyLabel.implicitWidth + 16
                                            height: 24
                                            radius: 12
                                            color: "#22ffffff"
                                            Text {
                                                id: copyLabel
                                                anchors.centerIn: parent
                                                text: "Copier"
                                                color: "#ffffff"
                                                opacity: 0.75
                                                font.pixelSize: 11
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Quickshell.execDetached(["bash", "-c", "printf '%s' " + results.shQuote(win.shellOutput) + " | wl-copy"])
                                            }
                                        }

                                        Rectangle {
                                            width: closeLabel.implicitWidth + 16
                                            height: 24
                                            radius: 12
                                            color: "#22ffffff"
                                            Text {
                                                id: closeLabel
                                                anchors.centerIn: parent
                                                text: "Fermer (Échap)"
                                                color: "#ffffff"
                                                opacity: 0.75
                                                font.pixelSize: 11
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.showingShellOutput = false
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 12
                                        color: "#20000000"
                                        clip: true

                                        Flickable {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            contentWidth: width
                                            contentHeight: outputText.implicitHeight
                                            boundsBehavior: Flickable.StopAtBounds
                                            clip: true

                                            Text {
                                                id: outputText
                                                width: parent.width
                                                text: win.shellOutput
                                                color: "#ffffff"
                                                font.family: "monospace"
                                                font.pixelSize: 12
                                                wrapMode: Text.Wrap
                                                textFormat: Text.PlainText
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:0;action:"applications";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/applications.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:1;action:"files";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/files.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:2;action:"actions";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/actions.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:3;iconSize:36;action:"clipboard";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/clipboard.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                }
            }
        }
    }

    component SpotlightActionBtn: Item {
        id: btn
        required property int    position
        required property string action
        required property url    iconSrc
        required property bool   actionsShown
        required property bool   isOpen
        required property color  glassColor
        required property color  textColor
        required property real   screenW
        property int iconSize: 30
        signal hovered(string action)
        signal selected(string action)
        width: 58; height: 58
        x: btn.screenW / 2 + 170 + 10 + (68 * btn.position)
        BoxGlass {
            anchors.fill:parent;radius:30;color:btn.glassColor;rimStrength:0.2
            light:"#20ffffff";lightDir:Qt.vector2d(1,1);layer.enabled:true
            scale:   btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            opacity: btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            VectorImage { anchors.centerIn:parent;width:btn.iconSize;height:btn.iconSize;source:btn.iconSrc;preferredRendererType:VectorImage.CurveRenderer;layer.enabled:true;layer.effect:MultiEffect{colorization:1;colorizationColor:btn.textColor} }
        }
        MouseArea { anchors.fill:parent;enabled:btn.actionsShown&&btn.isOpen;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onEntered:btn.hovered(btn.actionsShown&&btn.isOpen?btn.action:"");onExited:btn.hovered("");onClicked:btn.selected(btn.action) }
    }
}
