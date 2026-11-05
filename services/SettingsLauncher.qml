pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    function open(page) {
        var cmd = ["quickshell", "-p", Quickshell.shellDir + "/settings.qml"]
        if (page && page.length > 0)
            cmd = ["env", "LICKINTOSH_PAGE=" + page].concat(cmd)
        Quickshell.execDetached(cmd)
    }
}
