import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    property bool confirming: false

    ContentSection {
        IRow {
            icon: "settings/dock.svg"; title: I18n.tr("Désinstaller Lickintosh")
            subtitle: root.confirming ? I18n.tr("Tout ce que Lickintosh a créé est supprimé définitivement, y compris tes réglages.") : I18n.tr("Supprime absolument tout ce que Lickintosh a installé ou créé : shell, réglages, polices, icônes, curseur, caches et configuration Hyprland.")
            IButton { visible: root.confirming; text: I18n.tr("Annuler"); onClicked: root.confirming = false }
            IButton {
                text: root.confirming ? I18n.tr("Désinstaller") : I18n.tr("Désinstaller…")
                destructive: true
                enabled: !InstallerState.busy
                onClicked: { if (root.confirming) { root.confirming = false; InstallerState.uninstall() } else root.confirming = true }
            }
        }
    }

    CFText {
        Layout.fillWidth: true
        text: I18n.tr("Action définitive : les réglages du shell sont aussi supprimés. Les sauvegardes de ta configuration Hyprland et des réglages système sont restaurées si elles existent.")
        font.pixelSize: 12
        gray: true
        wrapMode: Text.WordWrap
    }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "uninstall" }
    CFText { visible: InstallerState.notice !== "" && InstallerState.runKind === "uninstall"; text: InstallerState.notice; font.pixelSize: 12; gray: true }
    LogView { viewHeight: 240 }
}
