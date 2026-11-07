pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string action: ""

    function request(name) {
        root.action = name
    }

    function clear() {
        root.action = ""
    }
}
