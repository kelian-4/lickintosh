import QtQuick
import Quickshell

Item {
    id: root

    property string icon: ""
    property bool active: true
    property real size: 18
    signal clicked()

    implicitWidth: root.size
    implicitHeight: root.size

    TintedIcon {
        anchors.fill: parent
        size: root.size
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + root.icon)
        tint: root.active ? "#FFFFFF" : "#4A4A4A"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.active
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
