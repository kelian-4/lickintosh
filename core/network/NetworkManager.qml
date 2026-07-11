pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    reloadableId: "network"

    readonly property list<AccessPoint> networks:      []
    readonly property list<AccessPoint> networksKnown: []
    readonly property AccessPoint active:              networks.find(function(n) { return n.active }) || null
    property bool wifiEnabled:                         true
    readonly property bool scanning:                   _rescan.running

    property string _pendingSSID:     ""
    property string _pendingPassword: ""

    signal connectionFailed(string ssid)

    function enableWifi(enabled) {
        _enableWifi.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"]
        _enableWifi.running = true
    }

    function connectToNetwork(ssid, password) {
        if (password === "") {
            if (root.active && root.active.ssid !== ssid) {
                _disconnect.command = ["nmcli", "connection", "down", root.active.ssid]
                _disconnect.running = true
            }
            _connect.command = ["nmcli", "conn", "up", ssid]
            _connect.running = true
        } else {
            root._pendingSSID     = ssid
            root._pendingPassword = password
            _deleteProfile.command = ["nmcli", "conn", "delete", ssid]
            _deleteProfile.running = true
        }
    }

    function disconnectFromNetwork() {
        if (root.active) {
            _disconnect.command = ["nmcli", "connection", "down", root.active.ssid]
            _disconnect.running = true
        }
    }

    function refresh() {
        _getNetworks.running = true
        _getKnown.running    = true
    }

    function rescan() {
        _rescan.running = true
    }

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: {
                _getNetworks.running = true
                _getKnown.running    = true
                _wifiStatus.running  = true
            }
        }
    }

    Process {
        id: _wifiStatus
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: _enableWifi
        onExited: {
            _wifiStatus.running  = true
            _getNetworks.running = true
            _getKnown.running    = true
        }
    }

    Process {
        id: _rescan
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            _getNetworks.running = true
            _getKnown.running    = true
        }
    }

    Process {
        id: _connect
        stdout: SplitParser {
            onRead: {
                _getNetworks.running = true
                _getKnown.running    = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t.indexOf("Secrets were required") !== -1 ||
                    t.indexOf("no-secrets") !== -1 ||
                    t.indexOf("activation failed") !== -1) {
                    var failedSSID = _connect.command[_connect.command.length - 1]
                    _deleteProfileSilent.command = ["nmcli", "conn", "delete", failedSSID]
                    _deleteProfileSilent.running = true
                    root.connectionFailed(failedSSID)
                    _getKnown.running = true
                }
            }
        }
        onExited: {
            _getNetworks.running = true
            _getKnown.running    = true
        }
    }

    Process {
        id: _deleteProfileSilent
        onExited: {
            _getKnown.running = true
        }
    }

    Process {
        id: _disconnect
        stdout: SplitParser {
            onRead: {
                _getNetworks.running = true
                _getKnown.running    = true
            }
        }
    }

    Process {
        id: _deleteProfile
        onExited: {
            _getKnown.running             = true
            _connectFresh.command         = ["nmcli", "device", "wifi", "connect",
                                             root._pendingSSID, "password", root._pendingPassword]
            _connectFresh.running         = true
        }
    }

    Process {
        id: _connectFresh
        stderr: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t.indexOf("Error") !== -1 || t.indexOf("failed") !== -1) {
                    root.connectionFailed(root._pendingSSID)
                }
            }
        }
        onExited: {
            root._pendingSSID     = ""
            root._pendingPassword = ""
            _getNetworks.running  = true
            _getKnown.running     = true
        }
    }

    Process {
        id: _getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var PLACEHOLDER = "STRWHICHHOPEFULLYWONTBEUSED"
                var lines       = text.trim().split("\n")
                var allNets     = []
                for (var i = 0; i < lines.length; i++) {
                    var l    = lines[i].replace(/\\:/g, PLACEHOLDER)
                    var p    = l.split(":")
                    var ssid = p[3] ? p[3].replace(new RegExp(PLACEHOLDER, "g"), ":") : ""
                    var bssid = p[4] ? p[4].replace(new RegExp(PLACEHOLDER, "g"), ":") : ""
                    if (!ssid) continue
                    allNets.push({
                        active:    p[0] === "yes",
                        strength:  parseInt(p[1]) || 0,
                        frequency: parseInt(p[2]) || 0,
                        ssid:      ssid,
                        bssid:     bssid,
                        security:  p[5] || ""
                    })
                }

                var map = {}
                for (var j = 0; j < allNets.length; j++) {
                    var n = allNets[j]
                    var e = map[n.ssid]
                    if (!e || (n.active && !e.active) || (!e.active && n.strength > e.strength)) {
                        map[n.ssid] = n
                    }
                }

                var next    = Object.values(map)
                var current = root.networks

                for (var k = current.length - 1; k >= 0; k--) {
                    var found = false
                    for (var m = 0; m < next.length; m++) {
                        if (next[m].ssid === current[k].ssid) { found = true; break }
                    }
                    if (!found) current.splice(k, 1)
                }

                for (var q = 0; q < next.length; q++) {
                    var nx       = next[q]
                    var existing = null
                    for (var r = 0; r < current.length; r++) {
                        if (current[r].ssid === nx.ssid) { existing = current[r]; break }
                    }
                    if (existing) {
                        existing.lastIpcObject = nx
                    } else {
                        current.push(_apComp.createObject(root, { lastIpcObject: nx }))
                    }
                }

                _getKnown.running = true
            }
        }
    }

    Process {
        id: _getKnown
        running: false
        command: ["nmcli", "-g", "NAME,TYPE", "connection", "show"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var known = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split(":")
                    if (p.length >= 2 && p[1].indexOf("wireless") !== -1 && p[0]) {
                        known.push(p[0])
                    }
                }
                var rk = root.networksKnown
                rk.splice(0, rk.length)
                for (var j = 0; j < root.networks.length; j++) {
                    if (known.indexOf(root.networks[j].ssid) !== -1) {
                        rk.push(root.networks[j])
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid:      lastIpcObject.ssid     || ""
        readonly property string bssid:     lastIpcObject.bssid    || ""
        readonly property int    strength:  lastIpcObject.strength  || 0
        readonly property int    frequency: lastIpcObject.frequency || 0
        readonly property bool   active:    lastIpcObject.active    || false
        readonly property string security:  lastIpcObject.security  || ""
        readonly property bool   isSecure:  security.length > 0
    }

    Component {
        id: _apComp
        AccessPoint {}
    }
}
