import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    property bool running: false

    Layout.fillWidth: true
    implicitHeight: 4
    radius: 2
    color: Theme.controlTrack
    visible: root.running
    clip: true

    Rectangle {
        id: _bar
        width: parent.width * 0.3
        height: parent.height
        radius: 2
        color: Theme.accent

        SequentialAnimation on x {
            running: root.running
            loops: Animation.Infinite
            NumberAnimation { from: -_bar.width; to: root.width; duration: 1100; easing.type: Easing.InOutQuad }
        }
    }
}
