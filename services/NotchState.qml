pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services

Singleton {
    id: root

    reloadableId: "notchState"

    property real topbarZoneWidth: 220

    property string visualState: "idle"

    readonly property bool hovered:  root.visualState !== "idle"
    readonly property bool expanded: root.visualState === "expanded"

    function setHovered(on) {
        if (root.visualState === "expanded") return
        if (on) {
            root.visualState = "peek"
        } else if (root._urgent.length === 0) {
            root.visualState = "idle"
        }
    }

    function toggleExpanded() {
        root.visualState = root.expanded ? (root._urgent.length > 0 ? "peek" : "idle") : "expanded"
    }

    function close() {
        root.visualState = root._urgent.length > 0 ? "peek" : "idle"
    }

    readonly property var  _battery: UPower.displayDevice
    readonly property bool batteryCharging: root._battery !== null
                                             && root._battery.isLaptopBattery
                                             && root._battery.state === UPowerDeviceState.Charging
    readonly property int  batteryPercent: root._battery ? Math.round(root._battery.percentage * 100) : 0

    property var _urgent: []

    function _pushUrgent(kind, title, subtitle, icon, ttlMs) {
        const now   = Date.now()
        const entry = { id: kind + "_" + now, kind: kind, title: title, subtitle: subtitle || "", icon: icon || "", expiresAt: now + (ttlMs || 4000) }
        const list  = root._urgent.filter(e => e.kind !== kind)
        list.push(entry)
        root._urgent = list
        if (root.visualState === "idle") root.visualState = "peek"
    }

    function notifyIncoming(appName, summary, appIcon) {
        root._pushUrgent("notification", appName || "Notification", summary, appIcon, 4500)
    }

    function _pruneUrgent() {
        const now  = Date.now()
        const kept = root._urgent.filter(e => e.expiresAt > now)
        if (kept.length !== root._urgent.length) {
            root._urgent = kept
            if (kept.length === 0 && root.visualState === "peek") root.visualState = "idle"
        }
    }

    Timer { interval: 500; running: true; repeat: true; onTriggered: root._pruneUrgent() }

    readonly property var topUrgent: root._urgent.length > 0 ? root._urgent[root._urgent.length - 1] : null

    readonly property bool alarmFiring: AlarmState.firingAlarmId !== ""
    readonly property bool timerFiring: TimerState.firing

    onAlarmFiringChanged: if (root.alarmFiring && root.visualState === "idle") root.visualState = "peek"
    onTimerFiringChanged: if (root.timerFiring && root.visualState === "idle") root.visualState = "peek"

    property var _btKnownConnected: ({})

    function _checkBluetoothTransitions() {
        const devices      = BluetoothState.devices
        const nowConnected = {}
        for (var i = 0; i < devices.length; i++) {
            const d   = devices[i]
            const key = d.bluetoothAddress || d.address || d.name
            if (d.connected) nowConnected[key] = true
        }
        for (const key in nowConnected) {
            if (!root._btKnownConnected[key]) {
                var dev = null
                for (var j = 0; j < devices.length; j++) {
                    const kk = devices[j].bluetoothAddress || devices[j].address || devices[j].name
                    if (kk === key) { dev = devices[j]; break }
                }
                root._pushUrgent("bluetooth", dev ? dev.name : "Bluetooth", "Connecté", dev ? BluetoothState.deviceIcon(dev) : "", 3500)
            }
        }
        root._btKnownConnected = nowConnected
    }

    Timer { interval: 1500; running: true; repeat: true; onTriggered: root._checkBluetoothTransitions() }

    readonly property string ambientKind: {
        if (MediaCaptureState.cameraActive) return "capture-camera"
        if (MediaCaptureState.micActive)    return "capture-mic"
        if (MprisState.hasPlayer && MprisState.isPlaying) return "media"
        if (TimerState.running)     return "timer"
        if (StopwatchState.running) return "stopwatch"
        if (root.batteryCharging)   return "battery"
        if (GameMode.enabled)       return "gamemode"
        return "none"
    }

    readonly property string primaryKind: root.topUrgent ? root.topUrgent.kind : root.ambientKind
    readonly property bool hasUrgentActivity: root.topUrgent !== null || root.alarmFiring || root.timerFiring
}
