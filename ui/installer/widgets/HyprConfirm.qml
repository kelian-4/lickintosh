import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    property string kind: ""

    Layout.fillWidth: true
    visible: InstallerState.pendingRun === root.kind
    implicitHeight: _col.implicitHeight + 24
    radius: 10
    color: "#14ffffff"
    border.color: "#1Affffff"
    border.width: 1

    ColumnLayout {
        id: _col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        CFText {
            text: I18n.tr("Remplacer ta configuration Hyprland ?")
            font.pixelSize: 13
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        CFText {
            text: I18n.tr("Les raccourcis clavier de ~/.config/hypr seront remplacés par ceux de Lickintosh. Une sauvegarde est faite avant.")
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 8
            IButton { main: true; text: I18n.tr("Remplacer"); onClicked: InstallerState.confirmRun(false) }
            IButton { text: I18n.tr("Conserver la mienne"); onClicked: InstallerState.confirmRun(true) }
            IButton { text: I18n.tr("Annuler"); onClicked: InstallerState.cancelRun() }
        }
    }
}
