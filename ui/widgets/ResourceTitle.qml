import QtQuick
import Quickshell

Row {
    id: root

    property string title: ""
    property color tint: "#30d158"
    property bool showTime: false

    spacing: 6

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 10
        radius: 3
        color: root.tint
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: "#ffffff"
        font.pixelSize: 13
        font.weight: Font.Bold
        font.family: "SF Pro Rounded"
        renderType: Text.NativeRendering
    }

    readonly property string updated: "Updated " + Qt.formatTime(clock.date, "hh:mm")
}
