pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property int captureUsers: 0
    property bool fast: false
    property int transitionEpoch: 0
    property string lastSignature: ""

    property int captureFastInterval: 40
    property int captureIdleInterval: 200
    property real captureMargin: 200
    property real backdropScale: 0.5

    readonly property var transitionEvents: ["workspace", "workspacev2", "activespecial", "activespecialv2"]
    readonly property var geometryEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "fullscreen", "changefloatingmode", "workspace", "workspacev2", "activespecial", "activespecialv2", "pin", "minimized"]

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

    function refreshWindows() {
        Hyprland.refreshMonitors()
        Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            var n = event.name
            if (root.geometryEvents.indexOf(n) === -1)
                return
            if (root.transitionEvents.indexOf(n) !== -1)
                root.transitionEpoch++
            root.markActive()
            windowSettle.restart()
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
        interval: root.fast ? root.captureFastInterval : root.captureIdleInterval
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
}
