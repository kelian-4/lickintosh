import QtQuick
import QtQuick.Layouts

// Calqué sur modules/dashboard/dash/DateTime.qml de caelestia (heure/
// minute empilées verticalement, séparateur "•••") — reconstruit avec
// JS Date + Timer puisqu'on n'a pas leur singleton "Time". Tailles
// agrandies pour correspondre à la maquette cible (gros chiffres).
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 84

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    function _pad(n) { return n < 10 ? "0" + n : String(n) }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._pad(root.now.getHours())
            color: "#C0C0C0"
            font.pixelSize: 34
            font.bold: true
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: "#FFFFFF"
            font.pixelSize: 20
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._pad(root.now.getMinutes())
            color: "#C0C0C0"
            font.pixelSize: 34
            font.bold: true
            font.family: "SF Pro Rounded"
        }
    }
}
