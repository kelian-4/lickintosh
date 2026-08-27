pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "timerState"

    property bool running: false
    property bool firing: false
    property double totalMs: 0
    property double remainingAtPauseMs: 0
    property double endsAtMs: 0

    property int _tick: 0

    readonly property double remainingMs: {
        root._tick
        if (root.firing) return 0
        if (!root.running) return root.remainingAtPauseMs
        var r = root.endsAtMs - Date.now()
        return r > 0 ? r : 0
    }

    function start(durationMs) {
        root.totalMs = durationMs
        root.remainingAtPauseMs = durationMs
        root.endsAtMs = Date.now() + durationMs
        root.running = true
        root.firing = false
    }

    function pause() {
        if (!root.running) return
        root.remainingAtPauseMs = Math.max(0, root.endsAtMs - Date.now())
        root.running = false
    }

    function resume() {
        if (root.running || root.remainingAtPauseMs <= 0) return
        root.endsAtMs = Date.now() + root.remainingAtPauseMs
        root.running = true
    }

    function cancel() {
        root.running = false
        root.firing = false
        root.totalMs = 0
        root.remainingAtPauseMs = 0
        root.endsAtMs = 0
    }

    function dismissFiring() {
        root.firing = false
        root.totalMs = 0
        root.remainingAtPauseMs = 0
    }

    function formatRemaining(ms) {
        var totalSecs = Math.ceil(ms / 1000)
        var secs = totalSecs % 60
        var totalMins = Math.floor(totalSecs / 60)
        var mins = totalMins % 60
        var hours = Math.floor(totalMins / 60)

        function pad(n) { return n < 10 ? "0" + n : "" + n }

        if (hours > 0) return hours + ":" + pad(mins) + ":" + pad(secs)
        return mins + ":" + pad(secs)
    }

    Process {
        id: _timerSoundProc
        command: ["sh", "-c",
            "command -v canberra-gtk-play >/dev/null 2>&1 && canberra-gtk-play -i complete 2>/dev/null || " +
            "command -v paplay >/dev/null 2>&1 && paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true"]
    }

    Timer {
        interval: 250
        running: root.running
        repeat: true
        onTriggered: {
            root._tick++
            if (root.remainingMs <= 0 && root.running) {
                root.running = false
                root.firing = true
                _timerSoundProc.running = true
            }
        }
    }
}
