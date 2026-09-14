import QtQuick
import QtQuick.Layouts
import qs.ui.topbar.notch.dashboard

// Onglet "Dashboard" : calqué sur modules/dashboard/Dash.qml de
// caelestia — Weather+User côte à côte en haut, Calendar en dessous,
// DateTime/Resources/Media en colonnes hautes de part et d'autre.
ColumnLayout {
    id: root
    spacing: 8

    StatusChipsRow {}

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 10

        DateTimeModule {}

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                WeatherModule {}
                UserModule {}
            }

            CalendarModule {}
        }

        ResourcesModule {}
        MediaModule {}
    }
}
