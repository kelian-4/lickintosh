import QtQuick

Item {
    id: root

    property var values: []
    property color lineColor: "#1C7AFF"

    implicitWidth: 120
    implicitHeight: 56
    onValuesChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#141414"
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 4
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var v = root.values
            if (v.length < 2) return
            var step = width / (v.length - 1)
            ctx.beginPath()
            for (var i = 0; i < v.length; i++) {
                var x = i * step
                var y = height - height * Math.min(1, Math.max(0, v[i] / 100))
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.strokeStyle = root.lineColor
            ctx.lineWidth = 1.5
            ctx.lineJoin = "round"
            ctx.stroke()
        }
    }
}
