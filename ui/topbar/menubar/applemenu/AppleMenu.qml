import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.ui.glass

Item {
    id: root

    property bool opened: false
    signal closeRequested()
    signal openAbout()

    readonly property int menuWidth: 260
    readonly property int rowHeight: 30
    readonly property color hoverColor: Qt.rgba(1, 1, 1, 0.9)
    readonly property color sepColor:   Qt.rgba(1, 1, 1, 0.10)
    readonly property color textColor:  "#FFFFFF"
    readonly property color hoverTextColor: "#000000"
    readonly property color dimColor:   Qt.rgba(1, 1, 1, 0.35)

    implicitWidth:  menuWidth
    implicitHeight: menuCol.implicitHeight + 12

    Process { id: _suspend;  command: ["systemctl", "suspend"];  running: false }
    Process { id: _reboot;   command: ["systemctl", "reboot"];   running: false }
    Process { id: _poweroff; command: ["systemctl", "poweroff"]; running: false }
    Process { id: _exit;     command: ["sh", "-c", "hyprctl dispatch 'hl.dsp.exit()'"]; running: false }
    Process { id: _kill;     command: ["sh", "-c", "hyprctl kill"];          running: false }

    
    BoxGlass {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(0.08, 0.08, 0.08, 0.75)
        rimStrength: 1.7
        light: "#20ffffff"
    }

    

    component MenuRow: Item {
        id: _mr
        property string label: ""
        property string shortcut: ""
        property string icon: ""
        property bool dimmed: false
        property bool hasSub: false
        signal activated()

        height: root.rowHeight
        width: root.menuWidth

        property bool _hovered: false

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            radius: 5
            color: _mr._hovered && !_mr.dimmed ? root.hoverColor : "transparent"
        }

        VectorImage {
            id: _icon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: _mr.icon !== "" ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + _mr.icon) : ""
            visible: _mr.icon !== ""
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: _mr._hovered ? "#000000" : "#FFFFFF"
            }
        }

        Text {
            anchors.left: _mr.icon !== "" ? _icon.right : parent.left
            anchors.leftMargin: _mr.icon !== "" ? 10 : 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.label
            color: _mr.dimmed ? root.dimColor : (_mr._hovered ? root.hoverTextColor : root.textColor)
            font.pixelSize: 13
            renderType: Text.NativeRendering
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.shortcut
            color: _mr._hovered ? root.hoverTextColor : Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 12
            renderType: Text.NativeRendering
            visible: !_mr.hasSub
        }

        VectorImage {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/chevron-right.svg")
            visible: _mr.hasSub
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: _mr._hovered ? "#000000" : "#FFFFFF"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: _mr.dimmed ? Qt.ArrowCursor : Qt.PointingHandCursor
            onEntered: _mr._hovered = true
            onExited:  _mr._hovered = false
            onClicked: if (!_mr.dimmed) _mr.activated()
        }
    }

    component MenuSep: Rectangle {
        height: 1
        width: root.menuWidth - 20
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.sepColor
    }

    
    Column {
        id: menuCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 6
        spacing: 2

        MenuRow {
            label: "About this Mac"
            icon: "dropdown/mac.svg"
            onActivated: {
                root.openAbout()
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            label: "System Settings…"
            icon: "dropdown/settings.svg"
            dimmed: true
        }
        MenuRow {
            label: "App Store"
            icon: "dropdown/store.svg"
            dimmed: true
        }

        MenuSep {}

        MenuRow {
            label: "Recent Items"
            icon: "dropdown/clock.svg"
            hasSub: true
            dimmed: true
        }

        MenuSep {}

        MenuRow {
            label: "Force Quit…"
            icon: "notch/x-circle.svg"
            shortcut: "⇧⌘⌫"
            onActivated: _kill.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Sleep"
            icon: "dropdown/sleep.svg"
            onActivated: _suspend.running = true
        }
        MenuRow {
            label: "Restart…"
            icon: "dropdown/reload.svg"
            onActivated: _reboot.running = true
        }
        MenuRow {
            label: "Shut Down…"
            icon: "dropdown/power.svg"
            onActivated: _poweroff.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Log Out…"
            icon: "notch/log-out.svg"
            onActivated: _exit.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Lock Screen"
            icon: "dropdown/lock.svg"
            shortcut: "⌃⌘L"
            dimmed: true
        }

        Item { height: 4; width: 1 }
    }

    opacity: opened ? 1 : 0
    scale:   opened ? 1 : 0.95
    transformOrigin: Item.TopLeft

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
}