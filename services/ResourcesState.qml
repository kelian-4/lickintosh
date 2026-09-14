pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
    Équivalent des services natifs C++ de caelestia (plugin/src/Caelestia/
    Services/{cpu,memory,storage,network}.hpp) — mêmes définitions
    (cpu = usage instantané en %, memory = used/total en %, storage =
    usage du disque racine en %, network = débit instantané + totaux),
    réimplémenté en QML/bash via /proc, df, faute de plugin natif
    équivalent dans ce projet.
*/
Singleton {
    id: root

    reloadableId: "resourcesState"

    property real cpuPercent:     0
    property string cpuName:      ""
    property real cpuTempC:       0
    property bool cpuTempAvailable: false

    property real memoryPercent:  0
    property real memoryUsedGb:   0
    property real memoryTotalGb:  0

    property real storagePercent: 0
    property real storageUsedGb:  0
    property real storageTotalGb: 0
    property string storageDevice: "sda"

    property real netDownBps: 0
    property real netUpBps:   0
    property real netTotalDownGb: 0
    property real netTotalUpGb:   0

    property var _prevCpu: null // { total, idle }
    property var _prevNet: null // { rx, tx, t }

    // ---- CPU ----
    Process {
        id: _cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        stdout: StdioCollector { onStreamFinished: root._parseCpu(text) }
    }

    function _parseCpu(line) {
        var parts = line.trim().split(/\s+/).slice(1).map(Number)
        if (parts.length < 4) return
        var idle  = parts[3] + (parts[4] || 0)
        var total = parts.reduce((a, b) => a + b, 0)
        if (root._prevCpu) {
            var deltaTotal = total - root._prevCpu.total
            var deltaIdle  = idle  - root._prevCpu.idle
            if (deltaTotal > 0) root.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - deltaIdle / deltaTotal)))
        }
        root._prevCpu = { total: total, idle: idle }
    }

    Process {
        id: _cpuNameProc
        running: true
        command: ["sh", "-c", "awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo"]
        stdout: StdioCollector { onStreamFinished: root.cpuName = text.trim() }
    }

    Process {
        id: _cpuTempProc
        command: ["sh", "-c",
            "for z in /sys/class/thermal/thermal_zone*/; do " +
            "  t=$(cat \"$z/type\" 2>/dev/null); " +
            "  if echo \"$t\" | grep -qiE 'x86_pkg_temp|cpu|k10temp|coretemp'; then cat \"$z/temp\" 2>/dev/null; exit; fi; " +
            "done; " +
            "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseFloat(text.trim())
                if (!isNaN(v) && v > 0) {
                    root.cpuTempC = v > 1000 ? v / 1000 : v
                    root.cpuTempAvailable = true
                } else {
                    root.cpuTempAvailable = false
                }
            }
        }
    }

    // ---- Mémoire ----
    Process {
        id: _memProc
        command: ["sh", "-c", "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}' /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root._parseMem(text) }
    }

    function _parseMem(line) {
        var parts = line.trim().split(/\s+/).map(Number)
        if (parts.length < 2 || parts[0] <= 0) return
        var totalKb = parts[0], availKb = parts[1]
        var usedKb  = totalKb - availKb
        root.memoryTotalGb = totalKb / 1048576
        root.memoryUsedGb  = usedKb  / 1048576
        root.memoryPercent = Math.max(0, Math.min(100, 100 * usedKb / totalKb))
    }

    // ---- Stockage ----
    Process {
        id: _storageProc
        command: ["sh", "-c", "df -B1 --output=pcent,used,size,source / | tail -1"]
        stdout: StdioCollector { onStreamFinished: root._parseStorage(text) }
    }

    function _parseStorage(line) {
        var parts = line.trim().split(/\s+/)
        if (parts.length < 4) return
        var pcent = parseFloat(parts[0].replace('%', ''))
        var used  = parseFloat(parts[1])
        var size  = parseFloat(parts[2])
        if (!isNaN(pcent)) root.storagePercent = pcent
        if (!isNaN(used))  root.storageUsedGb  = used / 1073741824
        if (!isNaN(size))  root.storageTotalGb = size / 1073741824
        var dev = parts[3] || ""
        var m = dev.match(/([a-zA-Z0-9]+)$/)
        if (m) root.storageDevice = m[1].replace(/[0-9]+$/, "")
    }

    // ---- Réseau ----
    Process {
        id: _netProc
        command: ["sh", "-c",
            "awk 'NR>2 && $1 !~ /lo:/ { gsub(\":\",\"\",$1); rx+=$2; tx+=$10 } END { print rx, tx }' /proc/net/dev"]
        stdout: StdioCollector { onStreamFinished: root._parseNet(text) }
    }

    function _parseNet(line) {
        var parts = line.trim().split(/\s+/).map(Number)
        if (parts.length < 2) return
        var rx = parts[0], tx = parts[1]
        var now = Date.now()
        if (root._prevNet) {
            var dt = (now - root._prevNet.t) / 1000
            if (dt > 0) {
                root.netDownBps = Math.max(0, (rx - root._prevNet.rx) / dt)
                root.netUpBps   = Math.max(0, (tx - root._prevNet.tx) / dt)
            }
        } else {
            root._sessionStartRx = rx
            root._sessionStartTx = tx
        }
        root.netTotalDownGb = Math.max(0, (rx - (root._sessionStartRx || rx)) / 1073741824)
        root.netTotalUpGb   = Math.max(0, (tx - (root._sessionStartTx || tx)) / 1073741824)
        root._prevNet = { rx: rx, tx: tx, t: now }
    }
    property real _sessionStartRx: 0
    property real _sessionStartTx: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!_cpuProc.running)  _cpuProc.running = true
            if (!_memProc.running)  _memProc.running = true
            if (!_netProc.running)  _netProc.running = true
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!_storageProc.running) _storageProc.running = true
            if (!_cpuTempProc.running) _cpuTempProc.running = true
        }
    }
}
