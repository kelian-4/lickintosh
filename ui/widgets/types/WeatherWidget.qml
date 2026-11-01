import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"
    readonly property bool fullBleed: true

    function dayLabel(dateString) {
        return Qt.locale().dayName(new Date(dateString + "T12:00:00").getDay(), Locale.ShortFormat)
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: root.look.skyTop }
            GradientStop { position: 1.0; color: root.look.skyBottom }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        visible: root.size !== "l"

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 0

            Text {
                text: WeatherState.city !== "" ? WeatherState.city : "Weather"
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.Medium
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Text {
                text: WeatherState.available ? Math.round(WeatherState.tempC) + "°" : "--°"
                color: "#ffffff"
                font.pixelSize: 46
                font.weight: Font.Thin
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillHeight: true }

            CFVI {
                size: 22
                colorized: false
                icon: WeatherState.iconFile
                visible: WeatherState.available
            }

            Text {
                text: WeatherState.description
                color: Qt.rgba(1, 1, 1, 0.85)
                font.pixelSize: 11
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            visible: root.size === "m"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Repeater {
                model: WeatherState.forecast.slice(1, 5)

                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.dayLabel(modelData.date)
                        color: Qt.rgba(1, 1, 1, 0.75)
                        font.pixelSize: 11
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }

                    CFVI {
                        Layout.alignment: Qt.AlignHCenter
                        size: 20
                        colorized: false
                        icon: WeatherState._iconFor(modelData.code)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.tempMax + "°"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.tempMin + "°"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 12
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: root.size === "l"

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0

                Text {
                    text: WeatherState.city !== "" ? WeatherState.city : "Weather"
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: WeatherState.available ? Math.round(WeatherState.tempC) + "°" : "--°"
                    color: "#ffffff"
                    font.pixelSize: 52
                    font.weight: Font.Thin
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 4

                CFVI {
                    Layout.alignment: Qt.AlignRight
                    size: 32
                    colorized: false
                    icon: WeatherState.iconFile
                    visible: WeatherState.available
                }

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: WeatherState.description
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.2)
        }

        Repeater {
            model: WeatherState.forecast.slice(0, 6)

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: 44
                    text: root.dayLabel(modelData.date)
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                CFVI {
                    size: 18
                    colorized: false
                    icon: WeatherState._iconFor(modelData.code)
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: modelData.tempMin + "°"
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.pixelSize: 13
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                    text: modelData.tempMax + "°"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
