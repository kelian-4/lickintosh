pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services

Row {
    id: root

    spacing: 18

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery && battery.ready

    readonly property real batPercentage: root.hasBattery ? battery.percentage : 1
    readonly property bool charging: battery && (battery.state === 1)

    readonly property string batteryIconName: {
        if (!root.hasBattery) return ""
        const level = (root.batPercentage > 0.95) ? "100" :
                    (root.batPercentage > 0.85) ? "090" :
                    (root.batPercentage > 0.75) ? "080" :
                    (root.batPercentage > 0.65) ? "070" :
                    (root.batPercentage > 0.55) ? "060" :
                    (root.batPercentage > 0.45) ? "050" :
                    (root.batPercentage > 0.35) ? "040" :
                    (root.batPercentage > 0.25) ? "030" :
                    (root.batPercentage > 0.15) ? "020" :
                    (root.batPercentage > 0.05) ? "010" : "000"
        return "battery/battery-" + level + (root.charging ? "-charging" : "") + ".svg"
    }

    CFVI {
        visible: NetworkManager.wifiEnabled
        anchors.verticalCenter: parent.verticalCenter
        size: 20
        gray: true
        icon: {
            const ap = NetworkManager.active
            if (!ap) return "wifi/wifi-clear-0.svg"
            const s = ap.strength
            if (s >= 75) return "wifi/wifi-clear-3.svg"
            if (s >= 50) return "wifi/wifi-clear-2.svg"
            if (s >= 25) return "wifi/wifi-clear-1.svg"
            return "wifi/wifi-clear-0.svg"
        }
    }

    CFVI {
        visible: BluetoothState.enabled
        anchors.verticalCenter: parent.verticalCenter
        size: 20
        gray: true
        icon: "bluetooth/bluetooth.svg"
    }

    Row {
        visible: root.hasBattery
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        CFVI {
            anchors.verticalCenter: parent.verticalCenter
            size: 24
            gray: true
            icon: root.batteryIconName
        }

        CFText {
            anchors.verticalCenter: parent.verticalCenter
            gray: true
            font.pixelSize: 14
            text: root.hasBattery ? Math.round(root.batPercentage * 100) + "%" : ""
        }
    }
}
