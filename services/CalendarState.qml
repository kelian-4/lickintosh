pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "calendarState"

    property bool available: false
    property var events: []

    Process {
        id: _detect
        running: true
        command: ["sh", "-c", "command -v khal >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim() === "yes"
                if (root.available) root.refresh()
            }
        }
    }

    function refresh() {
        if (!root.available) return
        _listProc.running = true
    }

    Process {
        id: _listProc
        command: ["khal", "list", "today", "3d"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(text) {
        var lines = text.split("\n")
        var result = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) continue

            var m = line.match(/^(\d{1,2}:\d{2}(?:-\d{1,2}:\d{2})?)\s+(.+)$/)
            if (m) result.push({ time: m[1], title: m[2] })
        }
        root.events = result.slice(0, 6)
    }

    Timer {
        interval: 15 * 60 * 1000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }
}
