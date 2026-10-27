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
            radius: 10
            color: "#1E1E1E"
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: root._entry ? root._entry.icon : ""
                fillMode: Image.PreserveAspectFit
                visible: root._entry && root._entry.icon !== ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: root._entry ? root._entry.title : ""
                color: "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root._entry ? root._entry.subtitle : ""
                color: "#B0B0B0"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
