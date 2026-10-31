import QtQuick

Item {
    id: root

    property var look: null
    readonly property color trackColor: root.look ? root.look.track : Qt.rgba(1, 1, 1, 0.14)
    readonly property color captionColor: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)
    property real percent: 0
    property color tint: "#30d158"
    property string caption: ""
    property real thickness: 9
    property int valueSize: 22

    onPercentChanged: canvas.requestPaint()
    onTintChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = Math.min(width, height) / 2 - root.thickness / 2
            var start = -Math.PI / 2
            ctx.lineWidth = root.thickness
            ctx.lineCap = "round"
            ctx.strokeStyle = root.trackColor
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()
            var fraction = Math.min(1, Math.max(0.001, root.percent / 100))
            ctx.strokeStyle = root.tint
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + Math.PI * 2 * fraction)
            ctx.stroke()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.percent) + "%"
            color: root.tint
            font.pixelSize: root.valueSize
            font.weight: Font.Bold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.caption !== ""
            text: root.caption
            color: root.captionColor
            font.pixelSize: Math.max(9, root.valueSize * 0.5)
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }
}
