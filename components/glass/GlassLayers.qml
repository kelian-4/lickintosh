pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var entries: []
    property int revision: 0
    property int users: 0
    property int captureUsers: 0
    property bool fast: false
    property int transitionEpoch: 0
    readonly property var transitionEvents: ["workspace", "workspacev2", "activespecial", "activespecialv2", "focusedmon", "focusedmonv2"]
    readonly property var geometryEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "fullscreen", "changefloatingmode", "workspace", "workspacev2", "activespecial", "activespecialv2", "focusedmon", "focusedmonv2", "pin", "minimized"]
    property string lastSignature: ""

    function lookup(monitor, w, h, rev) {
        if (monitor === "" || w <= 0 || h <= 0)
            return null
        var mon = null
        var ms = Hyprland.monitors.values
        for (var m = 0; m < ms.length; m++) {
            if (ms[m].name === monitor) {
                mon = ms[m]
                break
            }
        }
        var ox = mon && mon.lastIpcObject ? (mon.lastIpcObject.x ?? 0) : 0
        var oy = mon && mon.lastIpcObject ? (mon.lastIpcObject.y ?? 0) : 0
        for (var i = 0; i < root.entries.length; i++) {
            var e = root.entries[i]
            if (e.monitor === monitor && Math.abs(e.w - w) <= 1 && Math.abs(e.h - h) <= 1)
                return { x: e.x - ox, y: e.y - oy }
        }
        return null
    }

    function parse(text) {
        var data
        try {
            data = JSON.parse(text)
        } catch (err) {
            return
        }
        var list = []
        for (var mon in data) {
            var levels = data[mon].levels || {}
            for (var lv in levels) {
                var arr = levels[lv]
                for (var i = 0; i < arr.length; i++)
                    list.push({ monitor: mon, x: arr[i].x, y: arr[i].y, w: arr[i].w, h: arr[i].h, ns: arr[i].namespace })
            }
        }
        root.entries = list
        root.revision++
    }

    function signature() {
        var v = Hyprland.toplevels.values
        var parts = []
        for (var i = 0; i < v.length; i++) {
            var o = v[i].lastIpcObject
            if (!o)
                continue
            parts.push((o.address ?? "") + ":" + (o.at ? o.at.join(",") : "") + ":" + (o.size ? o.size.join(",") : "") + ":" + (o.hidden ? 1 : 0) + ":" + (o.workspace ? o.workspace.id : ""))
        }
        return parts.join("|")
    }

    function markActive() {
        root.fast = true
        fastOff.restart()
    }

    function refreshLayers() {
        if (!layersProc.running)
            layersProc.running = true
    }

    function refreshWindows() {
        Hyprland.refreshMonitors()
        Hyprland.refreshToplevels()
    }

    Process {
        id: layersProc
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            var n = event.name
            if (n === "openlayer" || n === "closelayer") {
                layerSettle.restart()
            } else if (root.geometryEvents.indexOf(n) !== -1) {
                if (root.transitionEvents.indexOf(n) !== -1)
                    root.transitionEpoch++
                root.markActive()
                windowSettle.restart()
            }
        }
    }

    Timer {
        id: layerSettle
        interval: 25
        onTriggered: {
            if (root.users > 0)
                root.refreshLayers()
        }
    }

    Timer {
        id: windowSettle
        interval: 25
        onTriggered: {
            if (root.captureUsers > 0)
                root.refreshWindows()
        }
    }

    Timer {
        id: fastOff
        interval: 1500
        onTriggered: root.fast = false
    }

    Timer {
        interval: 3000
        running: root.users > 0
        repeat: true
        onTriggered: root.refreshLayers()
    }

    Timer {
        interval: root.fast ? GlassSettings.captureFastInterval : GlassSettings.captureIdleInterval
        running: root.captureUsers > 0
        repeat: true
        onTriggered: {
            var sig = root.signature()
            if (sig !== root.lastSignature) {
                root.lastSignature = sig
                root.markActive()
            }
            root.refreshWindows()
        }
    }

    onUsersChanged: {
        if (users > 0)
            refreshLayers()
    }
}
