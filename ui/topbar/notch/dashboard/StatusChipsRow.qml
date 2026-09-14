import QtQuick
import QtQuick.Layouts
import qs.services

/*
    Rangée de petits badges pour les états "continus" (pas urgents) :
    Game Mode, batterie en charge, capture caméra/micro, chrono en
    cours. Contrairement aux évènements urgents (alarme, minuteur,
    notification, bluetooth) qui prennent tout l'écran en expanded,
    ces états restent visibles ICI, dans le hub, sans jamais bloquer
    l'accès au reste — avec un petit bouton pour désactiver quand ça a
    du sens (Game Mode).
*/
RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 6
    visible: GameMode.enabled || NotchState.batteryCharging || MediaCaptureState.cameraActive
             || MediaCaptureState.micActive || StopwatchState.running

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property color tint: "#1A1A1A"
        property bool showDismiss: false
        signal dismiss()

        Layout.preferredHeight: 22
        implicitWidth: rowContent.implicitWidth + 16
        radius: 11
        color: chip.tint

        RowLayout {
            id: rowContent
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: chip.label
                color: "#FFFFFF"
                font.pixelSize: 10
                font.family: "SF Pro Rounded"
            }

            Rectangle {
                visible: chip.showDismiss
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                radius: 7
                color: "#4A1E1E"
                Text { anchors.centerIn: parent; text: "✕"; color: "#FF6B6B"; font.pixelSize: 8 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: chip.dismiss() }
            }
        }
    }

    Chip {
        visible: GameMode.enabled
        label: "🎮 Game Mode"
        tint: "#2A1A3A"
        showDismiss: true
        onDismiss: GameMode.disable()
    }

    Chip {
        visible: NotchState.batteryCharging
        label: "⚡ " + NotchState.batteryPercent + "%"
        tint: "#1A2A1A"
    }

    Chip {
        visible: MediaCaptureState.cameraActive
        label: "◉ Caméra"
        tint: "#1A2A1A"
    }

    Chip {
        visible: MediaCaptureState.micActive
        label: "● Micro"
        tint: "#2A2A1A"
    }

    Chip {
        visible: StopwatchState.running
        label: "◔ " + StopwatchState.formatElapsed(StopwatchState.elapsedMs)
        tint: "#1A1A2A"
    }

    Item { Layout.fillWidth: true }
}
