import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

// Carte météo — restylée sur le modèle de modules/dashboard/dash/
// SmallWeather.qml de caelestia : icône réelle (pas de badge circulaire
// coloré derrière), température en grand, description en dessous.
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 16
    color: "#1A1A1A"
    visible: WeatherState.available

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        VectorImage {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            Layout.alignment: Qt.AlignVCenter
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + WeatherState.iconFile)
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
                text: Math.round(WeatherState.tempC) + "°C"
                color: "#FFFFFF"; font.pixelSize: 22; font.bold: true; font.family: "SF Pro Rounded"
            }
            Text {
                text: WeatherState.description
                color: "#B0B0B0"; font.pixelSize: 12; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
                Layout.maximumWidth: 130
            }
        }

        Item { Layout.fillWidth: true }
    }
}
