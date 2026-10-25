import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.ui.topbar.notch.dashboard

Item {
    id: root

    property string size: "s"

    readonly property bool present: UPower.displayDevice.isLaptopBattery
    readonly property real fraction: root.present ? UPower.displayDevice.percentage : 1
    readonly property bool charging: UPower.onBattery ? UPower.displayDevice.state === 1 : true
    readonly property color level: root.fraction <= 0.15 ? "#ff453a" : (root.fraction <= 0.3 ? "#ff9f0a" : "#30d158")

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Item {
            Layout.fillWidth: true
            visible: root.size === "s"
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 84
            Layout.preferredHeight: 84

            RingGauge {
                anchors.fill: parent
                size: 84
                percent: root.fraction * 100
                ringColor: root.level
            }
        }

        Item {
            Layout.fillWidth: true
            visible: root.size === "s"
        }

        ColumnLayout {
            visible: root.size === "m"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: "Battery"
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Text {
                text: !root.present ? "Plugged in" : (root.charging ? "Charging" : "On battery")
                color: "#ffffff"
                font.pixelSize: 16
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }
    }
}
