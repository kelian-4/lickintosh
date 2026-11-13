import QtQuick
import qs.components
import qs.services

Rectangle {
    id: root

    property string text: ""
    property string chipState: "installed"

    implicitWidth: _l.implicitWidth + 24
    implicitHeight: 24
    radius: 12
    color: state === "install" ? "#33FF9F0A" : state === "skipped" ? "#33FF453A" : "#18ffffff"

    CFText {
        id: _l
        anchors.centerIn: parent
        text: (root.chipState === "installed" ? "✓ " : root.chipState === "skipped" ? "– " : "") + root.text
        font.pixelSize: 12
        color: root.chipState === "install" ? "#FF9F0A" : Theme.textPrimary
    }
}
