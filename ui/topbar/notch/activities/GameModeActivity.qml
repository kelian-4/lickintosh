import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Game Mode actif"
            color: "#FFFFFF"
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Animations, flou et ombres désactivés"
            color: "#8A8A8A"
            font.pixelSize: 11
            font.family: "SF Pro Rounded"
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.preferredWidth: 120
            Layout.preferredHeight: 30
            radius: 15
            color: "#4A1E1E"
            Text { anchors.centerIn: parent; text: "Désactiver"; color: "#FF6B6B"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: GameMode.disable() }
        }
    }
}
