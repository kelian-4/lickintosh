import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property string size: "s"

    readonly property var connected: BluetoothState.devices.filter(function(d) { return d.connected })
    readonly property int visibleCount: root.size === "l" ? 6 : (root.size === "m" ? 3 : 0)

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Bluetooth"
                color: "#0a84ff"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            CFVI {
                size: 18
                icon: "notch/bluetooth.svg"
                gray: !BluetoothState.enabled
            }
        }

        Text {
            Layout.fillWidth: true
            text: !BluetoothState.enabled ? "Off" : (root.connected.length === 0 ? "No Devices" : root.connected.length + " connected")
            color: "#ffffff"
            font.pixelSize: root.size === "s" ? 18 : 15
            font.weight: Font.Medium
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.connected.slice(0, root.visibleCount)

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: modelData.name
                    elide: Text.ElideRight
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    visible: BluetoothState.batteryPercent(modelData) >= 0
                    text: BluetoothState.batteryPercent(modelData) + "%"
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
