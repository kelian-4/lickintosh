pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    function toggle() {
        enabled = !enabled
    }

    function enable() {
        enabled = true
    }

    function disable() {
        enabled = false
    }

    Process {
        id: _onCmd
        command: [
            "hyprctl", "eval",
            "hl.config({" +
            " animations = { enabled = false }," +
            " decoration = {" +
            "   shadow = { enabled = false }," +
            "   blur = { enabled = false }," +
            "   rounding = 0," +
            " }," +
            " general = {" +
            "   gaps_in = 0," +
            "   gaps_out = 0," +
            "   border_size = 1," +
            "   allow_tearing = true," +
            " }," +
            "})"
        ]
        stderr: SplitParser {
            onRead: line => console.warn("GameMode enable error: " + line)
        }
    }
    Process {
        id: _onPowerCmd
        command: ["powerprofilesctl", "set", "performance"]
        stderr: SplitParser {
            onRead: line => console.warn("GameMode enable (power profile) error: " + line)
        }
    }

    Process {
        id: _offCmd
        command: ["hyprctl", "reload"]
        stderr: SplitParser {
            onRead: line => console.warn("GameMode disable error: " + line)
        }
    }
    Process {
        id: _offPowerCmd
        command: ["powerprofilesctl", "set", "balanced"]
        stderr: SplitParser {
            onRead: line => console.warn("GameMode disable (power profile) error: " + line)
        }
    }

    onEnabledChanged: {
        if (enabled) {
            _onCmd.running = true
            _onPowerCmd.running = true
        } else {
            _offCmd.running = true
            _offPowerCmd.running = true
        }
    }
}
