pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    signal changed()

    readonly property var eventNames: ["workspace", "workspacev2", "activespecial", "activespecialv2"]

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.eventNames.indexOf(event.name) !== -1)
                root.changed()
        }
    }
}
