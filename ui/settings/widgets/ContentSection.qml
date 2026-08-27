import QtQuick
import QtQuick.Layouts
import qs.ui.glass
import qs.ui.primitives

ColumnLayout {
    id: root

    property string title: ""
    default property alias content: _inner.data

    Layout.fillWidth: true
    spacing: 8

    CFText {
        text: root.title
        font.pixelSize: 13
        font.weight: Font.Bold
        gray: true
        visible: root.title.length > 0
        Layout.leftMargin: 4
    }

    BoxGlass {
        Layout.fillWidth: true
        implicitHeight: _inner.implicitHeight + 28
        radius: 14
        color: "#18000000"
        light: "#20ffffff"
        rimStrength: 0.8

        ColumnLayout {
            id: _inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 16
        }
    }
}
