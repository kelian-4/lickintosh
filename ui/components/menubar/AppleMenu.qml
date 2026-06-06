import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../glass"

Item {
    id: root

    property bool opened: false
    signal closeRequested()
    signal openAbout()

    readonly property int menuWidth: 220
    readonly property int rowHeight: 38
    readonly property color hoverColor: Qt.rgba(0.22, 0.42, 0.88, 0.85)
    readonly property color sepColor:   Qt.rgba(1, 1, 1, 0.10)
    readonly property color textColor:  "#FFFFFF"
    readonly property color dimColor:   Qt.rgba(1, 1, 1, 0.35)

    implicitWidth:  menuWidth
    implicitHeight: menuCol.implicitHeight + 8

    Process { id: _suspend;  command: ["systemctl", "suspend"];  running: false }
    Process { id: _reboot;   command: ["systemctl", "reboot"];   running: false }
    Process { id: _poweroff; command: ["systemctl", "poweroff"]; running: false }
    Process { id: _exit;     command: ["sh", "-c", "hyprctl dispatch 'hl.dsp.exit()'"]; running: false }
    Process { id: _kill;     command: ["sh", "-c", "hyprctl kill"];          running: false }

    // ── Fond BoxGlass ────────────────────────────────────────────
    BoxGlass {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.08, 0.08, 0.08, 0.55)
        light: Qt.rgba(1, 1, 1, 0.18)
        rimStrength: 0.5
        highlightEnabled: true
        lightDir: Qt.vector2d(0.5, -1.0)
    }

    // ── Composants internes ──────────────────────────────────────

    component MenuRow: Item {
        id: _mr
        property string label: ""
        property string shortcut: ""
        property bool dimmed: false
        signal activated()

        height: root.rowHeight
        width: root.menuWidth

        property bool _hovered: false

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            radius: 6
            color: _mr._hovered && !_mr.dimmed ? root.hoverColor : "transparent"
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.label
            color: _mr.dimmed ? root.dimColor : root.textColor
            font.pixelSize: 13
            renderType: Text.NativeRendering
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.shortcut
            color: Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 12
            renderType: Text.NativeRendering
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
        width: root.menuWidth
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: root.sepColor
    }

    // ── Contenu ──────────────────────────────────────────────────
    Column {
        id: menuCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 4

        MenuRow {
            label: "About this PC"
            onActivated: {
                root.openAbout()
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            label: "System Settings…"
            dimmed: true
        }
        MenuRow {
            label: "App Store"
            dimmed: true
        }

        MenuSep {}

        MenuRow {
            label: "Recent Items"
            dimmed: true
        }

        MenuSep {}

        MenuRow {
            label: "Force Quit…"
            shortcut: "⌥⌘⎋"
            onActivated: _kill.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Sleep"
            onActivated: _suspend.running = true
        }
        MenuRow {
            label: "Restart…"
            onActivated: _reboot.running = true
        }
        MenuRow {
            label: "Shut Down…"
            onActivated: _poweroff.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Log Out…"
            shortcut: "⇧⌘Q"
            onActivated: _exit.running = true
        }

        MenuSep {}

        MenuRow {
            label: "Lock Screen"
            shortcut: "⌃⌘Q"
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