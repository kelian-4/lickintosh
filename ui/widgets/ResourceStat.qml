import QtQuick

Row {
    id: root

    property string label: ""
    property string value: ""
    property color tint: "#ffffff"
    property real labelWidth: 52

    spacing: 6

    Text {
        width: root.labelWidth
        text: root.label
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pixelSize: 11
        font.family: "SF Pro Text"
        renderType: Text.NativeRendering
    }

    Text {
        text: root.value
        color: root.tint
        font.pixelSize: 12
        font.weight: Font.Bold
        font.family: "SF Pro Text"
        renderType: Text.NativeRendering
    }
}
