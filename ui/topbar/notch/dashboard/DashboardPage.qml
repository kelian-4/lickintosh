import QtQuick
import QtQuick.Layouts
import qs.ui.topbar.notch.dashboard

// Onglet "Dashboard" : calqué sur modules/dashboard/Dash.qml de
// caelestia — Weather+User côte à côte en haut, Calendar en dessous,
// DateTime/Resources/Media en colonnes hautes de part et d'autre.
ColumnLayout {
    id: root
    spacing: 12

    StatusChipsRow {}

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 14

        DateTimeModule {}

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                WeatherModule {}
                UserModule {}
            }

            CalendarModule {}
        }

        ResourcesModule {}
        MediaModule {}
    }
}
