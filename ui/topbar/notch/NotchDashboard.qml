import QtQuick
import QtQuick.Layouts
import qs.ui.topbar.notch.dashboard

// Hub affiché par défaut en état "expanded" : 4 onglets calqués sur
// caelestia-dots/shell (modules/dashboard/, GPLv3) — Dashboard, Media,
// Performance, Weather. Pas de bouton fermer : ça se ferme au clic
// extérieur (HyprlandFocusGrab, cf. Notch.qml) ou à l'Échap.
ColumnLayout {
    id: root
    spacing: 8

    NotchTabBar {
        id: tabBar
        Layout.fillWidth: true
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: {
            switch (tabBar.currentIndex) {
                case 1:  return mediaComp
                case 2:  return performanceComp
                case 3:  return weatherComp
                default: return dashboardComp
            }
        }
    }

    Component { id: dashboardComp;   DashboardPage {} }
    Component { id: mediaComp;       MediaPage {} }
    Component { id: performanceComp; PerformancePage {} }
    Component { id: weatherComp;     WeatherPage {} }
}
