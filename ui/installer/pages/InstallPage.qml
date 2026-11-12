import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        title: I18n.tr("État")
        IRow {
            title: I18n.tr("Dépendances")
            subtitle: InstallerState.planBusy ? I18n.tr("Vérification de ce qui est installé…")
                : !InstallerState.plan ? I18n.tr("Impossible de lire la liste des dépendances")
                : InstallerState.missing > 0 ? InstallerState.missing + " " + I18n.tr("paquet(s) manquant(s)")
                : I18n.tr("Tout ce dont Lickintosh a besoin est installé")
            IButton { visible: InstallerState.missing > 0; text: I18n.tr("Installer…"); onClicked: Qt.callLater(function() { InstallerState.requestPage("DependenciesPage") }) }
            IButton { text: I18n.tr("Revérifier"); enabled: !InstallerState.planBusy; onClicked: InstallerState.runPlan() }
        }
        IRow {
            title: "Lickintosh"
            subtitle: InstallerState.installed ? I18n.tr("Installé") : I18n.tr("Pas encore installé")
        }
    }

    ContentSection {
        title: I18n.tr("Options")
        ConfigSwitch {
            text: I18n.tr("Démarrer le shell à la fin")
            description: I18n.tr("Démarre ou redémarre Quickshell après la copie des fichiers")
            checked: InstallerState.optLaunch
            onToggled: v => InstallerState.optLaunch = v
        }
    }

    CFText {
        Layout.fillWidth: true
        text: I18n.tr("L'installation copie le shell, les polices, les icônes, le curseur et la configuration Hyprland. Les fichiers existants sont sauvegardés avant et tes réglages sont conservés.")
        font.pixelSize: 12
        gray: true
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        IButton {
            main: true
            enabled: !InstallerState.busy
            text: InstallerState.busy && InstallerState.runKind === "install" ? I18n.tr("Installation…") : (InstallerState.installed ? I18n.tr("Réinstaller Lickintosh") : I18n.tr("Installer Lickintosh"))
            onClicked: InstallerState.install()
        }
        CFText { text: InstallerState.notice; font.pixelSize: 12; gray: true; Layout.fillWidth: true; elide: Text.ElideRight }
    }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "install" }
    LogView { viewHeight: 220 }
}
