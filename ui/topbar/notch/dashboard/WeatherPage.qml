import QtQuick
import QtQuick.Layouts
import qs.services

// Onglet "Weather" : calqué sur modules/dashboard/WeatherTab.qml de
// caelestia — ville + date, lever/coucher du soleil, icône+température
// en grand, humidité/ressenti/vent, prévisions 7 jours.
Item {
    id: root

    readonly property var _weekdays: ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."]

    function _weekdayFor(dateStr) {
        var d = new Date(dateStr)
        return root._weekdays[d.getDay()]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        visible: WeatherState.available

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0
                Text { text: WeatherState.city || "Position actuelle"; color: "#FFFFFF"; font.pixelSize: 16; font.bold: true; font.family: "SF Pro Rounded" }
                Text { text: Qt.formatDate(new Date(), "dddd d MMMM"); color: "#8A8A8A"; font.pixelSize: 11; font.family: "SF Pro Rounded" }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 20
                ColumnLayout {
                    spacing: 0
                    Text { text: "Lever"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                    Text { text: WeatherState.sunrise; color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Coucher"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                    Text { text: WeatherState.sunset; color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            Text { text: "☁"; color: "#FFFFFF"; font.pixelSize: 56 }

            ColumnLayout {
                spacing: 0
                Text { text: Math.round(WeatherState.tempC) + "°C"; color: "#FFFFFF"; font.pixelSize: 40; font.bold: true; font.family: "SF Pro Rounded" }
                Text { text: WeatherState.description; color: "#B0B0B0"; font.pixelSize: 13; font.family: "SF Pro Rounded" }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 14
                ColumnLayout {
                    spacing: 0
                    Text { text: "Humidité"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                    Text { text: WeatherState.humidity + "%"; color: "#FFFFFF"; font.pixelSize: 13; font.family: "SF Pro Rounded" }
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Ressenti"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                    Text { text: Math.round(WeatherState.feelsLikeC) + "°C"; color: "#FFFFFF"; font.pixelSize: 13; font.family: "SF Pro Rounded" }
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Vent"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                    Text { text: Math.round(WeatherState.windSpeed) + " km/h"; color: "#FFFFFF"; font.pixelSize: 13; font.family: "SF Pro Rounded" }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: WeatherState.forecast
                delegate: Rectangle {
                    id: dayDelegate
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: 10
                    color: dayDelegate.index === 0 ? "#1C7AFF" : "#1A1A1A"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: dayDelegate.index === 0 ? "Today" : root._weekdayFor(dayDelegate.modelData.date)
                            color: "#FFFFFF"; font.pixelSize: 9; font.family: "SF Pro Rounded"
                        }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "☁"; color: "#FFFFFF"; font.pixelSize: 14 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: dayDelegate.modelData.tempMin + "°/" + dayDelegate.modelData.tempMax + "°"
                            color: "#FFFFFF"; font.pixelSize: 9; font.family: "SF Pro Rounded"
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !WeatherState.available
        text: "Météo indisponible"
        color: "#7A7A7A"
        font.pixelSize: 12
        font.family: "SF Pro Rounded"
    }
}
