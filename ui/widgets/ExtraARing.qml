import QtQuick

Item {
    id: root

    property real percent: 0
    property color tint: "#30d158"
    property color trackColor: Qt.rgba(1, 1, 1, 0.16)
    property color inkColor: "white"
    property real lineWidth: 5
    property string glyph: ""
    property real glyphSize: 22
    property bool charging: false
    property bool showValue: true
    property string valueText: ""
    property real valueSize: 14
    property string fam: "SF Pro Text"

    property real shown: root.percent
    Behavior on shown { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    onShownChanged: canvas.requestPaint()
    onTintChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d")
            c.reset()
            var r = Math.min(width, height) / 2 - root.lineWidth / 2
            var cx = width / 2
            var cy = height / 2
            c.lineWidth = root.lineWidth
            c.lineCap = "round"
            c.strokeStyle = root.trackColor
            c.beginPath()
            c.arc(cx, cy, r, 0, Math.PI * 2)
            c.stroke()
            var f = Math.max(0, Math.min(1, root.shown / 100))
            if (f <= 0) return
            c.strokeStyle = root.tint
            c.beginPath()
            c.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * f)
            c.stroke()
        }
    }

    ExtraAGlyph {
        visible: root.glyph !== ""
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.charging ? -root.glyphSize * 0.18 : 0
        width: root.glyphSize
        height: root.glyphSize
        kind: root.glyph
        color: root.inkColor
    }

    Text {
        visible: root.glyph !== "" && root.charging
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.glyphSize * 0.6
        text: "⚡"
        color: root.tint
        font.family: root.fam
        font.pixelSize: root.glyphSize * 0.46
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.glyph === "" && root.showValue
        anchors.centerIn: parent
        text: root.valueText !== "" ? root.valueText : Math.round(root.percent) + "%"
        color: root.inkColor
        font.family: root.fam
        font.pixelSize: root.valueSize
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }
}
