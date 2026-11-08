import Quickshell
import QtQuick
import QtQuick.Controls
import qs.components.glass
import qs.services

Switch {
    id: control
    text: ""

    property int switchHeight: 22
    property int switchWidth: 54
    readonly property real knobInset: Math.max(2, control.switchHeight * 0.085)
    readonly property real knobH0: control.switchHeight - 2 * control.knobInset
    readonly property real knobW0: Math.round(control.knobH0 * 1.6)

    indicator: Rectangle {
        id: bg
        implicitWidth: control.switchWidth
        implicitHeight: control.switchHeight
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 999
        color: Theme.themed(control) ? (control.checked ? Theme.accent : Theme.controlTrack) : (control.checked ? "#1C7AFF" : "#20000000")
        Behavior on color {
            ColorAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        BoxGlass {
            id: handle
            backdrop: null
            anchors.verticalCenter: parent.verticalCenter
            x: control.checked ? bg.width - width - control.knobInset : control.knobInset
            width: control.knobW0 + (control.down ? control.switchHeight * 0.14 : 0)
            height: control.knobH0 + (control.down ? control.switchHeight * 0.07 : 0)
            radius: 999
            color: control.down ? "#20ffffff" : "#ffffff"
            light: control.down ? "#fff" : "transparent"
            rimStrength: control.down ? 1 : 0.8

            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.4
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.4
                }
            }
        }
    }
}
