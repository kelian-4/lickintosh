import QtQuick

Item {
    id: root

    property real percent: 0
    property color ringColor: "#4ADE80"
    property real size: 72

    implicitWidth: root.size
    implicitHeight: root.size
    onPercentChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: "#2A2A2A"
        border.width: 6
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = width / 2 - 3
            var start = -Math.PI / 2
            var end = start + Math.PI * 2 * Math.min(1, Math.max(0, root.percent / 100))
            ctx.strokeStyle = root.ringColor
            ctx.lineWidth = 6
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, end)
            ctx.stroke()
        }
    }

    Text {
        anchors.centerIn: parent
        text: Math.round(root.percent) + "%"
        color: "#FFFFFF"
        font.pixelSize: 15
        font.bold: true
        font.family: "SF Pro Rounded"
    }
}
