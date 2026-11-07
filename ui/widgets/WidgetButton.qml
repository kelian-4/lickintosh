import QtQuick

Rectangle {
    id: root

    property var look: null
    property string text: ""
    property color tint: root.look ? root.look.track : Qt.rgba(1, 1, 1, 0.16)
    readonly property bool neutral: root.look ? Qt.colorEqual(root.tint, root.look.track) : true
    property color textColor: root.neutral && root.look ? root.look.primary : "#ffffff"
    signal clicked()

    implicitWidth: label.implicitWidth + 22
    implicitHeight: 26
    radius: 13
    color: root.tint
    opacity: area.pressed ? 0.7 : 1

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: 12
        font.weight: Font.Medium
        font.family: "SF Pro Text"
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
