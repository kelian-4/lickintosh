import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property var look: null

    property string size: "s"

    readonly property bool paused: !TimerState.running && TimerState.remainingAtPauseMs > 0
    readonly property bool active: TimerState.running || root.paused
    readonly property var presets: root.size === "s" ? [5] : [1, 5, 10, 25]

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Text {
            text: "Timer"
            color: "#ff9f0a"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            text: TimerState.firing ? "Done" : (root.active ? TimerState.formatRemaining(TimerState.remainingMs) : "0:00")
            color: TimerState.firing ? "#ff9f0a" : root.look.primary
            font.pixelSize: root.size === "s" ? 34 : 44
            font.weight: Font.Light
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            WidgetButton {
                look: root.look
                visible: TimerState.firing
                text: "OK"
                tint: "#ff9f0a"
                onClicked: TimerState.dismissFiring()
            }

            Repeater {
                model: !root.active && !TimerState.firing ? root.presets : []

                delegate: WidgetButton {
                    look: root.look
                    required property int modelData
                    text: modelData + " min"
                    onClicked: TimerState.start(modelData * 60000)
                }
            }

            WidgetButton {
                look: root.look
                visible: root.active
                text: TimerState.running ? "Pause" : "Resume"
                tint: "#ff9f0a"
                onClicked: TimerState.running ? TimerState.pause() : TimerState.resume()
            }

            WidgetButton {
                look: root.look
                visible: root.active
                text: "Cancel"
                onClicked: TimerState.cancel()
            }
        }
    }
}
