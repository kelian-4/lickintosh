import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    readonly property var _entry: NotchState.topUrgent

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: "#1E1E1E"
            Text {
                anchors.centerIn: parent
                text: "◌"
                color: "#4ADE80"
                font.pixelSize: 18
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: root._entry ? root._entry.title : "Bluetooth"
                color: "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                text: root._entry ? root._entry.subtitle : ""
                color: "#4ADE80"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
            }
        }
    }
}
