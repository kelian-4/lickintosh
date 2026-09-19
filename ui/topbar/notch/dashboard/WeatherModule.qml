import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

// Carte météo — restylée sur le modèle de modules/dashboard/dash/
// SmallWeather.qml de caelestia : icône réelle (pas de badge circulaire
// coloré derrière), température en grand, description en dessous.
//
// Layout.preferredWidth/preferredHeight fixés depuis DashboardPage.qml
// (le vrai GridLayout de Dash.qml), pas ici : ce module n'a ni
// fillWidth ni fillHeight (conforme au fichier source reel, qui donne
// a Weather une largeur ET une hauteur fixes/intrinseques, pas
// etirees).
//
// Toujours visible (contrairement à une version antérieure qui se
// masquait entièrement via visible: WeatherState.available) : dans une
// disposition partagée avec UserModule, cacher ce module aurait cassé
// l'alignement des colonnes de la grille. À la place, état de repli
// visible quand la météo n'est pas disponible.
Rectangle {
    id: root
    radius: 16
    color: "#1A1A1A"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        VectorImage {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            opacity: WeatherState.available ? 1 : 0.35
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + (WeatherState.available ? WeatherState.iconFile : "weather/clouds.svg"))
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#8AB4F8"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: WeatherState.available ? (Math.round(WeatherState.tempC) + "°C") : "--°C"
                color: "#FFFFFF"; font.pixelSize: 20; font.bold: true; font.family: "SF Pro Rounded"
            }
            Text {
                Layout.fillWidth: true
                text: WeatherState.available ? WeatherState.description : "Météo indisponible"
                color: "#B0B0B0"; font.pixelSize: 11; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
        }
    }
}
