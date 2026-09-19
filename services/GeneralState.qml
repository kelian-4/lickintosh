pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "generalState"

    property string osName: ""
    property string osVersion: ""
    property string kernelVersion: ""
    property string hyprlandVersion: ""
    property string hostname: ""

    Process {
        id: _osReleaseProc
        running: true
        command: ["sh", "-c", "grep -E '^(PRETTY_NAME|VERSION)=' /etc/os-release 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.indexOf("PRETTY_NAME=") === 0) {
                        root.osName = line.replace("PRETTY_NAME=", "").replace(/^"|"$/g, "")
                    } else if (line.indexOf("VERSION=") === 0) {
                        root.osVersion = line.replace("VERSION=", "").replace(/^"|"$/g, "")
                    }
                }
            }
        }
    }

    Process {
        id: _kernelProc
        running: true
        command: ["uname", "-r"]
        stdout: StdioCollector {
            onStreamFinished: { root.kernelVersion = text.trim() }
        }
    }

    Process {
        id: _hostnameProc
        running: true
        command: ["hostname"]
        stdout: StdioCollector {
            onStreamFinished: { root.hostname = text.trim() }
        }
    }

    Process {
        id: _hyprVersionProc
        running: true
        command: ["sh", "-c", "hyprctl version 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hyprlandVersion = text.trim()
                root.wmName = text.trim().length > 0 ? "Hyprland" : ""
            }
        }
    }

    property string osVersionCodename: ""
    property string uptimePretty: ""
    property string shellName: ""
    property string wmName: ""
    property string cpuModel: ""
    property string gpuModel: ""
    property string memoryUsed: ""
    property string memoryTotal: ""
    property string memoryPercent: ""
    property string swapUsed: ""
    property string swapTotal: ""
    property string localIp: ""
    property string machineModel: ""
    property var packageCounts: []

    function refreshOverview() {
        _uptimeProc.running = true
        _shellProc.running = true
        _cpuProc.running = true
        _gpuProc.running = true
        _memoryProc.running = true
        _ipProc.running = true
        _machineModelProc.running = true
        _packageCountProc.running = true
    }

    Process {
        id: _uptimeProc
        // uptime -p (execute directement, sans shell) n'est pas
        // fiable dans l'environnement de Quickshell sur NixOS : le
        // binaire "uptime" peut ne pas etre resolu (PATH minimal du
        // process manager, hors d'un shell de login). /proc/uptime
        // est un pseudo-fichier toujours present sur Linux, lu ici
        // via un builtin shell (read) plutot qu'un binaire externe
        // supplementaire, pour eviter le meme probleme.
        command: ["sh", "-c", "read s _ < /proc/uptime && echo \"$s\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = parseFloat(text.trim())
                root.uptimePretty = isNaN(seconds) ? "" : root._formatUptime(seconds)
            }
        }
    }

    function _formatUptime(totalSeconds) {
        const days = Math.floor(totalSeconds / 86400)
        const hours = Math.floor((totalSeconds % 86400) / 3600)
        const minutes = Math.floor((totalSeconds % 3600) / 60)
        const parts = []
        if (days > 0) parts.push(days + (days > 1 ? " days" : " day"))
        if (hours > 0) parts.push(hours + (hours > 1 ? " hours" : " hour"))
        if (parts.length < 2 && minutes > 0) parts.push(minutes + (minutes > 1 ? " minutes" : " minute"))
        if (parts.length === 0) return "less than a minute"
        return parts.join(", ")
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: _uptimeProc.running = true
    }

    Process {
        id: _shellProc
        command: ["sh", "-c", "basename \"$SHELL\" 2>/dev/null; \"$SHELL\" --version 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                root.shellName = lines.length > 0 ? lines.join(" ") : ""
            }
        }
    }

    Process {
        id: _cpuProc
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//'"]
        stdout: StdioCollector {
            onStreamFinished: { root.cpuModel = text.trim() }
        }
    }

    Process {
        id: _gpuProc
        command: ["sh", "-c", "command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d: -f3 | sed 's/^ *//' || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: { root.gpuModel = text.trim() }
        }
    }

    Process {
        id: _memoryProc
        command: ["sh", "-c", "free -h | awk 'NR==2{print $3\"|\"$2} NR==3{print $3\"|\"$2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                if (lines.length >= 1) {
                    var mem = lines[0].split("|")
                    root.memoryUsed = mem[0] || ""
                    root.memoryTotal = mem[1] || ""
                }
                if (lines.length >= 2) {
                    var swap = lines[1].split("|")
                    root.swapUsed = swap[0] || ""
                    root.swapTotal = swap[1] || ""
                }
            }
        }
    }

    Process {
        id: _ipProc
        command: ["sh", "-c", "ip route get 1.1.1.1 2>/dev/null | grep -oE 'src [0-9.]+' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: { root.localIp = text.trim() }
        }
    }

    Process {
        id: _machineModelProc
        command: ["sh", "-c", "cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: { root.machineModel = text.trim() }
        }
    }

    Process {
        id: _packageCountProc
        command: ["sh", "-c",
            "command -v dpkg >/dev/null 2>&1 && echo \"dpkg:$(dpkg -l 2>/dev/null | grep -c '^ii')\"; " +
            "command -v rpm >/dev/null 2>&1 && echo \"rpm:$(rpm -qa 2>/dev/null | wc -l)\"; " +
            "command -v pacman >/dev/null 2>&1 && echo \"pacman:$(pacman -Qq 2>/dev/null | wc -l)\"; " +
            "command -v flatpak >/dev/null 2>&1 && echo \"flatpak:$(flatpak list 2>/dev/null | wc -l)\"; " +
            "command -v snap >/dev/null 2>&1 && echo \"snap:$(snap list 2>/dev/null | tail -n +2 | wc -l)\"; " +
            "command -v nix-store >/dev/null 2>&1 && echo \"nix-system:$(find /run/current-system/sw/bin -maxdepth 1 -type l 2>/dev/null | xargs -r -n1 readlink | sed -E 's|[^-]+-([^/]+)/.*|\\1|g' | sort -u | wc -l)\"; " +
            "command -v nix-store >/dev/null 2>&1 && echo \"nix-user:$({ find \\\"$HOME/.nix-profile/bin\\\" -maxdepth 1 -type l 2>/dev/null; find \\\"/etc/profiles/per-user/$USER/bin\\\" -maxdepth 1 -type l 2>/dev/null; } | xargs -r -n1 readlink | sed -E 's|[^-]+-([^/]+)/.*|\\1|g' | sort -u | wc -l)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var counts = []
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 2) continue
                    var n = parseInt(parts[1])
                    if (isNaN(n) || n === 0) continue
                    counts.push({ manager: parts[0], count: n })
                }
                root.packageCounts = counts
            }
        }
    }

    property string batteryModel: ""
    property string batteryPercent: ""
    property string batteryState: ""

    Process {
        id: _batteryProc
        command: ["sh", "-c",
            "BAT=$(upower -e 2>/dev/null | grep -i BAT | head -1); " +
            "[ -n \"$BAT\" ] && upower -i \"$BAT\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.indexOf("model:") === 0) root.batteryModel = line.replace("model:", "").trim()
                    else if (line.indexOf("percentage:") === 0) root.batteryPercent = line.replace("percentage:", "").trim()
                    else if (line.indexOf("state:") === 0) root.batteryState = line.replace("state:", "").trim()
                }
            }
        }
    }

    property var storageVolumes: []

    function refreshStorage() {
        _storageProc.running = true
    }

    Process {
        id: _storageProc
        command: ["sh", "-c", "df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var volumes = []
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0) continue
                    var parts = lines[i].trim().split(/\s+/)
                    if (parts.length < 6) continue
                    volumes.push({
                        filesystem: parts[0],
                        size: parts[1],
                        used: parts[2],
                        available: parts[3],
                        usePercent: parts[4],
                        mountPoint: parts[5]
                    })
                }
                root.storageVolumes = volumes
            }
        }
    }

    property string timezone: ""
    property bool ntpEnabled: false
    property bool clockSynchronized: false

    function refreshDateTime() {
        _timedatectlProc.running = true
    }

    Process {
        id: _timedatectlProc
        running: true
        command: ["timedatectl", "show", "--property=Timezone,NTP,NTPSynchronized"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("=")
                    if (parts.length < 2) continue
                    var key = parts[0]
                    var value = parts.slice(1).join("=")
                    if (key === "Timezone") root.timezone = value
                    else if (key === "NTP") root.ntpEnabled = value === "yes"
                    else if (key === "NTPSynchronized") root.clockSynchronized = value === "yes"
                }
            }
        }
    }

    function setNtpEnabled(enabled) {
        _setNtpProc.command = ["timedatectl", "set-ntp", enabled ? "true" : "false"]
        _setNtpProc.running = true
    }

    Process {
        id: _setNtpProc
        onExited: root.refreshDateTime()
    }

    property string localeName: ""
    property string languageCode: ""

    Process {
        id: _localeProc
        running: true
        command: ["sh", "-c", "echo \"${LANG:-C}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.localeName = text.trim()
                root.languageCode = text.trim().split(".")[0].split("_")[0]
            }
        }
    }

    property string packageManager: ""
    property int updateCount: -1
    property bool checkingUpdates: false

    Process {
        id: _detectPkgManagerProc
        running: true
        command: ["sh", "-c",
            "if command -v nix-channel >/dev/null 2>&1 && [ -f /etc/nixos/configuration.nix ]; then echo nixos; " +
            "elif command -v apt >/dev/null 2>&1; then echo apt; " +
            "elif command -v dnf >/dev/null 2>&1; then echo dnf; " +
            "elif command -v pacman >/dev/null 2>&1; then echo pacman; " +
            "elif command -v zypper >/dev/null 2>&1; then echo zypper; " +
            "else echo unknown; fi"]
        stdout: StdioCollector {
            onStreamFinished: { root.packageManager = text.trim() }
        }
    }

    function checkForUpdates() {
        if (root.packageManager === "" || root.packageManager === "unknown") return
        root.checkingUpdates = true

        var cmd = ""
        switch (root.packageManager) {
            case "apt":
                cmd = "apt list --upgradable 2>/dev/null | tail -n +2 | wc -l"
                break
            case "dnf":
                cmd = "dnf check-update 2>/dev/null | grep -c '^[a-zA-Z0-9]'"
                break
            case "pacman":
                cmd = "checkupdates 2>/dev/null | wc -l"
                break
            case "zypper":
                cmd = "zypper lu 2>/dev/null | grep -c '^v '"
                break
            case "nixos":
                cmd = "nix-channel --update >/dev/null 2>&1; nix-env -u --dry-run 2>/dev/null | grep -c '^would'"
                break
            default:
                root.checkingUpdates = false
                return
        }

        _updateCheckProc.command = ["sh", "-c", cmd]
        _updateCheckProc.running = true
    }

    Process {
        id: _updateCheckProc
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(text.trim())
                root.updateCount = isNaN(n) ? 0 : n
                root.checkingUpdates = false
            }
        }
    }

    property var autostartEntries: []

    function refreshAutostart() {
        _autostartProc.running = true
    }

    Process {
        id: _autostartProc
        running: true
        command: ["sh", "-c",
            "for d in \"$HOME/.config/autostart\" /etc/xdg/autostart; do " +
            "[ -d \"$d\" ] && find \"$d\" -maxdepth 1 -name '*.desktop' 2>/dev/null; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var paths = text.trim().split("\n").filter(function(p) { return p.length > 0 })
                root._pendingAutostartPaths = paths
                root._readNextAutostartEntry()
            }
        }
    }

    property var _pendingAutostartPaths: []
    property var _autostartAccum: []

    function _readNextAutostartEntry() {
        if (root._pendingAutostartPaths.length === 0) {
            root.autostartEntries = root._autostartAccum
            root._autostartAccum = []
            return
        }
        var path = root._pendingAutostartPaths.shift()
        _autostartReadProc.command = ["sh", "-c",
            "grep -E '^(Name|Exec|X-GNOME-Autostart-enabled|Hidden)=' '" + path.replace(/'/g, "'\\''") + "' 2>/dev/null"]
        _autostartReadProc.property_path = path
        _autostartReadProc.running = true
    }

    Process {
        id: _autostartReadProc
        property string property_path: ""
        stdout: StdioCollector {
            onStreamFinished: {
                var name = ""
                var enabled = true
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.indexOf("Name=") === 0) name = line.replace("Name=", "")
                    else if (line.indexOf("Hidden=") === 0 && line.replace("Hidden=", "") === "true") enabled = false
                    else if (line.indexOf("X-GNOME-Autostart-enabled=") === 0 && line.replace("X-GNOME-Autostart-enabled=", "") === "false") enabled = false
                }
                if (name.length > 0) {
                    root._autostartAccum.push({ name: name, path: _autostartReadProc.property_path, enabled: enabled })
                }
                root._readNextAutostartEntry()
            }
        }
    }

    function setAutostartEnabled(path, enabled) {
        _toggleAutostartProc.command = ["sh", "-c",
            "grep -q '^Hidden=' '" + path.replace(/'/g, "'\\''") + "' && " +
            "sed -i 's/^Hidden=.*/Hidden=" + (enabled ? "false" : "true") + "/' '" + path.replace(/'/g, "'\\''") + "' || " +
            "echo 'Hidden=" + (enabled ? "false" : "true") + "' >> '" + path.replace(/'/g, "'\\''") + "'"]
        _toggleAutostartProc.running = true
    }

    Process {
        id: _toggleAutostartProc
        onExited: root.refreshAutostart()
    }

    Component.onCompleted: {
        root.refreshStorage()
        root.checkForUpdates()
        root.refreshOverview()
        _batteryProc.running = true
    }
}
