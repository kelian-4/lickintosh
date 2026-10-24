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
    readonly property int editExtraRows: 2

    property bool galleryOpen: false
    property real panelX: 0
    property real panelY: 0
    property real panelWidth: 0
    property real panelHeight: 0

    readonly property var categories: [
        { key: "connectivity", title: "Connectivity", icon: "notch/bluetooth.svg",  tint: "#0a84ff" },
        { key: "media",        title: "Media",        icon: "music/play.svg",        tint: "#ff375f" },
        { key: "display",      title: "Display",      icon: "sun-small.svg",         tint: "#ff9f0a" },
        { key: "focus",        title: "Focus",        icon: "dnd.svg",               tint: "#5e5ce6" },
        { key: "screen",       title: "Screen",       icon: "screenshot/region.svg", tint: "#30d158" },
        { key: "utilities",    title: "Utilities",    icon: "notch/clock.svg",       tint: "#64d2ff" },
        { key: "gaming",       title: "Gaming",       icon: "notch/zap.svg",         tint: "#bf5af2" }
    ]

    readonly property var controls: [
        { id: "wifiWidget",      title: "Wi-Fi",         icon: "wifi/nm-signal-100-symbolic.svg", category: "connectivity", w: 2, h: 1 },
        { id: "musicWidget",     title: "Now Playing",   icon: "music/play.svg",                  category: "media",        w: 2, h: 2 },
        { id: "btWidget",        title: "Bluetooth",     icon: "bluetooth/bluetooth.svg",         category: "connectivity", w: 1, h: 1 },
        { id: "adWidget",        title: "KDE Connect",   icon: "devices/smartphone.svg",          category: "connectivity", w: 1, h: 1 },
        { id: "focusWidget",     title: "Focus",         icon: "dnd.svg",                         category: "focus",        w: 2, h: 1 },
        { id: "stageWidget",     title: "Screenshot",    icon: "screenshot/region.svg",           category: "screen",       w: 1, h: 1 },
        { id: "shareWidget",     title: "Screen Share",  icon: "screenshare.svg",                 category: "screen",       w: 1, h: 1 },
        { id: "displayWidget",   title: "Display",       icon: "sun-small.svg",                   category: "display",      w: 4, h: 1 },
        { id: "volumeWidget",    title: "Sound",         icon: "volume/audio-volume-3.svg",       category: "media",        w: 4, h: 1 },
        { id: "darkWidget",      title: "Dark Mode",     icon: "notch/moon.svg",                  category: "display",      w: 2, h: 1 },
        { id: "calcWidget",      title: "Calculator",    icon: "calculator.svg",                  category: "utilities",    w: 1, h: 1 },
        { id: "gameModeWidget",  title: "Game Mode",     icon: "notch/zap.svg",                   category: "gaming",       w: 1, h: 1 },
        { id: "timerWidget",     title: "Timer",         icon: "notch/clock.svg",                 category: "utilities",    w: 1, h: 1 },
        { id: "alarmWidget",     title: "Alarm",         icon: "notch/bell.svg",                  category: "utilities",    w: 1, h: 1 },
        { id: "stopwatchWidget", title: "Stopwatch",     icon: "notch/watch.svg",                 category: "utilities",    w: 1, h: 1 }
    ]

    readonly property var orderedIds: {
        var saved = ShellConfig.options.controlCenter.packOrder
        var known = root.controls.map(function(c) { return c.id })
        var ids = []
        for (var i = 0; i < saved.length; i++) {
            if (known.indexOf(saved[i]) >= 0 && ids.indexOf(saved[i]) < 0) ids.push(saved[i])
        }
        for (var j = 0; j < known.length; j++) {
            if (ids.indexOf(known[j]) < 0) ids.push(known[j])
        }
        return ids
    }

    readonly property var built: root.build()
    readonly property var packedLayout: root.built.layout
    readonly property var occupied: root.built.occupied
    readonly property int lastRow: root.built.lastRow
    readonly property int shownRows: root.lastRow + 1 + (root.galleryOpen ? root.editExtraRows : 0)

    readonly property var emptySlots: {
        var slots = []
        if (!root.galleryOpen) return slots
        for (var y = 0; y < root.shownRows; y++) {
            for (var x = 0; x < root.gridW; x++) {
                if (!root.occupied[x + "," + y]) slots.push({ x: x, y: y })
            }
        }
        return slots
    }

    function build() {
        var layout = {}
        var occupied = {}
        var lastRow = 0
        for (var i = 0; i < root.orderedIds.length; i++) {
            var id = root.orderedIds[i]
            if (!ShellConfig.ccWidgetVisible(id)) continue
            var info = root.infoOf(id)
            var placed = false
            for (var y = 0; !placed; y++) {
                for (var x = 0; x + info.w <= root.gridW && !placed; x++) {
                    var free = true
                    for (var dy = 0; dy < info.h && free; dy++) {
                        for (var dx = 0; dx < info.w && free; dx++) {
                            if (occupied[(x + dx) + "," + (y + dy)]) free = false
                        }
                    }
                    if (!free) continue
                    for (var my = 0; my < info.h; my++) {
                        for (var mx = 0; mx < info.w; mx++) occupied[(x + mx) + "," + (y + my)] = true
                    }
                    layout[id] = { xPos: x, yPos: y, wUnits: info.w, hUnits: info.h }
                    lastRow = Math.max(lastRow, y + info.h - 1)
                    placed = true
                }
            }
        }
        return { layout: layout, occupied: occupied, lastRow: lastRow }
    }

    function infoOf(id) {
        for (var i = 0; i < root.controls.length; i++) {
            if (root.controls[i].id === id) return root.controls[i]
        }
        return null
    }

    function add(id) {
        if (!root.infoOf(id)) return
        ShellConfig.setCcWidgetVisible(id, true)
    }

    function remove(id) {
        if (!root.infoOf(id)) return
        ShellConfig.setCcWidgetVisible(id, false)
    }

    function dropAt(id, x, y) {
        if (!root.infoOf(id)) return
        var outside = x < root.panelX || x > root.panelX + root.panelWidth || y < root.panelY || y > root.panelY + root.panelHeight
        if (outside) return
        var cell = root.box + root.boxMargin
        var cx = Math.max(0, Math.min(root.gridW - 1, Math.floor((x - root.panelX - root.boxMargin) / cell)))
        var cy = Math.max(0, Math.floor((y - root.panelY - root.boxMargin) / cell))
        var shown = root.orderedIds.filter(function(p) { return p !== id && ShellConfig.ccWidgetVisible(p) })
        var hidden = root.orderedIds.filter(function(p) { return p !== id && !ShellConfig.ccWidgetVisible(p) })
        var index = shown.length
        for (var i = 0; i < shown.length; i++) {
            var pos = root.packedLayout[shown[i]]
            if (pos && (pos.yPos > cy || (pos.yPos === cy && pos.xPos >= cx))) {
                index = i
                break
            }
        }
        shown.splice(index, 0, id)
        ShellConfig.options.controlCenter.packOrder = shown.concat(hidden)
        ShellConfig.setCcWidgetVisible(id, true)
    }
}
