import QtQuick
import qs.components

Item {
    id: root

    property string kind: "glass"
    property color col: "white"
    property real size: 22

    implicitWidth: root.size
    implicitHeight: root.size

    CFVI {
        visible: root.kind !== "glass"
        anchors.centerIn: parent
        size: root.size
        icon: root.kind === "light" ? "weather/sun.svg" : "notch/moon.svg"
        color: root.col
    }

    Item {
        visible: root.kind === "glass"
        anchors.centerIn: parent
        width: root.size
        height: root.size

        Rectangle {
            x: 0
            y: 0
            width: root.size * 0.66
            height: root.size * 0.66
            radius: root.size * 0.18
            color: "transparent"
            border.width: Math.max(1.5, root.size * 0.09)
            border.color: root.col
        }

        Rectangle {
            x: root.size * 0.34
            y: root.size * 0.34
            width: root.size * 0.66
            height: root.size * 0.66
            radius: root.size * 0.18
            color: Qt.rgba(root.col.r, root.col.g, root.col.b, 0.35)
            border.width: Math.max(1.5, root.size * 0.09)
            border.color: root.col
        }
    }
}
