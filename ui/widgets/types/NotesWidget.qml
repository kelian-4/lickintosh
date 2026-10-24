import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "s"
    readonly property int visibleCount: root.size === "l" ? 5 : (root.size === "m" ? 2 : 1)
    readonly property var shown: NotesState.notes.slice(0, root.visibleCount)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "Notes"
            color: "#ffd60a"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            visible: root.shown.length === 0
            text: "No Notes"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.shown

            delegate: Text {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: root.size === "s"
                text: modelData.text
                wrapMode: Text.Wrap
                maximumLineCount: root.size === "s" ? 5 : (root.size === "m" ? 2 : 3)
                elide: Text.ElideRight
                color: "#ffffff"
                font.pixelSize: 13
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }

        Item { Layout.fillHeight: true }
    }
}
