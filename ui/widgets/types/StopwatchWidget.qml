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
    readonly property color orange: "#ff9f0a"
    readonly property color fg: root.look ? root.look.primary : "white"
    readonly property color fg2: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)
    readonly property color btnTint: root.look && root.look.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.16)
    readonly property color btnInk: root.look && root.look.light ? Qt.rgba(0, 0, 0, 0.72) : "#ffffff"
    readonly property bool canReset: !StopwatchState.running && StopwatchState.elapsedMs > 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 4 * root.k

        Row {
            spacing: 5 * root.k
            ExtraBClockGlyph {
                anchors.verticalCenter: parent.verticalCenter
                kind: "stopwatch"
                color: root.orange
                width: 15 * root.k
                height: width
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Stopwatch")
                color: root.orange
                font.pixelSize: 14 * root.k
                font.weight: Font.DemiBold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 14
            text: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
            color: root.fg
            font.pixelSize: (root.isSmall ? 32 : 50) * root.k
            font.weight: Font.Light
            font.family: "SF Pro Text"
            font.features: { "tnum": 1 }
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: StopwatchState.running ? I18n.tr("Running") : I18n.tr("Paused")
            color: root.fg2
            font.pixelSize: 12 * root.k
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.k

            ExtraBRoundBtn {
                width: (root.isSmall ? 34 : 38) * root.k
                kind: StopwatchState.running ? "pause" : "play"
                tint: StopwatchState.running ? "#ff453a" : "#30d158"
                ink: "#ffffff"
                onClicked: StopwatchState.toggle()
            }

            ExtraBRoundBtn {
                visible: root.canReset
                width: (root.isSmall ? 34 : 38) * root.k
                kind: "reset"
                tint: root.btnTint
                ink: root.btnInk
                onClicked: StopwatchState.reset()
            }

            Item { Layout.fillWidth: true }
        }
    }
}
