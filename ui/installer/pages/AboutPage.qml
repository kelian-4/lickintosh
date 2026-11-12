import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        Item {
            Layout.fillWidth: true
            implicitHeight: 130
            CFVI { anchors.horizontalCenter: parent.horizontalCenter; y: 8; icon: "logo.svg"; size: 76; colorized: false }
            CFText { y: 92; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: I18n.tr("Installateur Lickintosh"); font.pixelSize: 17; font.weight: Font.DemiBold; color: Theme.textPrimary }
            CFText { y: 114; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: InstallerState.installed ? I18n.tr("Installé") : I18n.tr("Pas encore installé"); font.pixelSize: 12; gray: true }
        }
    }

    ContentSection {
        IRow { title: I18n.tr("Script d'installation"); subtitle: InstallerState.script }
        IRow { title: I18n.tr("Projet"); subtitle: InstallerState.projectUrl; IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.projectUrl) } }
        IRow { title: I18n.tr("Sauvegardes"); subtitle: InstallerState.dataDir + "/backups"; IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.dataDir + "/backups") } }
    }

    CFText {
        Layout.fillWidth: true
        text: I18n.tr("Cette fenêtre pilote setup.fish : installation, mise à jour, diagnostic et désinstallation exécutent le même code que le terminal.")
        font.pixelSize: 12
        gray: true
        wrapMode: Text.WordWrap
    }
}
