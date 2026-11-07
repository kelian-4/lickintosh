pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "shellConfig"

    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.config/lickintosh/core"]
    }

    readonly property string filePath: Quickshell.env("HOME") + "/.config/lickintosh/shell-config.json"
    property alias options: configAdapter

    readonly property string defaultWallpaper: Quickshell.shellDir + "/assets/wallpapers/WWDC25 macOS Tahoe city orange.jpeg"

    function seedWallpaper() {
        if (configAdapter.wallpaper.path === "") {
            configAdapter.wallpaper.path = root.defaultWallpaper
        }
    }
    property bool ready: false

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.ready = true
            root.seedWallpaper()
            root.seedKeepAwake()
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                root.seedWallpaper()
                writeAdapter()
            }
        }

        JsonAdapter {
            id: configAdapter

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
                property string powerProfile: ""
            }

            property JsonObject topbar: JsonObject {
                property bool notchVisible:      true
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
                property real iconScale:         1.15
                property int  iconOverflow:      4
                property real magnification:     1.50
                property bool magnificationEnabled: true
            }

            property JsonObject general: JsonObject {
                property string language: "auto"
            }

            property JsonObject menuBar: JsonObject {
                property bool autoHide: false
            }

            property JsonObject appearance: JsonObject {
                property string accentColor:  "#1C7AFF"
                property real   panelOpacity: 0.85
                property bool   reduceMotion: false
                property string mode:         "glass"
                property string blurPreset:   ""
                property real   blurWindowOpacity: 0.80
                property real   blurWindowOpacityInactive: 0.80
                property var    blurParams:   ({})
                property var    glassElements: ({})
                property bool   blurLayers:   true
                property bool   blurLayerPopups: true
                property real   layerIgnoreAlpha: 0.05
                property real   blurSurfaceAlpha: 0.30
                property real   glassTintLight: 0.45
                property real   glassTintDark: 0.40
                property string accentOverride: ""
                property bool   blurApplied:  false
                property string blurStatus:   ""
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
                    property bool webSearch:    true
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
                property string path: ""

                property string lockscreenPath: ""
            }

            property JsonObject glass: JsonObject {
                property bool captureWindows: false
                property int captureIntervalMs: 400
                property real windowOpacity: 1.0
                property var windowOpacityByClass: ({ "kitty": 0.3 })
            }

            property JsonObject lockscreen: JsonObject {
                property int    clockStyle:  0

                property real   clockWeight: 1.0
                property bool   clockLarge:  true

                property bool   showNotifications:         true
                property bool   showNotificationPreviews:  true
                property bool   showMediaPlayer:            true
                property bool   showControlCenter:          true
                property bool   lockAtStartup:              false
            }

            property JsonObject controlCenter: JsonObject {
                property bool keepAwakeSeeded: false
                property list<var> items: [
                    { "uid": "wifiWidget", "type": "wifiWidget" },
                    { "uid": "btWidget", "type": "btWidget" },
                    { "uid": "adWidget", "type": "adWidget" },
                    { "uid": "musicWidget", "type": "musicWidget" },
                    { "uid": "focusWidget", "type": "focusWidget" },
                    { "uid": "stageWidget", "type": "stageWidget" },
                    { "uid": "shareWidget", "type": "shareWidget" },
                    { "uid": "darkWidget", "type": "darkWidget" },
                    { "uid": "calcWidget", "type": "calcWidget" },
                    { "uid": "gameModeWidget", "type": "gameModeWidget" },
                    { "uid": "displayWidget", "type": "displayWidget" },
                    { "uid": "volumeWidget", "type": "volumeWidget" }
                ]
            }
        }
    }

    readonly property var pinnedApps:  options.dock.pinnedApps
    readonly property var pinnedFiles: options.dock.pinnedFiles

    function ccWidgetVisible(type) {
        var list = root.options.controlCenter.items
        for (var i = 0; i < list.length; i++) {
            if (list[i].type === type) return true
        }
        return false
    }

    function seedKeepAwake() {
        if (root.options.controlCenter.keepAwakeSeeded) return
        root.setCcWidgetVisible("keepAwakeWidget", true)
        root.options.controlCenter.keepAwakeSeeded = true
    }

    function setCcWidgetVisible(type, visible) {
        var list = root.options.controlCenter.items.slice()
        if (visible) {
            if (root.ccWidgetVisible(type)) return
            list.push({ uid: type + "_" + Date.now(), type: type })
        } else {
            list = list.filter(function(item) { return item.type !== type })
        }
        root.options.controlCenter.items = list
    }

    readonly property string powerProfile: options.battery.powerProfile

    function setPowerProfile(profileId) {
        root.options.battery.powerProfile = profileId
        _setProfileProc.command = ["powerprofilesctl", "set", profileId]
        _setProfileProc.running = true
    }

    Process {
        id: _setProfileProc
    }

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
                                    icon:  IconResolver.byName(key)
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
