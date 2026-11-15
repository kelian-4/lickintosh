pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string pendingAction: ""
    signal requested()

    function openApplications() {
        root.pendingAction = "applications"
        root.requested()
    }
}
