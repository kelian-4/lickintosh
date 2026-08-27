pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "batteryHistoryState"

    readonly property string historyPath: "$HOME/.local/share/quickshell/battery-history.csv"

    property var rawEntries: []

    readonly property var last24h: {
        var cutoff = Date.now() / 1000 - 24 * 3600
        return root.rawEntries.filter(function(e) { return e.timestamp >= cutoff })
    }

    readonly property var last10days: root.rawEntries

    function _hourlyScreenUsage(entries, intervalSeconds) {
        if (entries.length === 0) return []

        var buckets = {}
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            var hourKey = Math.floor(e.timestamp / 3600) * 3600
            if (!buckets[hourKey]) buckets[hourKey] = { total: 0, on: 0 }
            buckets[hourKey].total++
            if (e.screenOn) buckets[hourKey].on++
        }

        var result = []
        var keys = Object.keys(buckets).sort()
        for (var k = 0; k < keys.length; k++) {
            var hourTs = parseInt(keys[k])
            var b = buckets[hourTs]
            var minutesOn = Math.min(60, Math.round((b.on / b.total) * 60))
            result.push({ hourTimestamp: hourTs, minutesOn: minutesOn })
        }
        return result
    }

    readonly property var screenUsage24h: root._hourlyScreenUsage(root.last24h)
    readonly property var screenUsage10days: root._hourlyScreenUsage(root.last10days)

    function _loadHistory() {
        _loadProc.running = true
    }

    function _collectNow() {
        _collectProc.running = true
    }

    Process {
        id: _collectProc
        command: ["bash", Quickshell.shellDir + "/tools/battery-history/collect.sh"]
        onExited: root._loadHistory()
    }

    Process {
        id: _loadProc
        command: ["sh", "-c", "tail -n +2 '" + root.historyPath.replace(/'/g, "'\\''") + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var entries = []
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0) continue
                    var parts = lines[i].split(",")
                    if (parts.length < 3) continue
                    var ts = parseInt(parts[0])
                    var pct = parseInt(parts[1])
                    if (isNaN(ts) || isNaN(pct)) continue
                    var screenOn = parts.length >= 4 ? parts[3].trim() === "1" : true
                    entries.push({ timestamp: ts, percent: pct, state: parts[2], screenOn: screenOn })
                }
                root.rawEntries = entries
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._collectNow()
    }
}
