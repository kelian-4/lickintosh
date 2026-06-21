import Quickshell
import QtQuick
import QtQuick.Controls
import qs.ui.glass

Switch {
    id: control
    text: ""

    property int switchHeight: 22
    property int switchWidth: 54

    indicator: Rectangle {
        id: bg
        implicitWidth: control.switchWidth
        implicitHeight: control.switchHeight
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 999
        color: control.checked ? "#1C7AFF" : "#20000000"
        Behavior on color {
            ColorAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        BoxGlass {
            id: handle
            anchors.verticalCenter: parent.verticalCenter
            x: control.checked ? bg.width - width - 2 : 2
            width: control.down ? (control.switchWidth / 2) + 14 : (control.switchWidth / 2) + 8
            height: control.down ? control.switchHeight + 6 : control.switchHeight - 4
            radius: 999
            color: control.down ? "#20ffffff" : "#ffffff"
            light: control.down ? "#fff" : "transparent"
            rimStrength: control.down ? 1 : 0.8

            Behavior on x {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 3
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 3
                }
            }
        }
    }
}
