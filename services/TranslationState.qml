pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "translationState"

    property bool available: false
    property bool loading: false
    property string lastResult: ""
    property string lastError: ""
    property string targetLang: "fr"

    Process {
        id: _detect
        running: true
        command: ["sh", "-c", "command -v trans >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() === "yes"
        }
    }

    function translate(text) {
        if (!root.available || !text || text.trim() === "") return
        root.loading = true
        root.lastError = ""
        _translateProc.command = ["trans", "-b", ":" + root.targetLang, text]
        _translateProc.running = true
    }

    Process {
        id: _translateProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                root.lastResult = text.trim()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") root.lastError = text.trim()
            }
        }
    }
}
