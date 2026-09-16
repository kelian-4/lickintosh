import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell.Services.Notifications
import Quickshell
import qs.services
import qs.ui.topbar.menubar
import qs.ui.topbar.notch
import qs.ui.topbar.statusarea

Rectangle {
    id: root
    signal toggleCC()
    signal toggleAppleMenu()
    signal toggleSpotlight()
    signal toggleAI()
    signal toggleNotifCenter()
    signal toggleWifi(int xPos)
    signal toggleBluetooth(int xPos)
    signal toggleBattery(int xPos)
    signal toggleVolume(int xPos)

    property var hostWindow: null
    property var notifServer: null
    property bool appleMenuOpened:  false
    property bool spotlightOpened:  false
    property int  notifUnreadCount: 0

    readonly property alias notchExpandedPanel: notchPill

    readonly property color themeBackground: "transparent"
    readonly property int   themeHeight:     32
    readonly property int   themeMargin:     20

    implicitHeight: themeHeight
    color:          themeBackground

    anchors.top:   parent.top
    anchors.left:  parent.left
    anchors.right: parent.right

    readonly property var _spatialCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property int  _spatialDuration: 500
    readonly property var  _effectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property int  _effectsDuration: 200

    FontLoader {
        id: macFont
        source: "../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    readonly property real notchZoneLeft:  root.themeMargin + menuBarItem.width
    readonly property real notchZoneRight: root.width - root.themeMargin - statusAreaItem.width

    Binding {
        target: NotchState
        property: "topbarZoneWidth"
        value: root.notchZoneRight - root.notchZoneLeft
    }

    Connections {
        target: root.notifServer
        function onNotification(notification) {
            NotchState.notifyIncoming(notification.appName, notification.summary, notification.appIcon)
        }
    }

    RowLayout {
        anchors.fill:        parent
        anchors.leftMargin:  root.themeMargin
        anchors.rightMargin: root.themeMargin

        opacity: NotchState.expanded ? 0 : 1
        enabled: !NotchState.expanded
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Item {
            id: menuBarItem
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.maximumWidth: root.width * 0.42
            implicitWidth:  Math.min(menuBarContent.implicitWidth, Layout.maximumWidth)
            implicitHeight: menuBarContent.implicitHeight
            clip: true

            MenuBar {
                id: menuBarContent
                anchors.fill: parent
                appleActive: root.appleMenuOpened
                onAppleClicked: root.toggleAppleMenu()
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Item {
            id: statusAreaItem
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            implicitWidth:  statusAreaContent.implicitWidth
            implicitHeight: statusAreaContent.implicitHeight

            StatusArea {
                id: statusAreaContent
                anchors.fill: parent
                hostWindow:        root.hostWindow
                notifUnreadCount:  root.notifUnreadCount
                barWidth:          root.width
                onToggleCC:        root.toggleCC()
                onToggleSpotlight: root.toggleSpotlight()
                onToggleAI:        root.toggleAI()
                onToggleNotifCenter: root.toggleNotifCenter()
                onToggleWifi:      (x) => root.toggleWifi(x)
                onToggleBluetooth: (x) => root.toggleBluetooth(x)
                onToggleBattery:    (x) => root.toggleBattery(x)
                onToggleVolume:    (x) => root.toggleVolume(x)
            }
        }
    }

    readonly property bool notchIdle:      NotchState.visualState === "idle"
    readonly property bool notchPeek:      NotchState.visualState === "peek"
    readonly property bool notchExpanded:  NotchState.expanded
    readonly property bool notchDashboard: root.notchExpanded && !NotchState.hasUrgentActivity

    readonly property real notchTargetWidth: root.notchDashboard ? 620
                                            : root.notchExpanded   ? 440
                                            : root.notchPeek       ? Math.min(260, root.notchZoneRight - root.notchZoneLeft - 24)
                                                                    : 130
    readonly property real notchTargetHeight: root.notchDashboard ? 380
                                             : root.notchExpanded   ? 300
                                             : root.notchPeek       ? 40
                                                                     : 26

    Rectangle {
        id: notchPill
        readonly property real _safeHalfWidth: 65
        readonly property real notchCenterX: Math.max(root.notchZoneLeft + _safeHalfWidth,
                                                        Math.min(root.width / 2, root.notchZoneRight - _safeHalfWidth))
        x: notchCenterX - width / 2
        y: (root.themeHeight - 26) / 2
        width:  root.notchTargetWidth
        height: root.notchTargetHeight
        radius: root.notchExpanded ? 26 : height / 2
        color:  "#0A0A0A"

        Behavior on width  { NumberAnimation { duration: root._spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._spatialCurve } }
        Behavior on height { NumberAnimation { duration: root._spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._spatialCurve } }
        Behavior on radius { NumberAnimation { duration: root._spatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root._spatialCurve } }

        FadeLoader {
            anchors.fill: parent
            anchors.margins: 4
            shouldBeActive: !root.notchExpanded
            fadeDuration: root._effectsDuration
            fadeCurve: root._effectsCurve
            sourceComponent: NotchPill { peek: root.notchPeek }
        }

        FadeLoader {
            anchors.fill: parent
            anchors.margins: 16
            shouldBeActive: root.notchExpanded
            fadeDuration: root._effectsDuration
            fadeCurve: root._effectsCurve
            sourceComponent: NotchExpandedContent {}
        }

        MouseArea {
            anchors.fill: parent
            enabled: !root.notchExpanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: NotchState.setHovered(true)
            onExited:  NotchState.setHovered(false)
            onClicked: NotchState.toggleExpanded()
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
