import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.services

PanelWindow {
    id: root

    property var notifServer: null

    readonly property var _spatialCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property int _spatialDuration: 500
    readonly property var _effectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property int _effectsDuration: 200

    screen: NotchState.screen || Quickshell.screens[0]
    color: "transparent"
    exclusiveZone: 0
    focusable: NotchState.expanded

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lickintosh-notch"
    WlrLayershell.keyboardFocus: NotchState.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property bool isExpanded:  NotchState.expanded
    readonly property bool isDashboard: root.isExpanded && !NotchState.hasUrgentActivity

    readonly property real targetWidth:  root.isDashboard ? 620 : 440
    readonly property real targetHeight: root.isDashboard ? 380 : 300

    HyprlandFocusGrab {
        active: root.isExpanded
        windows: [root]
        onCleared: NotchState.close()
    }

    Item {
        anchors.fill: parent
        focus: root.isExpanded
        Keys.onEscapePressed: NotchState.close()
    }

    Rectangle {
        id: pill
        x: NotchState.anchorX - width / 2
        y: 38
        width: root.isExpanded ? root.targetWidth : 0
        height: root.isExpanded ? root.targetHeight : 0
        radius: 26
        color: "#0A0A0A"
        opacity: root.isExpanded ? 1 : 0

        Behavior on width   { NumberAnimation { duration: root._spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._spatialCurve } }
        Behavior on height  { NumberAnimation { duration: root._spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._spatialCurve } }
        Behavior on opacity { NumberAnimation { duration: root._effectsDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._effectsCurve } }

        FadeLoader {
            anchors.fill: parent
            anchors.margins: 16
            shouldBeActive: root.isExpanded
            fadeDuration: root._effectsDuration
            fadeCurve: root._effectsCurve
            sourceComponent: NotchExpandedContent {}
        }
    }

    mask: _pillMask
    Region { id: _pillMask; item: pill }

    Connections {
        target: root.notifServer
        function onNotification(notification) {
            NotchState.notifyIncoming(notification.appName, notification.summary, notification.appIcon)
        }
    }

    component FadeLoader: Loader {
        id: fl
        property bool shouldBeActive: false
        property int fadeDuration: 200
        property var fadeCurve: [0.34, 0.8, 0.34, 1, 1, 1]

        active: false
        opacity: 0

        states: State {
            name: "active"
            when: fl.shouldBeActive
            PropertyChanges { fl.opacity: 1; fl.active: true }
        }

        transitions: [
            Transition {
                from: ""; to: "active"
                SequentialAnimation {
                    PropertyAction { property: "active" }
                    NumberAnimation { property: "opacity"; duration: fl.fadeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: fl.fadeCurve }
                }
            },
            Transition {
                from: "active"; to: ""
                SequentialAnimation {
                    NumberAnimation { property: "opacity"; duration: fl.fadeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: fl.fadeCurve }
                    PropertyAction { property: "active" }
                }
            }
        ]
    }
}
