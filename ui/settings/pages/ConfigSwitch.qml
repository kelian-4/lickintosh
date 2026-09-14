import QtQuick
import QtQuick.Layouts
import qs.components

Item {
    id: root

    property string text: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool value)

    Layout.fillWidth: true
    implicitHeight: Math.max(_col.implicitHeight, _row.implicitHeight)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 8
        color: _mouse.containsMouse ? "#0cffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        id: _row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        ColumnLayout {
            id: _col
            Layout.fillWidth: true
            spacing: 2

            CFText {
                text: root.text
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: root.description
                font.pixelSize: 12
                gray: true
                visible: root.description.length > 0
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        CFSwitch {
            checked: root.checked
            onCheckedChanged: {
                if (checked !== root.checked) {
                    root.checked = checked
                    root.toggled(checked)
                }
            }
        }
    }

    MouseArea {
        id: _mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
