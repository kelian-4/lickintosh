import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        IRow {
            title: I18n.tr("Vérifier l'installation")
            subtitle: I18n.tr("Examine la session, Hyprland, Quickshell, les modules QML, les outils, les services, l'installation et le dernier journal de démarrage, et explique ce qui ne va pas.")
            IButton { text: I18n.tr("Ouvrir le journal"); onClicked: InstallerState.openPath(InstallerState.stateDir + "/shell.log") }
            IButton { main: true; text: InstallerState.busy && InstallerState.runKind === "doctor" ? I18n.tr("Vérification…") : I18n.tr("Lancer le diagnostic"); enabled: !InstallerState.busy; onClicked: InstallerState.doctor() }
        }
    }

    BarProgress { running: InstallerState.busy && InstallerState.runKind === "doctor" }
    LogView { viewHeight: 380 }
}
