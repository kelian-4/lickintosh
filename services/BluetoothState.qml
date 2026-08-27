pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    reloadableId: "bluetoothState"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    readonly property var devices: {
        if (!adapter || !enabled) return []
        return adapter.devices.values.filter(function(d) { return d.name !== "" })
    }

    readonly property var pairedDevices: devices.filter(function(d) { return d.paired })
    readonly property var otherDevices:  devices.filter(function(d) { return !d.paired })

    property bool _discoveringStarted: false
    property bool isScanning: false

    function setDiscovering(on) {
        if (!root.adapter || !root.adapter.enabled) return
        if (on) {
            root._discoveringStarted = true
            root._runScanCycle()
        } else {
            root.adapter.discovering = false
            root._discoveringStarted = false
            root.isScanning = false
            _scanTimer.stop()
        }
    }

    function rescan() {
        if (!root.adapter || !root.adapter.enabled) return
        _scanTimer.stop()
        root._discoveringStarted = true
        root._runScanCycle()
    }

    function _runScanCycle() {
        if (!root.adapter || !root.adapter.enabled || !root._discoveringStarted) return
        root.adapter.discovering = true
        root.isScanning = true
        _scanTimer.interval = 8000
        _scanTimer.restart()
    }

    Timer {
        id: _scanTimer
        repeat: false
        onTriggered: {
            if (!root._discoveringStarted) return
            root.adapter.discovering = false
            root.isScanning = false
        }
    }

    function isConnecting(dev) {
        return dev ? dev.state === BluetoothDeviceState.Connecting : false
    }

    function isDisconnecting(dev) {
        return dev ? dev.state === BluetoothDeviceState.Disconnecting : false
    }

    function isBusy(dev) {
        return root.isConnecting(dev) || root.isDisconnecting(dev)
    }

    function connectDevice(dev) {
        if (!dev) return
        dev.connected = true
    }

    function disconnectDevice(dev) {
        if (!dev) return
        dev.connected = false
    }

    function toggleConnection(dev) {
        if (!dev) return
        dev.connected = !dev.connected
    }

    function forgetDevice(dev) {
        if (!dev) return
        dev.forget()
    }

    function isAirpods(dev) {
        if (!dev) return false
        var n  = (dev.name || "").toLowerCase()
        var ic = (dev.icon || "").toLowerCase()
        return n.indexOf("airpods") !== -1
               || ic.indexOf("airpods") !== -1
               || ic.indexOf("headset") !== -1
               || ic.indexOf("headphone") !== -1
               || ic.indexOf("audio") !== -1
    }

    function deviceIcon(dev) {
        if (!dev) return "bluetooth/bluetooth.svg"
        var ic = (dev.icon || "").toLowerCase()

        if (ic.indexOf("headset") !== -1
            || ic.indexOf("headphone") !== -1
            || ic.indexOf("audio") !== -1) return "devices/airpods-pro.svg"

        if (ic.indexOf("phone") !== -1)     return "devices/smartphone.svg"
        if (ic.indexOf("keyboard") !== -1)  return "devices/keyboard.svg"
        if (ic.indexOf("mouse") !== -1)     return "devices/mouse.svg"
        if (ic.indexOf("laptop") !== -1
            || ic.indexOf("notebook") !== -1) return "devices/computer-laptop.svg"
        if (ic.indexOf("computer") !== -1
            || ic.indexOf("desktop") !== -1)  return "devices/computer.svg"
        if (ic.indexOf("watch") !== -1)      return "devices/smartphone.svg"

        return "bluetooth/bluetooth.svg"
    }

    function statusText(dev) {
        if (!dev) return ""
        if (root.isConnecting(dev))    return "Connexion…"
        if (root.isDisconnecting(dev)) return "Déconnexion…"
        if (dev.pairing)               return "Appairage…"
        return dev.connected ? "Connecté" : (dev.paired ? "Appairé" : "Non appairé")
    }

    function batteryPercent(dev) {
        if (!dev || !dev.batteryAvailable) return -1
        return Math.round(dev.battery * 100)
    }

    function batteryText(dev) {
        var pct = root.batteryPercent(dev)
        return pct >= 0 ? (pct + "%") : ""
    }

    function batteryIcon(dev) {
        var pct = root.batteryPercent(dev)
        if (pct < 0) return "battery/battery-000.svg"
        var step = Math.round(pct / 10) * 10
        if (step > 100) step = 100
        if (step < 0) step = 0
        var padded = step < 100 ? ("0" + step).slice(-3) : "100"
        return "battery/battery-" + padded + ".svg"
    }
}
