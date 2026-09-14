pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services

/*
    LockStatusIndicators — mini Control Center en lecture seule pour le
    lockscreen (batterie / wifi / bluetooth), inspiré du placement en
    haut à droite d'eqsh (batteryIndicator/wifiIndicator) mais lisant les
    vraies sources d'état du projet plutôt que d'inventer un état séparé :

      - Batterie : Quickshell.Services.UPower (natif, pas de Process
        upower -i dupliqué — BatteryHealthState.qml ne expose pas le
        pourcentage/état de charge instantané, seulement la santé/usure).
      - Wifi     : qs.services.NetworkManager (wifiEnabled, active AP).
      - Bluetooth: qs.services.BluetoothState (enabled, pairedDevices).

    Volontairement non interactif (pas de clic pour ouvrir un panneau) :
    le vrai ControlCenter.qml reste réservé à la session déverrouillée,
    cohérent avec le choix de ne pas exposer d'actions système depuis un
    écran de verrouillage.
*/
Row {
    id: root

    spacing: 18

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery && battery.ready

    // batPercentage / batteryIconName reprennent exactement la logique
    // déjà utilisée et validée dans
    // ui/topbar/statusarea/battery/Battery.qml de ce projet : percentage
    // y est traité comme une fraction 0.0-1.0
    // (Math.round(batPercentage * 100) + "%"), pas 0-100 — correction
    // par rapport à ma première version, qui se basait sur la doc D-Bus
    // UPower brute sans vérifier comment Quickshell la re-normalise
    // réellement ici. Le vrai code du projet, déjà en usage, prime sur
    // la doc externe.
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

    // --- Wifi -----------------------------------------------------
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

    // --- Bluetooth --------------------------------------------------
    // Visible dès que le bluetooth est activé, peu importe s'il y a un
    // appareil apparié/connecté — cohérent avec macOS, qui affiche
    // l'icône même sans rien de connecté. La condition précédente
    // (enabled && pairedDevices.length > 0) cachait l'icône trop
    // souvent, contribuant probablement à l'impression que rien ne
    // s'affichait du tout.
    CFVI {
        visible: BluetoothState.enabled
        anchors.verticalCenter: parent.verticalCenter
        size: 20
        gray: true
        icon: "bluetooth/bluetooth.svg"
    }

    // --- Batterie -----------------------------------------------------
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
