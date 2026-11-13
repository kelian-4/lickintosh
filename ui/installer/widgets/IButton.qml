import QtQuick
import qs.components
import qs.services

Rectangle {
    id: root

    property string text: ""
    property bool main: false
    property bool destructive: false
    signal clicked()

    implicitWidth: Math.max(90, _label.implicitWidth + 28)
    implicitHeight: 28
    radius: 8
    opacity: enabled ? 1 : 0.45
    color: root.main ? Qt.lighter(Theme.accent, _mouse.pressed ? 0.9 : (_mouse.containsMouse ? 1.1 : 1))
         : root.destructive ? (_mouse.containsMouse ? "#40FF453A" : "#2AFF453A")
         : (_mouse.containsMouse ? "#24ffffff" : "#18ffffff")
    border.color: root.main ? "transparent" : "#14ffffff"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 100 } }

    CFText {
        id: _label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 13
        font.weight: root.main ? Font.DemiBold : Font.Normal
        color: root.main ? Theme.onAccent : (root.destructive ? "#FF453A" : Theme.textPrimary)
    }

    MouseArea {
        id: _mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
