pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    function open(page) {
        var cmd = ["quickshell", "-p", Quickshell.shellDir + "/installer.qml"]
        if (page && page.length > 0)
            cmd = ["env", "LICKINTOSH_INSTALLER_PAGE=" + page].concat(cmd)
        Quickshell.execDetached(cmd)
    }
}
