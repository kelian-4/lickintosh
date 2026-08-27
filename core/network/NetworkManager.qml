pragma Singleton
pragma ComponentBehavior: Bound

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
    readonly property bool scanning:                   _rescanBackground.running
    readonly property bool busy:                       _connect.running
                                                         || _connectFresh.running
                                                         || _disconnect.running
                                                         || _deleteProfile.running
                                                         || _deleteProfileSilent.running

    readonly property bool   ethernetConnected: _ethernetInterface !== ""
    property string _ethernetInterface: ""
    property string _ethernetConnectionName: ""

    property string _pendingSSID:     ""
    property string _pendingPassword: ""

    // ---------------------------------------------------------------
    // Détails de connexion (IPv4/IPv6, DHCP) pour la connexion active
    // demandée. Rempli à la demande via fetchConnectionDetails().
    // ---------------------------------------------------------------
    property string detailsSSID:       ""
    property string detailsIPv4Method: ""
    property string detailsIPv4:       ""
    property string detailsSubnet:     ""
    property string detailsRouter:     ""
    property string detailsIPv6Method: ""
    property string detailsIPv6:       ""
    property bool   detailsLoading:    false

    function fetchConnectionDetails(ssid) {
        if (!ssid) return
        root.detailsSSID    = ssid
        root.detailsLoading = true
        _connDetails.command = ["nmcli", "-g",
            "IP4.ADDRESS,IP4.GATEWAY,IP4.ROUTE,ipv4.method,IP6.ADDRESS,ipv6.method",
            "connection", "show", ssid]
        _connDetails.running = true
    }

    function clearConnectionDetails() {
        root.detailsSSID       = ""
        root.detailsIPv4Method = ""
        root.detailsIPv4       = ""
        root.detailsSubnet     = ""
        root.detailsRouter     = ""
        root.detailsIPv6Method = ""
        root.detailsIPv6       = ""
    }

    function renewDhcpLease(ssid) {
        if (!ssid) return
        _dhcpRenew.command = ["sh", "-c",
            "nmcli conn down '" + ssid.replace(/'/g, "'\\''") + "' && nmcli conn up '" + ssid.replace(/'/g, "'\\''") + "'"]
        _dhcpRenew.running = true
    }

    Process {
        id: _dhcpRenew
        onExited: {
            if (root.detailsSSID) root.fetchConnectionDetails(root.detailsSSID)
        }
    }

    Process {
        id: _connDetails
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                // Champs demandés dans l'ordre : IP4.ADDRESS, IP4.GATEWAY,
                // IP4.ROUTE, ipv4.method, IP6.ADDRESS, ipv6.method.
                // nmcli -g sépare les valeurs multi-lignes du même champ
                // par des retours à la ligne dans l'ordre de la requête ;
                // on reste défensif si le format diffère légèrement.
                var addr4  = lines[0] || ""
                var gw4    = lines[1] || ""
                var route4 = lines[2] || ""
                var method4 = lines[3] || ""
                var addr6  = lines[4] || ""
                var method6 = lines[5] || ""

                var ipPart = addr4.split("/")
                root.detailsIPv4       = ipPart[0] || ""
                root.detailsSubnet     = ipPart.length > 1 ? _prefixToNetmask(parseInt(ipPart[1])) : ""
                root.detailsRouter     = gw4
                root.detailsIPv4Method = method4 === "auto" ? "Utilisation du DHCP" : method4
                root.detailsIPv6       = addr6.split("/")[0] || ""
                root.detailsIPv6Method = method6 === "auto" ? "Automatiquement" : method6

                root.detailsLoading = false
            }
        }
    }

    function _prefixToNetmask(prefix) {
        if (isNaN(prefix) || prefix < 0 || prefix > 32) return ""
        var mask = []
        for (var i = 0; i < 4; i++) {
            var n = Math.min(8, Math.max(0, prefix - i * 8))
            mask.push(256 - Math.pow(2, 8 - n))
        }
        return mask.join(".")
    }

    signal connectionFailed(string ssid)
    signal passwordRequired(string ssid)

    function _detectPasswordRequired(stderrText) {
        if (!stderrText || stderrText.length === 0) return false
        var t = stderrText
        return t.indexOf("Secrets were required") !== -1
            || t.indexOf("No secrets provided") !== -1
            || t.indexOf("802-11-wireless-security.psk") !== -1
            || (t.indexOf("password") !== -1 && t.indexOf("successfully") === -1)
    }

    function enableWifi(enabled) {
        _enableWifi.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"]
        _enableWifi.running = true
    }

    function connectToNetwork(ssid, password) {
        root._pendingSSID = ssid
        _connectTimeoutTimer.restart()

        if (password === "") {
            _connect.command = ["nmcli", "conn", "up", ssid]
            _connect.running = true
        } else {
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

    function forgetNetwork(ssid) {
        if (!ssid) return
        _forgetProfile.command = ["nmcli", "conn", "delete", ssid]
        _forgetProfile.running = true
    }

    function refresh() {
        _getNetworks.running = true
        _getKnown.running    = true
    }

    function rescan() {
        _getNetworks.running = true
        _getKnown.running    = true
        _rescanBackground.running = true
    }

    // Filet de sécurité : si aucune réponse claire n'arrive dans les 6s
    // (ni connexion réussie, ni erreur détectée), on considère l'essai
    // comme échoué plutôt que de laisser l'UI bloquée sur "Connexion…".
    Timer {
        id: _connectTimeoutTimer
        interval: 6000
        repeat: false
        onTriggered: {
            if (root._pendingSSID !== "" && (!root.active || root.active.ssid !== root._pendingSSID)) {
                var failedSSID = root._pendingSSID
                root._pendingSSID     = ""
                root._pendingPassword = ""
                root.connectionFailed(failedSSID)
            }
        }
    }

    Process {
        id: _monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: {
                _getNetworks.running  = true
                _getKnown.running     = true
                _wifiStatus.running   = true
                _getEthernet.running  = true
            }
        }
        onExited: _monitorRestartTimer.start()
    }

    Timer {
        id: _monitorRestartTimer
        interval: 2000
        repeat: false
        onTriggered: _monitor.running = true
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
        id: _getEthernet
        running: true
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var foundInterface = ""
                var foundConnName  = ""
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split(":")
                    if (p.length < 4) continue
                    var device = p[0]
                    var type   = p[1]
                    var state  = p[2]
                    var connName = p[3]
                    if (type === "ethernet" && state === "connected") {
                        foundInterface = device
                        foundConnName  = connName
                        break
                    }
                }
                root._ethernetInterface     = foundInterface
                root._ethernetConnectionName = foundConnName
            }
        }
    }

    Process {
        id: _rescanBackground
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            _getNetworks.running = true
            _getKnown.running    = true
        }
    }

    Process {
        id: _connect
        stderr: StdioCollector {
            id: _connectErr
        }
        stdout: SplitParser {
            onRead: {
                _getNetworks.running = true
                _getKnown.running    = true
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                var failedSSID = _connect.command[_connect.command.length - 1]
                _deleteProfileSilent.command = ["nmcli", "conn", "delete", failedSSID]
                _deleteProfileSilent.running = true
                if (root._detectPasswordRequired(_connectErr.text)) {
                    _connectTimeoutTimer.stop()
                    root._pendingSSID = ""
                    root.passwordRequired(failedSSID)
                } else {
                    _connectTimeoutTimer.stop()
                    root._pendingSSID = ""
                    root.connectionFailed(failedSSID)
                }
            } else {
                _connectTimeoutTimer.stop()
                root._pendingSSID = ""
            }
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
        id: _forgetProfile
        onExited: {
            _getKnown.running    = true
            _getNetworks.running = true
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
                                             root._pendingSSID,
                                             "password", root._pendingPassword]
            _connectFresh.running         = true
        }
    }

    Process {
        id: _connectFresh
        stderr: StdioCollector {
            id: _connectFreshErr
        }
        onExited: (exitCode, exitStatus) => {
            var failedSSID = root._pendingSSID
            root._pendingPassword = ""
            if (exitCode !== 0) {
                _deleteProfileSilent.command = ["nmcli", "conn", "delete", failedSSID]
                _deleteProfileSilent.running = true
                if (root._detectPasswordRequired(_connectFreshErr.text)) {
                    _connectTimeoutTimer.stop()
                    root._pendingSSID = ""
                    root.passwordRequired(failedSSID)
                } else {
                    _connectTimeoutTimer.stop()
                    root._pendingSSID = ""
                    root.connectionFailed(failedSSID)
                }
            } else {
                _connectTimeoutTimer.stop()
                root._pendingSSID = ""
            }
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
                    if (!found) {
                        var removedObj = current[k]
                        current.splice(k, 1)
                        removedObj.destroy()
                    }
                }

                for (var q = 0; q < next.length; q++) {
                    var nx       = next[q]
                    var existing = null
                    for (var r = 0; r < current.length; r++) {
                        if (current[r].ssid === nx.ssid) { existing = current[r]; break }
                    }
                    if (existing) {
                        var old = existing.lastIpcObject
                        var meaningfullyChanged = !old
                            || old.active    !== nx.active
                            || old.ssid      !== nx.ssid
                            || old.bssid     !== nx.bssid
                            || old.security  !== nx.security
                            || old.frequency !== nx.frequency
                            || Math.abs((old.strength || 0) - nx.strength) >= 5
                        if (meaningfullyChanged) {
                            existing.lastIpcObject = nx
                        }
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

                var newKnown = []
                for (var j = 0; j < root.networks.length; j++) {
                    if (known.indexOf(root.networks[j].ssid) !== -1) {
                        newKnown.push(root.networks[j])
                    }
                }

                var rk = root.networksKnown
                var sameLength = rk.length === newKnown.length
                var sameItems  = sameLength
                if (sameItems) {
                    for (var s = 0; s < rk.length; s++) {
                        if (rk[s] !== newKnown[s]) { sameItems = false; break }
                    }
                }
                if (!sameItems) {
                    rk.splice(0, rk.length)
                    for (var t = 0; t < newKnown.length; t++) {
                        rk.push(newKnown[t])
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
