import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"

    readonly property bool isSmall: root.size === "s"
    readonly property real u: root.height / 158
    readonly property real pad: 16 * root.u
    readonly property var loc: Qt.locale(I18n.lang)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 0

        Item { Layout.fillHeight: true }

        Text {
            id: timeText

            readonly property real xs: 0.94
            readonly property real ys: 1.14

            Layout.fillWidth: true
            Layout.preferredHeight: root.u * (root.isSmall ? 50 : 76)

            text: root.loc.toString(clock.date, "HH:mm")
            color: root.look ? root.look.primary : "white"
            opacity: 0.96

            font.family: "SF Pro Display"
            font.pixelSize: root.u * (root.isSmall ? 50 : 76)
            font.weight: Font.DemiBold
            font.letterSpacing: -2.2 * root.u
            font.features: { "tnum": 1 }

            renderType: Text.QtRendering
            antialiasing: true

            transform: Scale {
                origin.x: 0
                origin.y: timeText.height / 2
                xScale: timeText.xs
                yScale: timeText.ys
            }

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPixelSize: 10
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4 * root.u

            text: root.loc.toString(clock.date, root.isSmall ? I18n.tr("ddd d MMM") : I18n.tr("dddd d MMMM"))
            color: "#5e5ce6"
            elide: Text.ElideRight
            maximumLineCount: 1

            font.pixelSize: root.u * (root.isSmall ? 14 : 17)
            font.weight: Font.DemiBold
            font.family: "SF Pro Text"
            font.letterSpacing: 0.2 * root.u
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }
    }
}
