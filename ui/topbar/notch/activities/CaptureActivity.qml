import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            visible: MediaCaptureState.cameraActive
            spacing: 10
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: "#4ADE80" }
            Text {
                Layout.fillWidth: true
                text: "Caméra : " + MediaCaptureState.cameraApps.join(", ")
                color: "#FFFFFF"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: MediaCaptureState.micActive
            spacing: 10
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: "#FBBF24" }
            Text {
                Layout.fillWidth: true
                text: "Micro : " + MediaCaptureState.micApps.join(", ")
                color: "#FFFFFF"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true }
    }
}
