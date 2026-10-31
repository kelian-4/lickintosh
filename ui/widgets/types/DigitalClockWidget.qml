import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var look: null

    property string size: "s"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.fillHeight: true }

        Text {
            text: Qt.formatTime(clock.date, "HH:mm")
            color: root.look.primary
            font.pixelSize: root.size === "s" ? 46 : 72
            font.weight: Font.Light
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            text: Qt.formatDate(clock.date, root.size === "s" ? "ddd d MMM" : "dddd d MMMM")
            color: "#5e5ce6"
            font.pixelSize: root.size === "s" ? 13 : 16
            font.weight: Font.Medium
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }
    }
}
