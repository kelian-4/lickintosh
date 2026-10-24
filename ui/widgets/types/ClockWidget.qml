import QtQuick
import Quickshell

Item {
    id: root

    property string size: "s"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Item {
        id: face
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#f4f4f6"
        }

        Repeater {
            model: 12

            delegate: Item {
                required property int index
                anchors.fill: parent
                rotation: index * 30

                Rectangle {
                    x: parent.width / 2 - width / 2
                    y: 6
                    width: index % 3 === 0 ? 3 : 2
                    height: index % 3 === 0 ? 10 : 6
                    radius: 1
                    color: "#2b2b30"
                }
            }
        }

        Item {
            anchors.fill: parent
            rotation: (clock.hours % 12 + clock.minutes / 60) * 30

            Rectangle {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height
                width: 5
                height: face.height * 0.24
                radius: 2.5
                color: "#1c1c1f"
            }
        }

        Item {
            anchors.fill: parent
            rotation: (clock.minutes + clock.seconds / 60) * 6

            Rectangle {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height
                width: 4
                height: face.height * 0.36
                radius: 2
                color: "#1c1c1f"
            }
        }

        Item {
            anchors.fill: parent
            rotation: clock.seconds * 6

            Rectangle {
                x: parent.width / 2 - width / 2
                y: parent.height / 2 - height
                width: 2
                height: face.height * 0.40
                radius: 1
                color: "#ff9500"
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 9
            height: 9
            radius: 4.5
            color: "#ff9500"
        }
    }
}
