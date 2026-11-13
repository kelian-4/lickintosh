import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property var look: null

    property string size: "m"

    readonly property real k: Math.min(root.width / 330, root.height / (root.size === "l" ? 326 : 140))
    readonly property bool isLarge: root.size === "l"
    readonly property color accent: "#bf5af2"
    readonly property color fg: root.look ? root.look.primary : "white"
    readonly property color fg2: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8 * root.k

        Row {
            spacing: 5 * root.k
            ExtraBClockGlyph {
                anchors.verticalCenter: parent.verticalCenter
                kind: "quote"
                color: root.accent
                width: 15 * root.k
                height: width
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Quote of the Day")
                color: root.accent
                font.pixelSize: 14 * root.k
                font.weight: Font.DemiBold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: QuoteState.today
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            verticalAlignment: root.isLarge ? Text.AlignVCenter : Text.AlignTop
            color: root.fg
            font.pixelSize: (root.isLarge ? 28 : 17) * root.k
            font.weight: Font.Medium
            font.family: "SF Pro Display"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            visible: QuoteState.author !== ""
            text: "— " + QuoteState.author
            elide: Text.ElideRight
            color: root.fg2
            font.pixelSize: 13 * root.k
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }
}
