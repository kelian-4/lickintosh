import QtQuick
import qs.components

Rectangle {
    id: pill

    property string label: ""
    property string icon: ""
    property bool picked: false
    signal activated()

    height: 46
    radius: height / 2
    color: pill.picked ? "#ffffff" : (pillMa.containsMouse ? Qt.rgba(0.08, 0.1, 0.14, 0.78) : Qt.rgba(0.08, 0.1, 0.14, 0.62))
    border.width: pill.picked ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.22)
    Behavior on color { ColorAnimation { duration: 160 } }

    ThemeGlyph {
        visible: pill.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        kind: pill.icon
        size: 22
        col: pill.picked ? "#000000" : "#ffffff"
    }

    CFText {
        anchors.centerIn: parent
        width: parent.width - 100
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: pill.label
        font.family: "SF Pro Text"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: pill.picked ? "#000000" : "#ffffff"
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.activated()
    }
}
