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
            settle.restart()
        }
    }

    Timer {
        id: settle
        interval: 60
        onTriggered: {
            if (root.users > 0)
                root.refreshLayers()
            if (root.captureUsers > 0)
                root.refreshWindows()
        }
    }

    Timer {
        interval: 3000
        running: root.users > 0
        repeat: true
        onTriggered: root.refreshLayers()
    }

    Timer {
        interval: 500
        running: root.captureUsers > 0
        repeat: true
        onTriggered: root.refreshWindows()
    }

    onUsersChanged: {
        if (users > 0)
            settle.restart()
    }
}
