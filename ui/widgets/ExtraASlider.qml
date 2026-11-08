import QtQuick

Item {
    id: s

    property real value: 0
    property real u: 1
    property color fillColor: "white"
    property color trackColor: Qt.rgba(1, 1, 1, 0.20)
    property color knobColor: "white"
    signal moved(real v)

    height: 22 * s.u
    opacity: enabled ? 1 : 0.4

    readonly property real trackX: 14 * s.u
    readonly property real trackW: Math.max(1, s.width - 28 * s.u)
    readonly property real pos: Math.max(0, Math.min(1, s.value))
    readonly property real cy: s.height / 2

    property real hoverT: ma.containsMouse || ma.pressed ? 1 : 0
    Behavior on hoverT { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
    property real pressT: ma.pressed ? 1 : 0
    Behavior on pressT { NumberAnimation { duration: ma.pressed ? 420 : 300; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }

    property real shownPos: s.pos
    Behavior on shownPos { enabled: !ma.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        x: s.trackX
        y: s.cy - height / 2
        width: s.trackW
        height: 5 * s.u
        radius: height / 2
        color: s.trackColor
    }

    Rectangle {
        x: s.trackX
        y: s.cy - height / 2
        width: s.shownPos * s.trackW
        height: 5 * s.u
        radius: height / 2
        color: s.fillColor
    }

    Rectangle {
        id: knob
        width: (25 + 7 * s.pressT) * s.u
        height: (17 + 3 * s.pressT) * s.u
        radius: Math.min(height / 2, (9 + 3 * s.pressT) * s.u)
        x: s.trackX + s.shownPos * s.trackW - width / 2
        y: s.cy - height / 2
        scale: 1 + 0.08 * Math.min(1.3, s.hoverT)
        color: s.knobColor
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.08)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function setFrom(mx) {
            s.moved(Math.max(0, Math.min(1, (mx - s.trackX) / s.trackW)))
        }
        onPressed: function(mouse) { ma.setFrom(mouse.x) }
        onPositionChanged: function(mouse) {
            if (pressed) ma.setFrom(mouse.x)
        }
    }
}
