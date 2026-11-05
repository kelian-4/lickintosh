pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var files: []

    function refresh() {
        proc.running = true
    }

    function nameOf(path) {
        return path.slice(path.lastIndexOf("/") + 1)
    }

    Process {
        id: proc
        command: ["bash", "-c",
            "f=~/.local/share/recently-used.xbel; " +
            "[ -f \"$f\" ] || exit 0; " +
            "awk '/<bookmark / { href=\"\"; visited=\"\"; if (match($0, /href=\"[^\"]*\"/)) { href=substr($0, RSTART+6, RLENGTH-7) } if (match($0, /visited=\"[^\"]*\"/)) { visited=substr($0, RSTART+9, RLENGTH-10) } if (href != \"\") print visited \"\\t\" href }' \"$f\" " +
            "| sort -r | cut -f2- | sed 's#^file://##' " +
            "| while IFS= read -r p; do printf '%b\\n' \"${p//%/\\\\x}\"; done"
        ]
        stdout: StdioCollector { id: out }
        onExited: {
            var lines = out.text.trim().split("\n")
            var list = []
            for (var i = 0; i < lines.length; i++) {
                if (lines[i]) list.push(lines[i])
            }
            root.files = list
        }
    }
}
