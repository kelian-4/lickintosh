pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
    État de santé et de charge de la batterie.

    Contient :
      - Battery Health (via upower : energy-full / energy-full-design)
      - Charge Limit (seuil matériel, si le kernel l'expose)
      - Low Power Mode avec règle conditionnelle (Never/Always/
        Only on Battery/Only on Power Adapter), simulée par-dessus
        power-profiles-daemon puisque celui-ci n'a pas cette notion
        nativement.

    Ne gère PAS l'historique long terme (Battery Level / Screen On
    Usage) : voir BatteryHistoryState.qml pour ça.
*/
Singleton {
    id: root

    reloadableId: "batteryHealthState"

    // ---------------------------------------------------------------
    // Battery Health
    // ---------------------------------------------------------------
    property real energyFull:       0
    property real energyFullDesign: 0
    readonly property real healthPercent: energyFullDesign > 0
                                           ? Math.round((energyFull / energyFullDesign) * 100)
                                           : 100
    readonly property string healthLabel: {
        if (energyFullDesign <= 0) return "Inconnu"
        if (healthPercent >= 80) return "Normal"
        if (healthPercent >= 60) return "Réduite"
        return "Service requis"
    }

    property string batteryDevicePath: ""

    Process {
        id: _findDevice
        running: true
        command: ["sh", "-c", "upower -e 2>/dev/null | grep -i BAT | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim()
                if (path.length > 0) {
                    root.batteryDevicePath = path
                    _healthProc.running = true
                }
            }
        }
    }

    Process {
        id: _healthProc
        command: ["sh", "-c", "upower -i '" + root.batteryDevicePath.replace(/'/g, "'\\''") + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.indexOf("energy-full:") === 0 && line.indexOf("energy-full-design") === -1) {
                        root.energyFull = parseFloat(line.replace("energy-full:", "").trim())
                    } else if (line.indexOf("energy-full-design:") === 0) {
                        root.energyFullDesign = parseFloat(line.replace("energy-full-design:", "").trim())
                    }
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (root.batteryDevicePath !== "") _healthProc.running = true
        }
    }

    // ---------------------------------------------------------------
    // Charge Limit (seuil matériel)
    // Chemin standard exposé par certains pilotes (ThinkPad, ASUS,
    // certains Dell) : /sys/class/power_supply/BAT0/charge_control_end_threshold
    // Si absent, la fonctionnalité doit rester masquée côté UI.
    // ---------------------------------------------------------------
    property bool   chargeLimitSupported: false
    property string chargeLimitPath: ""
    property int    chargeLimitValue: 100

    Process {
        id: _findChargeLimitPath
        running: true
        command: ["sh", "-c",
            "for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do " +
            "if [ -w \"$f\" ]; then echo \"$f\"; break; fi; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim()
                if (path.length > 0) {
                    root.chargeLimitPath      = path
                    root.chargeLimitSupported = true
                    _readChargeLimit.running  = true
                }
            }
        }
    }

    Process {
        id: _readChargeLimit
        command: ["cat", root.chargeLimitPath]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                if (!isNaN(v)) root.chargeLimitValue = v
            }
        }
    }

    function setChargeLimit(percent) {
        if (!root.chargeLimitSupported) return
        var v = Math.max(1, Math.min(100, Math.round(percent)))
        root.chargeLimitValue = v
        _writeChargeLimit.command = ["sh", "-c",
            "echo " + v + " | pkexec tee '" + root.chargeLimitPath.replace(/'/g, "'\\''") + "' >/dev/null"]
        _writeChargeLimit.running = true
    }

    Process {
        id: _writeChargeLimit
    }

    // ---------------------------------------------------------------
    // Low Power Mode avec règle conditionnelle
    // power-profiles-daemon n'a pas de notion "only on battery" ni
    // "only on AC" : on la simule nous-mêmes en surveillant l'état
    // secteur/batterie via upower et en appliquant le profil voulu.
    // ---------------------------------------------------------------
    // "never" | "always" | "only-battery" | "only-ac"
    property string lowPowerRule: "never"
    property bool   onBattery: false

    Process {
        id: _acStateProc
        command: ["sh", "-c", "upower -i '" + root.batteryDevicePath.replace(/'/g, "'\\''") + "' 2>/dev/null | grep -i 'state:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var isDischarging = text.toLowerCase().indexOf("discharging") !== -1
                if (isDischarging !== root.onBattery) {
                    root.onBattery = isDischarging
                    root._applyLowPowerRule()
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: root.batteryDevicePath !== ""
        repeat: true
        onTriggered: _acStateProc.running = true
    }

    function setLowPowerRule(rule) {
        root.lowPowerRule = rule
        root._applyLowPowerRule()
    }

    function _applyLowPowerRule() {
        var wantPowerSaver = false
        switch (root.lowPowerRule) {
            case "always":       wantPowerSaver = true; break
            case "only-battery": wantPowerSaver = root.onBattery; break
            case "only-ac":      wantPowerSaver = !root.onBattery; break
            default:              wantPowerSaver = false
        }
        _setProfileProc.command = ["powerprofilesctl", "set", wantPowerSaver ? "power-saver" : "balanced"]
        _setProfileProc.running = true
    }

    Process {
        id: _setProfileProc
    }
}
