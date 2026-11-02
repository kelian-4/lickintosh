import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        title: "lgclient"
        implicitWidth: 520
        implicitHeight: 360
        color: "#203040"

        Grid {
            anchors.fill: parent
            anchors.margins: 12
            columns: 4
            spacing: 8
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    width: 112
                    height: 100
                    color: Qt.hsla(index / 12, 0.9, 0.5, 1)
                    Text {
                        anchors.centerIn: parent
                        text: parent.index
                        font.pixelSize: 40
                        color: "white"
                    }
                }
            }
        }
    }
}
