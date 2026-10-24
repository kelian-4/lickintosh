pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "controlCatalog"

    readonly property int box: 65
    readonly property int boxMargin: 10
    readonly property int gridW: 4
    readonly property int packStartRow: 5

    property bool galleryOpen: false
    property real panelX: 0
    property real panelY: 0
    property real panelWidth: 0
    property real panelHeight: 0

    readonly property var categories: [
        { key: "connectivity", title: "Connectivity", icon: "notch/bluetooth.svg", tint: "#0a84ff" },
        { key: "media",        title: "Media",        icon: "music/play.svg",       tint: "#ff375f" },
        { key: "display",      title: "Display",      icon: "sun-small.svg",        tint: "#ff9f0a" },
        { key: "focus",        title: "Focus",        icon: "dnd.svg",              tint: "#5e5ce6" },
        { key: "screen",       title: "Screen",       icon: "screenshot/region.svg", tint: "#30d158" },
        { key: "utilities",    title: "Utilities",    icon: "notch/clock.svg",      tint: "#64d2ff" },
        { key: "gaming",       title: "Gaming",       icon: "notch/zap.svg",        tint: "#bf5af2" }
    ]

    readonly property var controls: [
        { id: "wifiWidget",      title: "Wi-Fi",         icon: "wifi/nm-signal-100-symbolic.svg", category: "connectivity", locked: true,  w: 1, h: 1 },
        { id: "btWidget",        title: "Bluetooth",     icon: "bluetooth/bluetooth.svg",         category: "connectivity", locked: true,  w: 1, h: 1 },
        { id: "adWidget",        title: "KDE Connect",   icon: "devices/smartphone.svg",          category: "connectivity", locked: true,  w: 1, h: 1 },
        { id: "musicWidget",     title: "Now Playing",   icon: "music/play.svg",                  category: "media",        locked: true,  w: 1, h: 1 },
        { id: "volumeWidget",    title: "Volume",        icon: "volume/audio-volume-3.svg",       category: "media",        locked: true,  w: 1, h: 1 },
        { id: "displayWidget",   title: "Brightness",    icon: "sun-small.svg",                   category: "display",      locked: true,  w: 1, h: 1 },
        { id: "darkWidget",      title: "Dark Mode",     icon: "notch/moon.svg",                  category: "display",      locked: false, w: 2, h: 1 },
        { id: "focusWidget",     title: "Focus",         icon: "dnd.svg",                         category: "focus",        locked: true,  w: 1, h: 1 },
        { id: "stageWidget",     title: "Screenshot",    icon: "screenshot/region.svg",           category: "screen",       locked: true,  w: 1, h: 1 },
        { id: "shareWidget",     title: "Screen Share",  icon: "screenshare.svg",                 category: "screen",       locked: true,  w: 1, h: 1 },
        { id: "calcWidget",      title: "Calculator",    icon: "calculator.svg",                  category: "utilities",    locked: false, w: 1, h: 1 },
        { id: "timerWidget",     title: "Timer",         icon: "notch/clock.svg",                 category: "utilities",    locked: false, w: 1, h: 1 },
        { id: "alarmWidget",     title: "Alarm",         icon: "notch/bell.svg",                  category: "utilities",    locked: false, w: 1, h: 1 },
        { id: "stopwatchWidget", title: "Stopwatch",     icon: "notch/watch.svg",                 category: "utilities",    locked: false, w: 1, h: 1 },
        { id: "gameModeWidget",  title: "Game Mode",     icon: "notch/zap.svg",                   category: "gaming",       locked: false, w: 1, h: 1 }
    ]

    readonly property var defaultOrder: ["darkWidget", "calcWidget", "gameModeWidget", "timerWidget", "alarmWidget", "stopwatchWidget"]

    readonly property var orderedPackable: {
        var saved = ShellConfig.options.controlCenter.packOrder
        var ids = []
        for (var i = 0; i < saved.length; i++) {
            if (root.defaultOrder.indexOf(saved[i]) >= 0 && ids.indexOf(saved[i]) < 0) ids.push(saved[i])
        }
        for (var j = 0; j < root.defaultOrder.length; j++) {
            if (ids.indexOf(root.defaultOrder[j]) < 0) ids.push(root.defaultOrder[j])
        }
        return ids
    }

    readonly property var packedLayout: {
        var layout = {}
        var cursorX = 0
        var cursorY = root.packStartRow
        for (var i = 0; i < root.orderedPackable.length; i++) {
            var id = root.orderedPackable[i]
            if (!ShellConfig.ccWidgetVisible(id)) continue
            var info = root.infoOf(id)
            if (cursorX + info.w > root.gridW) {
                cursorX = 0
                cursorY++
            }
            layout[id] = { xPos: cursorX, yPos: cursorY, wUnits: info.w, hUnits: info.h }
            cursorX += info.w
        }
        return layout
    }

    function infoOf(id) {
        for (var i = 0; i < root.controls.length; i++) {
            if (root.controls[i].id === id) return root.controls[i]
        }
        return null
    }

    function toggle(id) {
        var info = root.infoOf(id)
        if (!info || info.locked) return
        ShellConfig.setCcWidgetVisible(id, !ShellConfig.ccWidgetVisible(id))
    }

    function dropAt(id, x, y) {
        var info = root.infoOf(id)
        if (!info || info.locked) return
        var outside = x < root.panelX || x > root.panelX + root.panelWidth || y < root.panelY || y > root.panelY + root.panelHeight
        if (outside) return
        var cell = root.box + root.boxMargin
        var cx = Math.max(0, Math.floor((x - root.panelX - root.boxMargin) / cell))
        var cy = Math.floor((y - root.panelY - root.boxMargin) / cell)
        var shown = root.orderedPackable.filter(function(p) { return p !== id && ShellConfig.ccWidgetVisible(p) })
        var hidden = root.orderedPackable.filter(function(p) { return p !== id && !ShellConfig.ccWidgetVisible(p) })
        var index = 0
        for (var i = 0; i < shown.length; i++) {
            var pos = root.packedLayout[shown[i]]
            if (pos && (pos.yPos < cy || (pos.yPos === cy && pos.xPos < cx))) index = i + 1
        }
        shown.splice(index, 0, id)
        ShellConfig.options.controlCenter.packOrder = shown.concat(hidden)
        ShellConfig.setCcWidgetVisible(id, true)
    }
}
