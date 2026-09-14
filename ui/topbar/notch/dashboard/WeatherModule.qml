import QtQuick
import QtQuick.Layouts
import qs.services

// Calqué sur modules/dashboard/dash/SmallWeather.qml de caelestia :
// température + description, alimenté par services/WeatherState.qml
// (Open-Meteo, même source de données qu'eux).
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    radius: 12
    color: "#1A1A1A"
    visible: WeatherState.available

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Badge circulaire coloré derrière l'icône, façon caelestia
        // (leurs cartes ont toutes un cercle pastel derrière l'icône,
        // pas juste l'icône seule).
        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: "#3A2A5A"
            Text { anchors.centerIn: parent; text: "☁"; color: "#B39DDB"; font.pixelSize: 16 }
        }

        ColumnLayout {
            spacing: 1
            Text {
                text: Math.round(WeatherState.tempC) + "°C"
                color: "#FFFFFF"; font.pixelSize: 18; font.bold: true; font.family: "SF Pro Rounded"
            }
            Text {
                text: WeatherState.description
                color: "#B0B0B0"; font.pixelSize: 10; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: WeatherState.city
            color: "#8A8A8A"; font.pixelSize: 10; font.family: "SF Pro Rounded"
            elide: Text.ElideRight
            Layout.maximumWidth: 90
        }
    }
}
