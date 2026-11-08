pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "nightShift"

    readonly property int minTemperature: 2500
    readonly property int maxTemperature: 6000

    property bool enabled: false
    property int temperature: 4000
    property bool available: true
    property bool restarting: false

    function toggle() {
        if (root.available) root.enabled = !root.enabled
    }

    function setTemperature(value) {
        root.temperature = Math.max(root.minTemperature, Math.min(root.maxTemperature, Math.round(value)))
    }

    function _restore() {
        if (!ShellConfig.ready) return
        root.temperature = ShellConfig.options.session.nightTemperature
        root.enabled = ShellConfig.options.session.nightShift
    }

    onEnabledChanged: {
        if (ShellConfig.ready) ShellConfig.options.session.nightShift = root.enabled
    }

    onTemperatureChanged: {
        if (ShellConfig.ready) ShellConfig.options.session.nightTemperature = root.temperature
        if (root.enabled) {
            root.restarting = true
            restartTimer.restart()
        }
    }

    Component.onCompleted: root._restore()

    Connections {
        target: ShellConfig
        function onReadyChanged() { root._restore() }
    }

    Timer {
        id: restartTimer
        interval: 350
        onTriggered: root.restarting = false
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v hyprsunset >/dev/null 2>&1"]
        running: true
        onExited: function(code) { root.available = code === 0 }
    }

    Loader {
        active: root.enabled && root.available && !root.restarting

        sourceComponent: Process {
            command: ["hyprsunset", "-t", String(root.temperature)]
            running: true
        }
    }
}
