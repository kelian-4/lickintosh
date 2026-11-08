import QtQuick

Canvas {
    id: wi

    property string kind: "laptop"
    property color color: "white"
    property real level: 2
    property bool flag: false

    width: 24
    height: 24

    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onLevelChanged: requestPaint()
    onFlagChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var c = getContext("2d")
        c.reset()
        var s = Math.min(width, height) / 18
        c.scale(s, s)
        var PI = Math.PI
        c.lineCap = "round"
        c.lineJoin = "round"
        var k = wi.kind
        if (k === "laptop") {
            c.strokeStyle = wi.color
            c.lineWidth = 1.4
            c.beginPath()
            c.rect(3.5, 4, 11, 7.6)
            c.stroke()
            c.beginPath()
            c.moveTo(1.5, 14)
            c.lineTo(16.5, 14)
            c.stroke()
        } else if (k === "headphones") {
            c.strokeStyle = wi.color
            c.lineWidth = 1.5
            c.beginPath()
            c.arc(9, 10, 6, PI, 0)
            c.stroke()
            c.fillStyle = wi.color
            c.fillRect(2.4, 10, 2.8, 5)
            c.fillRect(12.8, 10, 2.8, 5)
        } else if (k === "mouse") {
            c.strokeStyle = wi.color
            c.lineWidth = 1.4
            c.beginPath()
            c.moveTo(9, 2.5)
            c.arcTo(14, 2.5, 14, 8, 4.5)
            c.arcTo(14, 15.5, 9, 15.5, 4.5)
            c.arcTo(4, 15.5, 4, 8, 4.5)
            c.arcTo(4, 2.5, 9, 2.5, 4.5)
            c.stroke()
            c.beginPath()
            c.moveTo(9, 3)
            c.lineTo(9, 7)
            c.stroke()
        } else if (k === "bluetooth") {
            c.strokeStyle = wi.color
            c.lineWidth = 1.5
            c.beginPath()
            c.moveTo(5, 5.5)
            c.lineTo(13, 12.5)
            c.lineTo(9, 16)
            c.lineTo(9, 2)
            c.lineTo(13, 5.5)
            c.lineTo(5, 12.5)
            c.stroke()
            if (wi.flag) {
                c.beginPath()
                c.moveTo(2.5, 2.5)
                c.lineTo(15.5, 15.5)
                c.stroke()
            }
        } else if (k === "speaker") {
            c.strokeStyle = wi.color
            c.fillStyle = wi.color
            c.lineWidth = 1.5
            c.beginPath()
            c.moveTo(2.2, 7)
            c.lineTo(5.4, 7)
            c.lineTo(9.2, 3.6)
            c.lineTo(9.2, 14.4)
            c.lineTo(5.4, 11)
            c.lineTo(2.2, 11)
            c.closePath()
            c.fill()
            if (wi.level <= 0) {
                c.beginPath()
                c.moveTo(12, 6.8)
                c.lineTo(16, 11.2)
                c.moveTo(16, 6.8)
                c.lineTo(12, 11.2)
                c.stroke()
            } else {
                for (var i = 1; i <= Math.min(2, wi.level); i++) {
                    c.beginPath()
                    c.arc(9.2, 9, 1.4 + i * 3.0, -0.62, 0.62)
                    c.stroke()
                }
            }
        } else if (k === "moon") {
            c.fillStyle = wi.color
            c.beginPath()
            c.arc(9, 9, 6.8, 0, PI * 2)
            c.fill()
            c.globalCompositeOperation = "destination-out"
            c.beginPath()
            c.arc(12.2, 6.4, 5.6, 0, PI * 2)
            c.fill()
            c.globalCompositeOperation = "source-over"
        } else if (k === "reset") {
            c.strokeStyle = wi.color
            c.fillStyle = wi.color
            c.lineWidth = 1.6
            c.beginPath()
            c.arc(9, 9, 5.6, -PI * 0.55, PI * 1.2)
            c.stroke()
            c.beginPath()
            c.moveTo(3.2, 2.4)
            c.lineTo(3.2, 7.2)
            c.lineTo(8, 7.2)
            c.closePath()
            c.fill()
        } else {
            c.strokeStyle = wi.color
            c.lineWidth = 1.4
            c.beginPath()
            c.rect(3, 5, 12, 8)
            c.stroke()
        }
    }
}
