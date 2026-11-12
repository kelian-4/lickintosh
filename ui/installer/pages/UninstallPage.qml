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
            subtitle: root.confirming ? I18n.tr("Lickintosh est déplacé dans le dossier des sauvegardes. Tes réglages sont conservés.") : I18n.tr("Déplace le shell dans le dossier des sauvegardes. Les polices, les icônes et le curseur restent en place.")
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
        text: I18n.tr("Tes réglages sont conservés : réinstaller remet tout en place. La configuration Hyprland n'est pas modifiée.")
        font.pixelSize: 12
        gray: true
        wrapMode: Text.WordWrap
    }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "uninstall" }
    CFText { visible: InstallerState.notice !== "" && InstallerState.runKind === "uninstall"; text: InstallerState.notice; font.pixelSize: 12; gray: true }
    LogView { viewHeight: 240 }
}
