import QtQuick
import Quickshell
import qs.services

Scope {
    id: root

    property bool wanted: false
    property int exitDuration: ShellMotion.fade()
    property bool present: false

    onWantedChanged: {
        if (root.wanted) {
            exitTimer.stop()
            root.present = true
        } else {
            exitTimer.restart()
        }
    }

    Component.onCompleted: root.present = root.wanted

    Timer {
        id: exitTimer
        interval: root.exitDuration
        onTriggered: root.present = false
    }
}
