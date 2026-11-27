pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property int captureUsers: 0
    property bool fast: false
    property int transitionEpoch: 0
    property string closingAddress: ""
    property var closingSet: ({})
    property bool sessionLocked: false
    property bool closing: false
    readonly property bool captureBlocked: sessionLocked || unlockSettle.running

    onSessionLockedChanged: {
        if (!sessionLocked)
            unlockSettle.restart()
    }

    Timer {
        id: unlockSettle
        interval: 1500
        onTriggered: root.calmed()
    }
    property string lastSignature: ""

    signal calmed()

    function normalizeAddress(a) {
        return String(a === undefined || a === null ? "" : a).replace(/^0x/i, "").toLowerCase()
    }

    function isClosing(address) {
        var a = root.normalizeAddress(address)
        return a !== "" && root.closingSet[a] !== undefined
    }

    function markClosing(address) {
        var a = root.normalizeAddress(address)
        if (a === "")
            return
        var next = {}
        for (var k in root.closingSet)
            next[k] = root.closingSet[k]
        next[a] = Date.now()
        root.closingSet = next
        closingPrune.restart()
    }

    function unmarkClosing(address) {
        var a = root.normalizeAddress(address)
        if (a === "" || root.closingSet[a] === undefined)
            return
        var next = {}
        for (var k in root.closingSet)
            if (k !== a)
                next[k] = root.closingSet[k]
        root.closingSet = next
    }

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
            if (n === "openwindow")
                root.unmarkClosing(String(event.data).split(",")[0])
            if (n === "closewindow") {
                root.markClosing(String(event.data).split(",")[0])
                root.closingAddress = String(event.data).split(",")[0].replace(/^0x/i, "").toLowerCase()
                root.closing = true
                closingOff.restart()
            }
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
        id: closingOff
        interval: 700
        onTriggered: {
            root.closing = false
            root.closingAddress = ""
        }
    }

    Timer {
        id: closingPrune
        interval: 3000
        onTriggered: {
            var now = Date.now()
            var next = {}
            var left = 0
            for (var k in root.closingSet) {
                if (now - root.closingSet[k] < 3000) {
                    next[k] = root.closingSet[k]
                    left++
                }
            }
            root.closingSet = next
            if (left > 0)
                closingPrune.restart()
        }
    }

    Timer {
        id: fastOff
        interval: 900
        onTriggered: {
            root.fast = false
            root.calmed()
        }
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
