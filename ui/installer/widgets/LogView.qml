import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.components
import qs.components.glass
import qs.services

BoxGlass {
    id: root

    property int viewHeight: 240

    Layout.fillWidth: true
    implicitHeight: root.viewHeight
    radius: 14
    color: Theme.card
    light: Theme.cardRim
    rimStrength: 0.8

    function kindColor(k) {
        return k === "ok" ? "#30D158" : k === "warn" ? "#FF9F0A" : k === "step" ? Theme.textPrimary : (k === "dim" ? Theme.textTertiary : Theme.textSecondary)
    }

    CFText {
        anchors.centerIn: parent
        visible: InstallerState.logEmpty
        text: I18n.tr("La sortie s'affiche ici")
        font.pixelSize: 12
        gray: true
    }

    ListView {
        id: _list
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        spacing: 2
        model: InstallerState.logLines
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

        delegate: Text {
            required property var modelData
            width: _list.width - 8
            text: modelData.text
            wrapMode: Text.WrapAnywhere
            font.family: "monospace"
            font.pixelSize: 12
            font.weight: modelData.kind === "step" ? Font.Bold : Font.Normal
            color: root.kindColor(modelData.kind)
        }

        onCountChanged: Qt.callLater(function() { _list.positionViewAtEnd() })
    }
}
