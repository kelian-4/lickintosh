import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    Layout.preferredWidth: 128
    Layout.fillHeight: true

    readonly property int cycle: (PomodoroState.cyclesCompleted % PomodoroState.cyclesBeforeLongBreak) + 1
    readonly property string phaseLabel: PomodoroState.phase === "work"
                                         ? "Focus (" + root.cycle + "/" + PomodoroState.cyclesBeforeLongBreak + ")"
                                         : "Pause"

    function format(ms) {
        var total = Math.ceil(ms / 1000)
        var m = Math.floor(total / 60)
        var s = total % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.phaseLabel
            color: PomodoroState.phase === "work" ? "#8A8A8A" : "#34C759"
            font.pixelSize: 12
            font.bold: true
            font.family: "SF Pro Rounded"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.format(PomodoroState.remainingMs)
            color: "#FFFFFF"
            font.pixelSize: 30
            font.bold: true
            font.family: "SF Pro Rounded"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            spacing: 18

            CtrlButton { icon: "arrow-counterclockwise.svg"; size: 16; onClicked: PomodoroState.reset() }
            CtrlButton { icon: PomodoroState.running ? "music/pause.svg" : "music/play.svg"; onClicked: PomodoroState.running ? PomodoroState.pause() : PomodoroState.start() }
            CtrlButton { icon: "music/forward.svg"; size: 16; onClicked: PomodoroState.skip() }
        }

        Item { Layout.fillHeight: true }
    }
}
