import QtQuick
import QtQuick.Layouts
import qs.ui.topbar.notch.dashboard

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
        sourceComponent: tabBar.currentIndex === 1 ? performanceComp : dashboardComp
    }

    Component { id: dashboardComp;   DashboardPage {} }
    Component { id: performanceComp; PerformancePage {} }
}
