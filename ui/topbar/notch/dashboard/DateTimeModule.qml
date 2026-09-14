import QtQuick
import QtQuick.Layouts

// Calqué sur modules/dashboard/dash/DateTime.qml de caelestia (heure/
// minute empilées verticalement, séparateur "•••") — reconstruit avec
// JS Date + Timer puisqu'on n'a pas leur singleton "Time".
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 64

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    function _pad(n) { return n < 10 ? "0" + n : String(n) }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._pad(root.now.getHours())
            color: "#B0B0B0"
            font.pixelSize: 22
            font.bold: true
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: "#FFFFFF"
            font.pixelSize: 14
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._pad(root.now.getMinutes())
            color: "#B0B0B0"
            font.pixelSize: 22
            font.bold: true
            font.family: "SF Pro Rounded"
        }
    }
}
