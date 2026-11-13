import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        IRow { icon: "settings/general.svg"; title: I18n.tr("Script d'installation"); subtitle: InstallerState.script }
        IRow { icon: "settings/network.svg"; title: I18n.tr("Projet"); subtitle: InstallerState.projectUrl; IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.projectUrl) } }
        IRow { icon: "settings/dock.svg"; title: I18n.tr("Sauvegardes"); subtitle: InstallerState.dataDir + "/backups"; IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.dataDir + "/backups") } }
    }

    CFText {
        Layout.fillWidth: true
        text: I18n.tr("Cette fenêtre pilote setup.fish : installation, mise à jour, diagnostic et désinstallation exécutent le même code que le terminal.")
        font.pixelSize: 12
        gray: true
        wrapMode: Text.WordWrap
    }
}
