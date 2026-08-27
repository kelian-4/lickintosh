import QtQuick
import QtQuick.Layouts
import qs.ui.primitives

Item {
    id: root
    property string pageTitle: ""
    property string icon: ""

    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        CFVI {
            Layout.alignment: Qt.AlignHCenter
            icon: root.icon.length > 0 ? root.icon : "settings/empty.svg"
            size: 48
            gray: true
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            text: root.pageTitle
            font.pixelSize: 16
            font.weight: Font.Bold
            color: "#fff"
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            text: "Bientôt disponible"
            font.pixelSize: 13
            gray: true
        }
    }
}
