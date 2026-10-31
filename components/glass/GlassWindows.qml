import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property string monitorName: ""
    property rect region: Qt.rect(0, 0, 0, 0)
    property real attachMargin: GlassTracker.captureMargin
    property real windowOpacity: 1.0
    property var opacityByClass: ({})

    function opacityFor(windowClass) {
        var wanted = String(windowClass || "").toLowerCase()
        if (wanted !== "" && root.opacityByClass) {
            for (var key in root.opacityByClass) {
                if (String(key).toLowerCase() === wanted)
                    return Number(root.opacityByClass[key])
            }
        }
        return root.windowOpacity
    }

    readonly property var monitorObject: {
        var ms = Hyprland.monitors.values
        for (var i = 0; i < ms.length; i++) {
            if (ms[i].name === root.monitorName)
                return ms[i]
        }
        return null
    }
    readonly property real monitorX: monitorObject && monitorObject.lastIpcObject ? (monitorObject.lastIpcObject.x ?? 0) : 0
    readonly property real monitorY: monitorObject && monitorObject.lastIpcObject ? (monitorObject.lastIpcObject.y ?? 0) : 0

    property int pending: 0
    property bool graceDone: false
    property bool timedOut: false
    property bool latched: false

    function recount() {
        var n = 0
        for (var i = 0; i < windowsRepeater.count; i++) {
            var it = windowsRepeater.itemAt(i)
            if (it && it.pending)
                n++
        }
        root.pending = n
        root.check()
    }

    function check() {
        if (!root.latched && root.graceDone && (root.pending === 0 || root.timedOut))
            root.latched = true
    }

    function restartGate(grace) {
        root.latched = false
        root.graceDone = false
        root.timedOut = false
        graceTimer.interval = grace
        graceTimer.restart()
        timeoutTimer.restart()
        root.recount()
    }

    Timer {
        id: graceTimer
        interval: 60
        running: true
        onTriggered: {
            root.graceDone = true
            root.check()
        }
    }

    Timer {
        id: timeoutTimer
        interval: 2000
        running: true
        onTriggered: {
            root.timedOut = true
            root.check()
        }
    }

    Connections {
        target: GlassTracker

        function onTransitionEpochChanged() {
            root.restartGate(180)
        }
    }

    Component.onCompleted: GlassTracker.captureUsers++
    Component.onDestruction: GlassTracker.captureUsers--

    Repeater {
        id: windowsRepeater
        model: Hyprland.toplevels
        onItemAdded: root.recount()
        onItemRemoved: root.recount()

        ScreencopyView {
            id: view

            required property var modelData

            readonly property var ipc: modelData.lastIpcObject
            readonly property bool onScreen: ipc !== undefined && ipc !== null
                && modelData.wayland !== null
                && modelData.monitor !== null
                && modelData.monitor.name === root.monitorName
                && modelData.workspace !== null
                && modelData.workspace.active
                && ipc.hidden !== true
                && ipc.mapped !== false
                && ipc.at !== undefined && ipc.size !== undefined
            readonly property bool shown: onScreen && !GlassTracker.captureBlocked
                && root.region.width > 0 && root.region.height > 0
                && (ipc.at[0] - root.monitorX) < (root.region.x + root.region.width + root.attachMargin)
                && (ipc.at[0] - root.monitorX + ipc.size[0]) > (root.region.x - root.attachMargin)
                && (ipc.at[1] - root.monitorY) < (root.region.y + root.region.height + root.attachMargin)
                && (ipc.at[1] - root.monitorY + ipc.size[1]) > (root.region.y - root.attachMargin)
            readonly property bool inRegion: shown
                && (ipc.at[0] - root.monitorX) < (root.region.x + root.region.width)
                && (ipc.at[0] - root.monitorX + ipc.size[0]) > root.region.x
                && (ipc.at[1] - root.monitorY) < (root.region.y + root.region.height)
                && (ipc.at[1] - root.monitorY + ipc.size[1]) > root.region.y
            readonly property real rank: ipc && ipc.focusHistoryID !== undefined ? ipc.focusHistoryID : 0

            readonly property real captureOpacity: root.opacityFor(ipc ? ipc["class"] : "")
            readonly property bool translucent: captureOpacity > 0 && captureOpacity < 1
            readonly property bool pending: inRegion && captureOpacity > 0 && !hasContent
            onPendingChanged: root.recount()

            property bool restarting: false

            function restart() {
                restarting = true
                restartTimer.start()
            }

            Timer {
                id: restartTimer
                interval: 80
                onTriggered: view.restarting = false
            }

            Timer {
                interval: 8000
                running: view.shown && !view.hasContent
                repeat: true
                onTriggered: view.restart()
            }

            captureSource: shown && !restarting && captureOpacity > 0 ? modelData.wayland : null
            live: true
            visible: shown
            opacity: hasContent ? (translucent ? 1 : Math.min(1, captureOpacity)) : 0
            layer.enabled: translucent
            layer.effect: ShaderEffect {
                property real bgAlpha: view.captureOpacity
                property real lumaLow: 0.12
                property real lumaHigh: 0.45

                vertexShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/WindowAlpha.vert.qsb")
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/WindowAlpha.frag.qsb")
            }
            x: ipc && ipc.at ? ipc.at[0] - root.monitorX : 0
            y: ipc && ipc.at ? ipc.at[1] - root.monitorY : 0
            width: ipc && ipc.size ? ipc.size[0] : 0
            height: ipc && ipc.size ? ipc.size[1] : 0
            z: (ipc && ipc.floating ? 1000 : 0) - rank
        }
    }
}
