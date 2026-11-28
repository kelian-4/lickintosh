import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        IRow { icon: "settings/launchpad.svg"; title: I18n.tr("Installé"); subtitle: InstallerState.installed ? I18n.tr("Installé") : I18n.tr("Pas encore installé") }
        IRow {
            icon: "settings/update.svg"; title: I18n.tr("Canal de mise à jour")
            subtitle: I18n.tr("Suit la branche main (stable) ou dev (nightly). La mise à jour change de branche dans ce clone si besoin.")
                + (InstallerState.currentBranch !== "" ? " " + I18n.tr("Branche actuelle : %1").replace("%1", InstallerState.currentBranch) : "")
            IButton { main: InstallerState.branch === "main"; text: I18n.tr("Stable (main)"); enabled: !InstallerState.busy; onClicked: InstallerState.branch = "main" }
            IButton { main: InstallerState.branch === "dev"; text: I18n.tr("Nightly (dev)"); enabled: !InstallerState.busy; onClicked: InstallerState.branch = "dev" }
        }
        IRow {
            icon: "settings/update.svg"; title: I18n.tr("Mettre à jour depuis Git")
            subtitle: I18n.tr("Récupère les dernières modifications de ce clone puis les installe. L'ancienne version est sauvegardée avant (les 3 dernières sont gardées).")
            IButton { main: true; text: I18n.tr("Mettre à jour"); enabled: !InstallerState.busy; onClicked: InstallerState.requestRun("update") }
        }
        IRow {
            icon: "settings/dock.svg"; title: I18n.tr("Sauvegardes")
            subtitle: InstallerState.dataDir + "/backups"
            IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.dataDir + "/backups") }
        }
    }

    HyprConfirm { kind: "update" }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "update" }
    CFText { visible: InstallerState.notice !== "" && InstallerState.runKind === "update"; text: InstallerState.notice; font.pixelSize: 12; gray: true }
    LogView { viewHeight: 240 }
}
