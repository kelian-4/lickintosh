import QtQuick

Rectangle {
    id: root

    property string kind: "play"
    property color tint: Qt.rgba(1, 1, 1, 0.16)
    property color ink: "#ffffff"
    property real glyphScale: 0.46
    signal clicked()

    width: 30
    height: width
    radius: width / 2
    color: root.tint
    scale: area.pressed ? 0.9 : 1
    opacity: area.pressed ? 0.8 : 1

    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
    Behavior on opacity { NumberAnimation { duration: 120 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    Canvas {
        id: glyph
        anchors.centerIn: parent
        width: root.width * root.glyphScale
        height: width
        antialiasing: true
        property string kind: root.kind
        property color ink: root.ink
        onKindChanged: requestPaint()
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var c = getContext("2d")
            c.reset()
            var s = width / 20
            c.scale(s, s)
            c.fillStyle = ink
            c.strokeStyle = ink
            c.lineCap = "round"
            c.lineJoin = "round"
            if (kind === "play") {
                c.beginPath()
                c.moveTo(5, 2.5)
                c.lineTo(17, 10)
                c.lineTo(5, 17.5)
                c.closePath()
                c.fill()
            } else if (kind === "pause") {
                c.beginPath(); c.roundedRect(3.5, 2.5, 4.6, 15, 1.4, 1.4); c.fill()
                c.beginPath(); c.roundedRect(11.9, 2.5, 4.6, 15, 1.4, 1.4); c.fill()
            } else if (kind === "stop") {
                c.beginPath(); c.roundedRect(3.5, 3.5, 13, 13, 2.6, 2.6); c.fill()
            } else if (kind === "close") {
                c.lineWidth = 2.6
                c.beginPath(); c.moveTo(4, 4); c.lineTo(16, 16); c.stroke()
                c.beginPath(); c.moveTo(16, 4); c.lineTo(4, 16); c.stroke()
            } else if (kind === "reset") {
                c.lineWidth = 2.4
                c.beginPath(); c.arc(10, 10, 6.8, -Math.PI * 0.35, Math.PI * 1.3); c.stroke()
                c.beginPath(); c.moveTo(13.6, 0.8); c.lineTo(13.6, 6.6); c.lineTo(8.2, 4.2); c.closePath(); c.fill()
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -3
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
