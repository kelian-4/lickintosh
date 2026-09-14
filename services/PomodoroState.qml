pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "pomodoroState"

    property int workMinutes: 25
    property int breakMinutes: 5
    property int longBreakMinutes: 15
    property int cyclesBeforeLongBreak: 4

    property bool running: false
    // "work" | "break" | "longBreak"
    property string phase: "work"
    property int cyclesCompleted: 0

    property double endsAtMs: 0
    property double remainingAtPauseMs: 0

    property int _tick: 0
    readonly property double remainingMs: {
        root._tick
        if (!root.running) return root.remainingAtPauseMs
        var r = root.endsAtMs - Date.now()
        return r > 0 ? r : 0
    }

    function _phaseDurationMs(phase) {
        if (phase === "work") return root.workMinutes * 60000
        if (phase === "longBreak") return root.longBreakMinutes * 60000
        return root.breakMinutes * 60000
    }

    function start() {
        if (root.running) return
        if (root.remainingAtPauseMs <= 0) root.remainingAtPauseMs = root._phaseDurationMs(root.phase)
        root.endsAtMs = Date.now() + root.remainingAtPauseMs
        root.running = true
    }

    function pause() {
        if (!root.running) return
        root.remainingAtPauseMs = Math.max(0, root.endsAtMs - Date.now())
        root.running = false
    }

    function reset() {
        root.running = false
        root.phase = "work"
        root.cyclesCompleted = 0
        root.remainingAtPauseMs = root._phaseDurationMs("work")
    }

    function skip() {
        root._advancePhase()
    }

    function _advancePhase() {
        root.running = false
        if (root.phase === "work") {
            root.cyclesCompleted++
            root.phase = (root.cyclesCompleted % root.cyclesBeforeLongBreak === 0) ? "longBreak" : "break"
        } else {
            root.phase = "work"
        }
        root.remainingAtPauseMs = root._phaseDurationMs(root.phase)
        _phaseSoundProc.running = true
    }

    Process {
        id: _phaseSoundProc
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
            if (root.remainingMs <= 0 && root.running) root._advancePhase()
        }
    }

    Component.onCompleted: root.remainingAtPauseMs = root._phaseDurationMs("work")
}
