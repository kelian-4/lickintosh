import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "m"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "Quote of the Day"
            color: "#bf5af2"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: QuoteState.today
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            verticalAlignment: root.size === "l" ? Text.AlignVCenter : Text.AlignTop
            color: "#ffffff"
            font.pixelSize: root.size === "l" ? 24 : 15
            font.weight: Font.Medium
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            visible: QuoteState.author !== ""
            text: "— " + QuoteState.author
            elide: Text.ElideRight
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 12
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }
}
