import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

RowLayout {
    id: root
    spacing: 6

    component Badge: Rectangle {
        id: badge

        property bool shown: false
        property string icon: ""
        property color tint: "#FFFFFF"
        property string label: ""
        property string labelFamily: "SF Pro Text"
        property bool dismissible: false
        property real reveal: badge.shown ? 1 : 0

        signal dismissed()

        visible: badge.reveal > 0
        opacity: badge.reveal
        scale: 0.85 + 0.15 * badge.reveal
        Layout.preferredHeight: 22
        Layout.preferredWidth: (content.implicitWidth + 18) * badge.reveal
        radius: 11
        color: "#1A1A1A"
        clip: true

        Behavior on reveal {
            NumberAnimation {
                duration: ShellMotion.effects(1.5)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.effectsCurve
            }
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 6

            TintedIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 12
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + badge.icon)
                tint: badge.tint
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: badge.label
                color: "#E6E6E6"
                font.pixelSize: 11
                font.family: badge.labelFamily
            }

            Item {
                visible: badge.dismissible
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12

                TintedIcon {
                    anchors.centerIn: parent
                    size: 9
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/x.svg")
                    tint: "#8A8A8A"
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: badge.dismissed()
                }
            }
        }
    }

    Badge {
        shown: MediaCaptureState.cameraActive
        icon: "notch/camera.svg"
        tint: "#4ADE80"
        label: "Caméra"
    }

    Badge {
        shown: MediaCaptureState.micActive
        icon: "notch/mic.svg"
        tint: "#FBBF24"
        label: "Micro"
    }

    Badge {
        shown: GameMode.enabled
        icon: "notch/award.svg"
        tint: "#FF6B6B"
        label: "Game Mode"
        dismissible: true
        onDismissed: GameMode.disable()
    }

    Badge {
        shown: NotchState.batteryCharging
        icon: "battery/zap.svg"
        tint: "#4ADE80"
        label: NotchState.batteryPercent + "%"
    }

    Badge {
        shown: StopwatchState.running
        icon: "notch/clock.svg"
        label: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
        labelFamily: "SF Mono"
    }

    Badge {
        shown: TimerState.running
        icon: "notch/clock.svg"
        label: TimerState.formatRemaining(TimerState.remainingMs)
        labelFamily: "SF Mono"
    }
}
