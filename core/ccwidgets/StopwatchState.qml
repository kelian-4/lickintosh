pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "stopwatchState"

    property bool running: false
    property double startedAtMs: 0
    property double accumulatedMs: 0

    property int _tick: 0

    readonly property double elapsedMs: {
        root._tick
        return root.running ? (root.accumulatedMs + (Date.now() - root.startedAtMs)) : root.accumulatedMs
    }

    function start() {
        if (root.running) return
        root.startedAtMs = Date.now()
        root.running = true
    }

    function stop() {
        if (!root.running) return
        root.accumulatedMs += Date.now() - root.startedAtMs
        root.running = false
    }

    function toggle() {
        if (root.running) root.stop()
        else root.start()
    }

    function reset() {
        root.running = false
        root.accumulatedMs = 0
        root.startedAtMs = 0
    }

    function formatElapsed(ms) {
        var totalCentis = Math.floor(ms / 10)
        var centis = totalCentis % 100
        var totalSecs = Math.floor(totalCentis / 100)
        var secs = totalSecs % 60
        var totalMins = Math.floor(totalSecs / 60)
        var mins = totalMins % 60
        var hours = Math.floor(totalMins / 60)

        function pad(n) { return n < 10 ? "0" + n : "" + n }

        if (hours > 0) return pad(hours) + ":" + pad(mins) + ":" + pad(secs)
        return pad(mins) + ":" + pad(secs) + "." + pad(centis)
    }

    Timer {
        interval: 33
        running: root.running
        repeat: true
        onTriggered: root._tick++
    }
}
