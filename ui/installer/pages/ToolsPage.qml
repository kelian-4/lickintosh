import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        title: "Lickintosh"
        IRow { title: I18n.tr("Démarrer"); subtitle: I18n.tr("Lance le shell dans ta session Hyprland"); IButton { main: true; text: I18n.tr("Démarrer"); onClicked: InstallerState.startShell() } }
        IRow { title: I18n.tr("Redémarrer"); subtitle: I18n.tr("Arrête le shell puis le relance"); IButton { text: I18n.tr("Redémarrer"); onClicked: InstallerState.restartShell() } }
        IRow { title: I18n.tr("Arrêter"); subtitle: I18n.tr("Quitte le shell en cours"); IButton { text: I18n.tr("Arrêter"); destructive: true; onClicked: InstallerState.stopShell() } }
        IRow { title: I18n.tr("Écran de verrouillage"); subtitle: I18n.tr("Essayer l'écran de verrouillage"); IButton { text: I18n.tr("Verrouiller"); onClicked: InstallerState.lockScreen() } }
    }

    ContentSection {
        title: I18n.tr("Configuration")
        IRow { title: I18n.tr("Dossier de configuration Hyprland"); IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.home + "/.config/hypr") } }
        IRow { title: I18n.tr("Dossier du shell"); subtitle: "~/.config/quickshell/lickintosh"; IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.shellInstallDir) } }
        IRow { title: I18n.tr("Sauvegardes"); subtitle: I18n.tr("Où les mises à jour et la désinstallation gardent les anciennes versions"); IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.dataDir + "/backups") } }
    }
}
