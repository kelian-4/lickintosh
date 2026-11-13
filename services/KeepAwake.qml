pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "keepAwake"

    property bool enabled: false

    function toggle() {
        root.enabled = !root.enabled
    }

    function _restore() {
        if (ShellConfig.ready) root.enabled = ShellConfig.options.session.keepAwake
    }

    onEnabledChanged: {
        if (ShellConfig.ready) ShellConfig.options.session.keepAwake = root.enabled
    }

    Component.onCompleted: root._restore()

    Connections {
        target: ShellConfig
        function onReadyChanged() { root._restore() }
    }
}
