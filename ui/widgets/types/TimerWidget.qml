import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property var look: null

    property string size: "s"

    readonly property real k: Math.min(root.width / (root.size === "s" ? 140 : 330), root.height / 140)
    readonly property bool isSmall: root.size === "s"
    readonly property bool paused: !TimerState.running && TimerState.remainingAtPauseMs > 0
    readonly property bool active: TimerState.running || root.paused
    readonly property var presets: root.isSmall ? [5] : [1, 5, 10, 25]
    readonly property color orange: "#ff9f0a"
    readonly property color fg: root.look ? root.look.primary : "white"
    readonly property color fg2: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)
    readonly property color btnTint: root.look && root.look.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.16)
    readonly property color btnInk: root.look && root.look.light ? Qt.rgba(0, 0, 0, 0.72) : "#ffffff"
    readonly property real frac: TimerState.totalMs > 0 ? Math.max(0, Math.min(1, TimerState.remainingMs / TimerState.totalMs)) : 0
    readonly property string timeText: TimerState.firing ? I18n.tr("Done") : (root.active ? TimerState.formatRemaining(TimerState.remainingMs) : "0:00")

    component Head: Row {
        spacing: 5 * root.k
        ExtraBClockGlyph {
            anchors.verticalCenter: parent.verticalCenter
            kind: "timer"
            color: root.orange
            width: 15 * root.k
            height: width
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Timer")
            color: root.orange
            font.pixelSize: 14 * root.k
            font.weight: Font.DemiBold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }

    component Ring: Canvas {
        id: ring
        property real f: root.frac
        property color ink: root.orange
        property color track: root.look && root.look.light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.18)
        antialiasing: true
        Behavior on f { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
        onFChanged: requestPaint()
        onInkChanged: requestPaint()
        onTrackChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var c = getContext("2d")
            c.reset()
            var lw = width * 0.07
            var r = width / 2 - lw / 2
            c.lineWidth = lw
            c.lineCap = "round"
            c.strokeStyle = track
            c.beginPath()
            c.arc(width / 2, height / 2, r, 0, Math.PI * 2)
            c.stroke()
            c.strokeStyle = ink
            c.beginPath()
            c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.0001, f))
            c.stroke()
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeText
                color: TimerState.firing ? root.orange : root.fg
                font.pixelSize: ring.width * 0.2
                font.weight: Font.Medium
                font.family: "SF Pro Text"
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.paused ? I18n.tr("Paused") : I18n.tr("Timer")
                color: root.fg2
                font.pixelSize: Math.max(9, ring.width * 0.085)
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.active && !TimerState.firing

        Item {
            id: ringBox
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: root.isSmall ? parent.horizontalCenter : undefined
            width: root.isSmall ? parent.width : parent.height

            Ring {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 4 * root.k
                height: width
            }
        }

        Column {
            visible: !root.isSmall
            anchors.left: ringBox.right
            anchors.leftMargin: 16 * root.k
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10 * root.k

            Head {}

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: TimerState.formatRemaining(TimerState.remainingMs)
                color: root.fg
                font.pixelSize: 40 * root.k
                font.weight: Font.Light
                font.family: "SF Pro Text"
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
            }

            Row {
                spacing: 10 * root.k
                ExtraBRoundBtn {
                    width: 36 * root.k
                    kind: TimerState.running ? "pause" : "play"
                    tint: root.orange
                    ink: "#ffffff"
                    onClicked: TimerState.running ? TimerState.pause() : TimerState.resume()
                }
                ExtraBRoundBtn {
                    width: 36 * root.k
                    kind: "close"
                    tint: root.btnTint
                    ink: root.btnInk
                    onClicked: TimerState.cancel()
                }
            }
        }

        Row {
            visible: root.isSmall
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 5 * root.k
            ExtraBRoundBtn {
                width: 22 * root.k
                kind: TimerState.running ? "pause" : "play"
                tint: root.orange
                ink: "#ffffff"
                onClicked: TimerState.running ? TimerState.pause() : TimerState.resume()
            }
            ExtraBRoundBtn {
                width: 22 * root.k
                kind: "close"
                tint: root.btnTint
                ink: root.btnInk
                onClicked: TimerState.cancel()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: !root.active || TimerState.firing
        spacing: 4 * root.k

        Head {}

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.timeText
            color: TimerState.firing ? root.orange : root.fg
            font.pixelSize: (root.isSmall ? 38 : 50) * root.k
            font.weight: Font.Light
            font.family: "SF Pro Text"
            font.features: { "tnum": 1 }
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * root.k

            WidgetButton {
                look: root.look
                visible: TimerState.firing
                text: I18n.tr("OK")
                tint: root.orange
                onClicked: TimerState.dismissFiring()
            }

            Repeater {
                model: !root.active && !TimerState.firing ? root.presets : []

                delegate: WidgetButton {
                    look: root.look
                    required property int modelData
                    text: modelData + " min"
                    onClicked: TimerState.start(modelData * 60000)
                }
            }
        }
    }
}
