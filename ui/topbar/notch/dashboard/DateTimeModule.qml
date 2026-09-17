import QtQuick
import QtQuick.Layouts

/*
    Port de modules/dashboard/dash/DateTime.qml (caelestia-dots/shell,
    GPLv3) : heure/minute en gros, séparateur "•••", chevauchement serré
    via des marges négatives (leur pattern exact : Layout.bottomMargin /
    topMargin = -(pointSize * 0.4)) plutôt qu'un simple spacing à 0.
    Rôles de couleur repris tels quels : heure/minute = m3secondary,
    séparateur = m3primary. Reconstruit avec JS Date + Timer (pas de
    singleton Time ici) ; secondes/AM-PM non repris (options de config
    absentes de ce depot).
*/
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 60

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    function _pad(n) { return n < 10 ? "0" + n : String(n) }

    readonly property int _fontPx: 28
    readonly property real _overlap: -(_fontPx * 0.4)

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: root._overlap
            text: root._pad(root.now.getHours())
            color: "#9AA0A6"
            font.pixelSize: root._fontPx
            font.bold: true
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: "#1C7AFF"
            font.pixelSize: root._fontPx * 0.9
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root._overlap
            text: root._pad(root.now.getMinutes())
            color: "#9AA0A6"
            font.pixelSize: root._fontPx
            font.bold: true
            font.family: "SF Pro Rounded"
        }
    }
}
