import QtQuick
import QtQuick.Layouts
import qs.ui.primitives

Item {
    id: root

    property string text: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property string valueSuffix: ""
    property int decimals: 0
    signal moved(real value)

    Layout.fillWidth: true
    implicitHeight: _col.implicitHeight

    Column {
        id: _col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        RowLayout {
            width: parent.width

            CFText {
                text: root.text
                font.pixelSize: 14
                color: "#fff"
                Layout.fillWidth: true
            }

            CFText {
                text: root.value.toFixed(root.decimals) + root.valueSuffix
                font.pixelSize: 13
                gray: true
            }
        }

        CFSlider {
            width: parent.width
            value: (root.value - root.from) / (root.to - root.from)
            onMoved: {
                var real = root.from + value * (root.to - root.from)
                root.value = real
                root.moved(real)
            }
        }
    }
}
