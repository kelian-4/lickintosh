import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
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
    property bool appleMenuOpened:  false
    property bool spotlightOpened:  false
    property int  notifUnreadCount: 0

    readonly property color themeBackground: "transparent"
    readonly property int   themeHeight:     32
    readonly property int   themeMargin:     20

    implicitHeight: themeHeight
    color:          themeBackground

    anchors.top:   parent.top
    anchors.left:  parent.left
    anchors.right: parent.right

    FontLoader {
        id: macFont
        source: "../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    readonly property real notchIdleWidth: 130
    readonly property real notchPeekWidth: 260
    readonly property bool notchPeek: NotchState.visualState === "peek"
    readonly property real notchPillWidth: root.notchPeek ? root.notchPeekWidth : root.notchIdleWidth

    readonly property real notchZoneLeft:  root.themeMargin + menuBarItem.width
    readonly property real notchZoneRight: root.width - root.themeMargin - statusAreaItem.width

    Binding {
        target: NotchState
        property: "topbarZoneWidth"
        value: root.notchZoneRight - root.notchZoneLeft
    }

    Binding {
        target: NotchState
        property: "screen"
        value: root.hostWindow ? root.hostWindow.screen : null
    }

    Binding {
        target: NotchState
        property: "anchorX"
        value: notchPillBg.x + notchPillBg.width / 2
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

    Rectangle {
        id: notchPillBg
        y: (root.height - height) / 2
        width: root.notchPillWidth
        height: 26
        radius: height / 2
        color: "#0A0A0A"
        visible: !NotchState.expanded
        x: {
            var ideal = (root.width - width) / 2
            return Math.max(root.notchZoneLeft, Math.min(ideal, root.notchZoneRight - width))
        }

        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        NotchPill {
            anchors.fill: parent
            peek: root.notchPeek
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: NotchState.setHovered(true)
            onExited:  NotchState.setHovered(false)
            onClicked: NotchState.toggleExpanded()
        }
    }
}
