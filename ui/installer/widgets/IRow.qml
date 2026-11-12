import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias trailing: _trailing.data

    Layout.fillWidth: true
    spacing: 12

    Column {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 2

        CFText {
            width: parent.width
            text: root.title
            font.pixelSize: 14
            color: Theme.textPrimary
            elide: Text.ElideRight
        }

        CFText {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }
    }

    Row {
        id: _trailing
        spacing: 8
        Layout.alignment: Qt.AlignVCenter
    }
}
