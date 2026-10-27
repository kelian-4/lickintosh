pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    reloadableId: "coucouState"

    readonly property string command: ShellConfig.options.coucou.command.trim()

    function launch() {
        root._run([])
    }

    function toggleIsland() {
        root._run(["--shortcut", "toggleIsland"])
    }

    function openChat() {
        root._run(["--shortcut", "openChat"])
    }

    function _run(args) {
        if (root.command === "") return
        _process.command = [root.command].concat(args)
        _process.startDetached()
    }

    Process {
        id: _process
    }
}
