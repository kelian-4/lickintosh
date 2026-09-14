pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
    Configuration et état persistant unifiés pour tout le shell.

    Contient :
      - Etat runtime persistant (dock, profil batterie) : anciennement ShellState.
      - Réglages visuels utilisateur pilotés par l'app Settings (topbar, dock, etc.)

    Ne contient PAS de logique système : NetworkManager, BluetoothState, etc.
    restent des singletons séparés en lecture/écriture directe sur le système
    (nmcli, bluez...), jamais gérés depuis ce fichier.

    Persistance : un seul fichier JSON, via FileView + JsonAdapter (mécanisme
    natif Quickshell). watchChanges: true assure la synchronisation
    bidirectionnelle automatique :
      - Un changement fait depuis l'app Settings (ou par un composant du
        shell) écrit le fichier -> tous les autres composants qui lisent
        ShellConfig.options.xxx se mettent à jour immédiatement (binding).
      - Un changement fait manuellement dans le fichier JSON est détecté
        (watchChanges) et rechargé -> les composants du shell reflètent le
        changement sans redémarrage.

    Usage:
        import qs.services
        ShellConfig.options.dock.pinnedApps
        ShellConfig.options.topbar.clockVisible = false
*/
Singleton {
    id: root

    reloadableId: "shellConfig"

    readonly property string filePath: "$HOME/.config/quickshell/core/shell-config.json"
    property alias options: configAdapter
    property bool ready: false

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                writeAdapter()
            }
        }

        JsonAdapter {
            id: configAdapter

            // ---------------------------------------------------------
            // Etat runtime persistant (anciennement ShellState)
            // ---------------------------------------------------------
            property JsonObject dock: JsonObject {
                property list<var> pinnedApps: [
                    { "name": "Finder",   "cmd": "dolphin", "icon": "system-file-manager", "iconPath": "", "autostart": false },
                    { "name": "Terminal", "cmd": "kitty",   "icon": "kitty",               "iconPath": "", "autostart": false },
                    { "name": "Browser",  "cmd": "brave",   "icon": "brave-browser",       "iconPath": "", "autostart": false },
                    { "name": "Settings", "cmd": "",        "icon": "preferences-system",  "iconPath": "", "autostart": false }
                ]
                property list<var> pinnedFiles: []
            }

            property JsonObject battery: JsonObject {
                // "" tant que non chargé/connu, sinon "balanced" | "power-saver" | "performance"
                property string powerProfile: ""
            }

            // ---------------------------------------------------------
            // Réglages visuels utilisateur (pilotés par l'app Settings)
            // Purement visuel : aucune de ces valeurs ne pilote de logique
            // système, seulement l'apparence des composants du shell.
            // ---------------------------------------------------------
            property JsonObject topbar: JsonObject {
                property bool clockVisible:      true
                property bool clockTextVisible:  true
                property bool clockBadgeVisible: true

                property bool batteryVisible:      true
                property bool batteryTextVisible:  true
                property bool batteryIconVisible:  true

                property bool showBluetooth:  true
                property bool showWifi:       true
                property bool showSystemTray: true
                property bool showControlCenter: true
                property bool showAI:            true
                property bool showSpotlight:     true
                property string clockFormat:  "ddd d MMM HH:mm"
                property int    barHeight:    30
            }

            property JsonObject dockAppearance: JsonObject {
                property bool enable:            true
                property real height:            60
                property bool hoverToReveal:     true
                property bool monochromeIcons:   true
                property int  iconSize:          54
                property real magnification:     1.50
                property bool magnificationEnabled: true
            }

            property JsonObject menuBar: JsonObject {
                property bool autoHide: false
            }

            property JsonObject appearance: JsonObject {
                property string accentColor:  "#1C7AFF"
                property real   panelOpacity: 0.85
                property bool   reduceMotion: false
            }

            property JsonObject spotlight: JsonObject {
                property string hotkey: "Super"

                property JsonObject aliases: JsonObject {
                    property string calc:     "="
                    property string search:   "?"
                    property string wall:     "~"
                    property string emoji:    ":"
                    property string sh:       "$"
                    property string todo:     "+"
                }

                property JsonObject sources: JsonObject {
                    property bool applications: true
                    property bool files:        true
                    property bool actions:      true
                    property bool calculator:   true
                }

                property JsonObject clipboard: JsonObject {
                    property bool enableText:  true
                    property bool enableImage: true
                    property int  maxEntries:  60
                }

                property JsonObject indexing: JsonObject {
                    property string wallpaperDir:       "~/Pictures/wallpaper"
                    property list<string> excludePaths: ["node_modules", "target", "dist", "build", "vendor", "venv", "__pycache__"]
                    property int fullReindexHours:       24
                    property int incrementalMinutes:     5
                }

                property list<string> disabledActions: []
            }

            property JsonObject notifications: JsonObject {
                property bool enable:      true
                property int  timeoutSecs: 5
            }

            property JsonObject sound: JsonObject {
                property bool  showOsd:    true
                property real  osdTimeout: 1.5
            }

            property JsonObject wallpaper: JsonObject {
                // Wallpaper du bureau normal. Historiquement stocké à
                // part par SpotlightWindow.qml dans un cache base64
                // (~/.cache/quickshell/spotlight_wallpaper) : migré ici
                // pour que ce soit ShellConfig la seule source de vérité
                // persistée, cohérent avec le reste du shell.
                property string path: ""
                // Wallpaper spécifique au lockscreen — volontairement
                // une image distincte de celle du bureau, pas un simple
                // alias vers "path" ci-dessus.
                property string lockscreenPath: ""
            }

            property JsonObject controlCenter: JsonObject {
                property list<var> widgetVisibility: [
                    { "id": "wifiWidget",     "visible": true },
                    { "id": "btWidget",       "visible": true },
                    { "id": "adWidget",       "visible": true },
                    { "id": "musicWidget",    "visible": true },
                    { "id": "focusWidget",    "visible": true },
                    { "id": "stageWidget",    "visible": true },
                    { "id": "shareWidget",    "visible": true },
                    { "id": "darkWidget",     "visible": true },
                    { "id": "calcWidget",     "visible": true },
                    { "id": "gameModeWidget", "visible": true },
                    { "id": "displayWidget",  "visible": true },
                    { "id": "volumeWidget",   "visible": true },
                    { "id": "timerWidget",    "visible": false },
                    { "id": "alarmWidget",    "visible": false },
                    { "id": "stopwatchWidget","visible": false }
                ]
            }
        }
    }

    // ---------------------------------------------------------------
    // Dock : fonctions de compatibilité avec l'ancien ShellState
    // ---------------------------------------------------------------
    readonly property var pinnedApps:  options.dock.pinnedApps
    readonly property var pinnedFiles: options.dock.pinnedFiles

    function ccWidgetVisible(id) {
        var list = root.options.controlCenter.widgetVisibility
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i].visible
        }
        return false
    }

    function setCcWidgetVisible(id, visible) {
        var list = root.options.controlCenter.widgetVisibility.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = { id: id, visible: visible }
                root.options.controlCenter.widgetVisibility = list
                return
            }
        }
        list.push({ id: id, visible: visible })
        root.options.controlCenter.widgetVisibility = list
    }

    // ---------------------------------------------------------------
    // Batterie / profil d'alimentation
    // ---------------------------------------------------------------
    readonly property string powerProfile: options.battery.powerProfile

    function setPowerProfile(profileId) {
        root.options.battery.powerProfile = profileId
        _setProfileProc.command = ["powerprofilesctl", "set", profileId]
        _setProfileProc.running = true
    }

    Process {
        id: _setProfileProc
    }

    // Resynchronise une fois au démarrage avec l'état système réel
    // (le profil peut avoir été changé ailleurs que par le shell).
    Process {
        id: _getProfileProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: function(data) {
                var val = data.trim()
                if (val.length > 0 && val !== root.options.battery.powerProfile) {
                    root.options.battery.powerProfile = val
                }
            }
        }
    }

    // -----------------------------------------------------------------
    // Energy usage monitoring (top consommateurs CPU/RAM/Swap)
    // Etat volatil, recalculé en continu, jamais persisté dans le JSON.
    // Tourne dès le démarrage du shell, indépendamment de l'ouverture du
    // panneau batterie.
    // -----------------------------------------------------------------
    property var previousSample: ({})
    property double previousTimestamp: 0
    property double memTotalKb: 1
    property var topConsumers: []
    readonly property bool hasCollectedOnce: root.previousTimestamp > 0

    function formatMemory(mb) {
        if (mb >= 1024) return (mb / 1024).toFixed(1) + " GB"
        return Math.round(mb) + " MB"
    }

    Process {
        id: _memTotalProc
        command: ["bash", "-c", "awk '/^MemTotal:/{print $2}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: function(data) {
                var v = parseFloat(data.trim())
                if (v > 0) root.memTotalKb = v
            }
        }
    }

    Process {
        id: _sampleProc
        command: ["bash", Quickshell.shellDir + "/tools/energy-usage/sample-processes.sh"]
        property var pending: ({})
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split(";")
                if (parts.length === 4) {
                    _sampleProc.pending[parts[0]] = {
                        cpu:  parseFloat(parts[1]),
                        rss:  parseFloat(parts[2]),
                        swap: parseFloat(parts[3])
                    }
                }
            }
        }
        onExited: function() {
            var now = Date.now()
            var current = _sampleProc.pending
            _sampleProc.pending = ({})

            if (root.previousTimestamp > 0) {
                var elapsedSec = (now - root.previousTimestamp) / 1000
                if (elapsedSec > 0.2) {
                    var results = []
                    for (var key in current) {
                        var prev = root.previousSample[key]
                        if (prev) {
                            var deltaTicks = current[key].cpu - prev.cpu
                            if (deltaTicks < 0) deltaTicks = 0
                            var cpuPct = (deltaTicks / 100) / elapsedSec * 100
                            var rssMb  = current[key].rss / 1024
                            var swapMb = current[key].swap / 1024
                            if (cpuPct > 0.3 || rssMb > 50) {
                                results.push({
                                    name:  key,
                                    cpu:   cpuPct,
                                    rssMb: rssMb,
                                    swap:  swapMb,
                                    icon:  Quickshell.iconPath(key, true)
                                })
                            }
                        }
                    }
                    results.sort(function(a, b) { return b.rssMb - a.rssMb })
                    root.topConsumers = results.slice(0, 3)
                }
            }

            root.previousSample   = current
            root.previousTimestamp = now
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!_sampleProc.running) _sampleProc.running = true
        }
    }

    Component.onCompleted: {
        _memTotalProc.running = true
        _sampleProc.running   = true
        _getProfileProc.running = true
    }
}
