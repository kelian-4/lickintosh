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
// Toujours visible (contrairement à la version d'avant qui se masquait
// entièrement via visible: WeatherState.available) : dans une RowLayout
// avec UserModule, cacher ce module fait que UserModule avale tout
// l'espace libéré (comportement normal d'un RowLayout avec un sibling
// masqué), ce qui casse la disposition prévue à deux cartes égales.
// À la place, état de repli visible quand la météo n'est pas dispo.
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 16
    color: "#1A1A1A"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        VectorImage {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
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
            spacing: 2
            Text {
                text: WeatherState.available ? (Math.round(WeatherState.tempC) + "°C") : "--°C"
                color: "#FFFFFF"; font.pixelSize: 22; font.bold: true; font.family: "SF Pro Rounded"
            }
            Text {
                text: WeatherState.available ? WeatherState.description : "Météo indisponible"
                color: "#B0B0B0"; font.pixelSize: 12; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
                Layout.maximumWidth: 130
            }
        }

        Item { Layout.fillWidth: true }
    }
}
