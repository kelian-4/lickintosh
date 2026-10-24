import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Text {
            text: "Stopwatch"
            color: "#ff9f0a"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Text {
            text: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
            color: "#ffffff"
            font.pixelSize: root.size === "s" ? 30 : 44
            font.weight: Font.Light
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            WidgetButton {
                text: StopwatchState.running ? "Stop" : "Start"
                tint: StopwatchState.running ? "#ff453a" : "#30d158"
                onClicked: StopwatchState.toggle()
            }

            WidgetButton {
                visible: !StopwatchState.running && StopwatchState.elapsedMs > 0
                text: "Reset"
                onClicked: StopwatchState.reset()
            }
        }
    }
}
