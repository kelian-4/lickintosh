import Quickshell
import QtQuick
import QtQuick.Controls
import qs.components.glass

Slider {
    id: slider

    property bool autoHideHandle: false
    property Item glassBackdrop: GlassRegistry.lookup(QsWindow.window)
    property bool recentlyChanged: false
    readonly property bool handleShown: !slider.autoHideHandle || slider.pressed || slider.recentlyChanged

    onValueChanged: {
        if (!slider.autoHideHandle) return
        slider.recentlyChanged = true
        hideTimer.restart()
    }

    Component.onCompleted: {
        slider.recentlyChanged = false
        hideTimer.stop()
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: slider.recentlyChanged = false
    }

    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 6
        width: slider.availableWidth
        height: implicitHeight
        radius: 10
        color: "#30000000"

        Rectangle {
            width: slider.visualPosition * parent.width
            height: parent.height
            color: "#fff"
            radius: 10
        }
    }

    handle: BoxGlass {
        backdrop: slider.glassBackdrop
        opacity: slider.handleShown ? 1 : 0
        visible: opacity > 0
        x: slider.leftPadding + Math.min(slider.availableWidth - width, Math.max(0, (slider.visualPosition * (slider.availableWidth - (width)))))
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.pressed ? 40 : 30
        height: slider.pressed ? 25 : 15
        radius: 99
        color: slider.pressed ? "#20ffffff" : "#ffffff"
        light: slider.pressed ? "#fff" : "transparent"
        rimStrength: slider.pressed ? 1 : 0.8

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 2
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 2
            }
        }
    }

    from: 0
    to: 1
    stepSize: 0.01
}
