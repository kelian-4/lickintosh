import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        IRow { title: I18n.tr("Installé"); subtitle: InstallerState.installed ? I18n.tr("Installé") : I18n.tr("Pas encore installé") }
        IRow {
            title: I18n.tr("Mettre à jour depuis Git")
            subtitle: I18n.tr("Récupère les dernières modifications de ce clone puis les installe. L'ancienne version est sauvegardée avant (les 3 dernières sont gardées).")
            IButton { main: true; text: I18n.tr("Mettre à jour"); enabled: !InstallerState.busy; onClicked: InstallerState.update() }
        }
        IRow {
            title: I18n.tr("Sauvegardes")
            subtitle: InstallerState.dataDir + "/backups"
            IButton { text: I18n.tr("Ouvrir"); onClicked: InstallerState.openPath(InstallerState.dataDir + "/backups") }
        }
    }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "update" }
    CFText { visible: InstallerState.notice !== "" && InstallerState.runKind === "update"; text: InstallerState.notice; font.pixelSize: 12; gray: true }
    LogView { viewHeight: 240 }
}
