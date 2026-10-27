import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 60
            Layout.preferredHeight: 32

            Rectangle {
                id: shell
                anchors.fill: parent
                anchors.rightMargin: 4
                radius: 5
                color: "transparent"
                border.color: "#5A5A5A"
                border.width: 2

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    width: (parent.width - 6) * Math.min(1, NotchState.batteryPercent / 100)
                    radius: 2
                    color: "#4ADE80"

                    Behavior on width { NumberAnimation { duration: 400 } }

                    SequentialAnimation on opacity {
                        running: NotchState.batteryCharging
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }
            }
            Rectangle {
                anchors.left: shell.right
                anchors.verticalCenter: shell.verticalCenter
                width: 3
                height: 12
                radius: 1
                color: "#5A5A5A"
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (NotchState.batteryCharging ? "Charge en cours · " : "") + NotchState.batteryPercent + "%"
            color: "#FFFFFF"
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
        }
    }
}
