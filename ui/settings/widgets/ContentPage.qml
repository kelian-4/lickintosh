import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    id: root

    default property alias content: _col.data
    property string pageTitle: ""

    clip: true
    background: Item {}
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ScrollBar.vertical: ScrollBar {
        id: _vbar
        parent: root
        x: root.width - width
        width: 4
        policy: ScrollBar.AsNeeded

        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: "#50ffffff"
            opacity: _vbar.pressed ? 0.9 : (_vbar.hovered ? 0.7 : 0.0)
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        background: Item {}
    }

    ColumnLayout {
        id: _col
        width: root.width - 48
        x: 24
        y: 20
        spacing: 20
    }
}
