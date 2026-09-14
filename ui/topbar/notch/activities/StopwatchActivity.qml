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
            text: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
            color: "#FFFFFF"
            font.pixelSize: 28
            font.family: "SF Pro Mono"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 30
                radius: 15
                color: "#2A2A2A"
                Text {
                    anchors.centerIn: parent
                    text: StopwatchState.running ? "Pause" : "Démarrer"
                    color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded"
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: StopwatchState.toggle() }
            }

            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 30
                radius: 15
                color: "#4A1E1E"
                Text { anchors.centerIn: parent; text: "Réinitialiser"; color: "#FF6B6B"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: StopwatchState.reset() }
            }
        }
    }
}
