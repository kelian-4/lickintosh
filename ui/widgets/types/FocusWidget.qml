import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    readonly property bool working: PomodoroState.phase === "work"
    readonly property color phaseColor: root.working ? "#ff453a" : "#30d158"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.working ? "Focus" : "Break"
                color: root.phaseColor
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.size === "m"
                text: "Cycle " + ((PomodoroState.cyclesCompleted % PomodoroState.cyclesBeforeLongBreak) + 1) + " of " + PomodoroState.cyclesBeforeLongBreak
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }

        Text {
            text: TimerState.formatRemaining(PomodoroState.remainingMs)
            color: "#ffffff"
            font.pixelSize: root.size === "s" ? 34 : 44
            font.weight: Font.Light
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            WidgetButton {
                text: PomodoroState.running ? "Pause" : "Start"
                tint: root.phaseColor
                onClicked: PomodoroState.running ? PomodoroState.pause() : PomodoroState.start()
            }

            WidgetButton {
                visible: root.size === "m"
                text: "Skip"
                onClicked: PomodoroState.skip()
            }

            WidgetButton {
                text: "Reset"
                onClicked: PomodoroState.reset()
            }
        }
    }
}
