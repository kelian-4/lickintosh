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
            text: TimerState.firing ? "Temps écoulé" : TimerState.formatRemaining(TimerState.remainingMs)
            color: "#FFFFFF"
            font.pixelSize: TimerState.firing ? 16 : 28
            font.family: "SF Pro Mono"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Rectangle {
                visible: TimerState.firing
                Layout.preferredWidth: 90
                Layout.preferredHeight: 30
                radius: 15
                color: "#2A2A2A"
                Text { anchors.centerIn: parent; text: "Ignorer"; color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TimerState.dismissFiring() }
            }

            Rectangle {
                visible: !TimerState.firing && TimerState.totalMs > 0
                Layout.preferredWidth: 90
                Layout.preferredHeight: 30
                radius: 15
                color: "#2A2A2A"
                Text {
                    anchors.centerIn: parent
                    text: TimerState.running ? "Pause" : "Reprendre"
                    color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded"
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TimerState.running ? TimerState.pause() : TimerState.resume() }
            }

            Rectangle {
                visible: !TimerState.firing && TimerState.totalMs > 0
                Layout.preferredWidth: 90
                Layout.preferredHeight: 30
                radius: 15
                color: "#4A1E1E"
                Text { anchors.centerIn: parent; text: "Annuler"; color: "#FF6B6B"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: TimerState.cancel() }
            }
        }
    }
}
