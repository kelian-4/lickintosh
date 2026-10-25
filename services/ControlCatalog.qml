pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "controlCatalog"

    readonly property int box: 65
    readonly property int boxMargin: 10
    readonly property int cell: root.box + root.boxMargin
    readonly property int gridW: 4
    readonly property int editExtraRows: 2
    readonly property int maxRows: 16

    property bool galleryOpen: false
    property var preview: null

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
        { id: "wifiWidget",      title: "Wi-Fi",         icon: "wifi/nm-signal-100-symbolic.svg", category: "connectivity", w: 2, h: 1, subtitle: "Network" },
        { id: "musicWidget",     title: "Now Playing",   icon: "music/play.svg",                  category: "media",        w: 2, h: 2, subtitle: "Not Playing" },
        { id: "btWidget",        title: "Bluetooth",     icon: "bluetooth/bluetooth.svg",         category: "connectivity", w: 1, h: 1, subtitle: "" },
        { id: "adWidget",        title: "KDE Connect",   icon: "devices/smartphone.svg",          category: "connectivity", w: 1, h: 1, subtitle: "" },
        { id: "focusWidget",     title: "Focus",         icon: "dnd.svg",                         category: "focus",        w: 2, h: 1, subtitle: "Off" },
        { id: "stageWidget",     title: "Screenshot",    icon: "screenshot/region.svg",           category: "screen",       w: 1, h: 1, subtitle: "" },
        { id: "shareWidget",     title: "Screen Share",  icon: "screenshare.svg",                 category: "screen",       w: 1, h: 1, subtitle: "" },
        { id: "displayWidget",   title: "Display",       icon: "sun-small.svg",                   category: "display",      w: 4, h: 1, subtitle: "" },
        { id: "volumeWidget",    title: "Sound",         icon: "volume/audio-volume-3.svg",       category: "media",        w: 4, h: 1, subtitle: "" },
        { id: "darkWidget",      title: "Dark Mode",     icon: "notch/moon.svg",                  category: "display",      w: 2, h: 1, subtitle: "On" },
        { id: "calcWidget",      title: "Calculator",    icon: "calculator.svg",                  category: "utilities",    w: 1, h: 1, subtitle: "" },
        { id: "gameModeWidget",  title: "Game Mode",     icon: "notch/zap.svg",                   category: "gaming",       w: 1, h: 1, subtitle: "" },
        { id: "timerWidget",     title: "Timer",         icon: "notch/clock.svg",                 category: "utilities",    w: 1, h: 1, subtitle: "" },
        { id: "alarmWidget",     title: "Alarm",         icon: "notch/bell.svg",                  category: "utilities",    w: 1, h: 1, subtitle: "" },
        { id: "stopwatchWidget", title: "Stopwatch",     icon: "notch/watch.svg",                 category: "utilities",    w: 1, h: 1, subtitle: "" }
    ]

    readonly property var built: root.build(root.savedPositions(), "")
    readonly property var packedLayout: root.built.layout
    readonly property var occupied: root.built.occupied
    readonly property int lastRow: root.built.lastRow
    readonly property int shownRows: root.lastRow + 1 + (root.galleryOpen ? root.editExtraRows : 0)

    function savedPositions() {
        var out = {}
        var list = ShellConfig.options.controlCenter.positions
        for (var i = 0; i < list.length; i++) out[list[i].id] = { x: list[i].x, y: list[i].y }
        return out
    }

    function currentSaved() {
        var out = {}
        var layout = root.packedLayout
        for (var id in layout) out[id] = { x: layout[id].xPos, y: layout[id].yPos }
        return out
    }

    function key(x, y) {
        return x + "," + y
    }

    function isFree(occupied, x, y, w, h) {
        if (x < 0 || y < 0 || x + w > root.gridW || y + h > root.maxRows) return false
        for (var dy = 0; dy < h; dy++) {
            for (var dx = 0; dx < w; dx++) {
                if (occupied[root.key(x + dx, y + dy)]) return false
            }
        }
        return true
    }

    function mark(occupied, x, y, w, h) {
        for (var dy = 0; dy < h; dy++) {
            for (var dx = 0; dx < w; dx++) occupied[root.key(x + dx, y + dy)] = true
        }
    }

    function build(saved, skipId) {
        var layout = {}
        var occupied = {}
        var lastRow = 0
        var pending = []
        for (var i = 0; i < root.controls.length; i++) {
            var info = root.controls[i]
            if (info.id === skipId || !ShellConfig.ccWidgetVisible(info.id)) continue
            var pos = saved[info.id]
            if (pos && root.isFree(occupied, pos.x, pos.y, info.w, info.h)) {
                root.mark(occupied, pos.x, pos.y, info.w, info.h)
                layout[info.id] = { xPos: pos.x, yPos: pos.y, wUnits: info.w, hUnits: info.h }
                lastRow = Math.max(lastRow, pos.y + info.h - 1)
            } else {
                pending.push(info)
            }
        }
        for (var j = 0; j < pending.length; j++) {
            var item = pending[j]
            var placed = false
            for (var y = 0; y < root.maxRows && !placed; y++) {
                for (var x = 0; x + item.w <= root.gridW && !placed; x++) {
                    if (!root.isFree(occupied, x, y, item.w, item.h)) continue
                    root.mark(occupied, x, y, item.w, item.h)
                    layout[item.id] = { xPos: x, yPos: y, wUnits: item.w, hUnits: item.h }
                    lastRow = Math.max(lastRow, y + item.h - 1)
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

    function nearestIn(occupied, w, h, fx, fy) {
        var best = null
        var bestDist = 1e9
        for (var y = 0; y + h <= root.maxRows; y++) {
            for (var x = 0; x + w <= root.gridW; x++) {
                if (!root.isFree(occupied, x, y, w, h)) continue
                var d = (x - fx) * (x - fx) + (y - fy) * (y - fy)
                if (d < bestDist) {
                    bestDist = d
                    best = { x: x, y: y }
                }
            }
        }
        return best
    }

    function resolve(id, fx, fy) {
        var info = root.infoOf(id)
        if (!info) return null
        var rest = root.build(root.currentSaved(), id)
        var rows = Math.max(info.h, Math.min(root.maxRows, rest.lastRow + 1 + root.editExtraRows))
        var x = Math.max(0, Math.min(root.gridW - info.w, Math.round(fx)))
        var y = Math.max(0, Math.min(rows - info.h, Math.round(fy)))
        var colliders = []
        var occupied = {}
        for (var i = 0; i < root.controls.length; i++) {
            var cid = root.controls[i].id
            var pos = rest.layout[cid]
            if (!pos) continue
            var hit = x < pos.xPos + pos.wUnits && x + info.w > pos.xPos && y < pos.yPos + pos.hUnits && y + info.h > pos.yPos
            if (hit) colliders.push(cid)
            else root.mark(occupied, pos.xPos, pos.yPos, pos.wUnits, pos.hUnits)
        }
        root.mark(occupied, x, y, info.w, info.h)
        var old = root.packedLayout[id]
        var moves = {}
        for (var j = 0; j < colliders.length; j++) {
            var ci = root.infoOf(colliders[j])
            var orig = rest.layout[colliders[j]]
            var spot = null
            if (colliders.length === 1 && old && root.isFree(occupied, old.xPos, old.yPos, ci.w, ci.h)) spot = { x: old.xPos, y: old.yPos }
            else spot = root.nearestIn(occupied, ci.w, ci.h, orig.xPos, orig.yPos)
            if (!spot) return null
            root.mark(occupied, spot.x, spot.y, ci.w, ci.h)
            moves[colliders[j]] = spot
        }
        return { id: id, x: x, y: y, moves: moves }
    }

    function setPreview(id, fx, fy) {
        root.preview = root.resolve(id, fx, fy)
    }

    function clearPreview() {
        root.preview = null
    }

    function commitPreview() {
        var p = root.preview
        root.preview = null
        if (!p) return false
        root.place(p.id, p.x, p.y, p.moves)
        return true
    }

    function place(id, x, y, moves) {
        if (!root.infoOf(id)) return
        var layout = root.packedLayout
        var list = []
        for (var i = 0; i < root.controls.length; i++) {
            var cid = root.controls[i].id
            if (cid === id) continue
            if (moves && moves[cid]) list.push({ id: cid, x: moves[cid].x, y: moves[cid].y })
            else if (layout[cid]) list.push({ id: cid, x: layout[cid].xPos, y: layout[cid].yPos })
        }
        list.push({ id: id, x: x, y: y })
        ShellConfig.options.controlCenter.positions = list
        ShellConfig.setCcWidgetVisible(id, true)
    }

    function add(id) {
        if (!root.infoOf(id)) return
        ShellConfig.setCcWidgetVisible(id, true)
    }

    function remove(id) {
        if (!root.infoOf(id)) return
        var layout = root.packedLayout
        var list = []
        for (var i = 0; i < root.controls.length; i++) {
            var cid = root.controls[i].id
            if (cid !== id && layout[cid]) list.push({ id: cid, x: layout[cid].xPos, y: layout[cid].yPos })
        }
        ShellConfig.options.controlCenter.positions = list
        ShellConfig.setCcWidgetVisible(id, false)
    }
}
