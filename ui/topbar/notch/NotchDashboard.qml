import QtQuick
import QtQuick.Layouts
import qs.components
import qs.ui.topbar.notch.dashboard

ColumnLayout {
    id: root
    spacing: 8

    NotchTabBar {
        id: tabBar
        Layout.fillWidth: true
    }

    PageLoader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        index: tabBar.currentIndex
        pages: [dashboardComp, performanceComp]
    }

    Component { id: dashboardComp;   DashboardPage {} }
    Component { id: performanceComp; PerformancePage {} }
}
