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
                                                         || _cleanup.running
                                                         || _forgetProfile.running

    readonly property bool   ethernetConnected: _ethernetInterface !== ""
    property string _ethernetInterface: ""
    property string _ethernetConnectionName: ""

    property string _pendingSSID: ""
    property bool   _hadProfile:  false
    property bool   _timedOut:    false
    property var    failures:     ({})

    readonly property string _findScript:
        "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r u t; do " +
        "[ \"$t\" = 802-11-wireless ] || continue; " +
        "s=$(nmcli -g 802-11-wireless.ssid connection show uuid \"$u\" 2>/dev/null); " +
        "[ \"$s\" = \"$LK_SSID\" ] && echo \"$u\"; done"

    readonly property string _deleteScript:
        _findScript + " | while read -r u; do nmcli connection delete uuid \"$u\" >/dev/null 2>&1; done; " +
        "[ -z \"$(" + _findScript + ")\" ]"

    readonly property string _upScript:
        "u=$(" + _findScript + " | head -n1); " +
        "if [ -n \"$u\" ]; then exec nmcli --wait 25 connection up uuid \"$u\"; fi; " +
        "exec nmcli --wait 25 device wifi connect \"$LK_SSID\""

    readonly property string _freshScript:
        _deleteScript + "; exec nmcli --wait 25 device wifi connect \"$LK_SSID\" password \"$LK_PW\""

    function failureMessage(ssid) {
        return ssid ? (root.failures[ssid] || "") : ""
    }

    function _setFailure(ssid, message) {
        if (!ssid) return
        var next = Object.assign({}, root.failures)
        if (message) next[ssid] = message
        else delete next[ssid]
        root.failures = next
    }

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

    signal connectionFailed(string ssid, string reason, string message)
    signal passwordRequired(string ssid)

    function _classify(raw, timedOut) {
        if (timedOut)
            return { reason: "timeout", message: I18n.tr("La connexion a expiré : le routeur ne répond pas") }
        var t = (raw || "").toLowerCase()
        if (t.indexOf("802-11-wireless-security.psk") !== -1)
            return { reason: "password", message: I18n.tr("Mot de passe invalide (8 à 63 caractères)") }
        if (t.indexOf("wi-fi is disabled") !== -1 || t.indexOf("wireless is disabled") !== -1 || t.indexOf("rfkill") !== -1)
            return { reason: "radio", message: I18n.tr("Le Wi-Fi est désactivé") }
        if (t.indexOf("no wi-fi device") !== -1 || t.indexOf("no suitable device") !== -1 || t.indexOf("not ready") !== -1)
            return { reason: "device", message: I18n.tr("Aucune carte Wi-Fi disponible") }
        if (t.indexOf("not authorized") !== -1 || t.indexOf("insufficient privileges") !== -1 || t.indexOf("permission") !== -1)
            return { reason: "denied", message: I18n.tr("Permission refusée par NetworkManager") }
        if (t.indexOf("no network with ssid") !== -1 || t.indexOf("could not be found") !== -1)
            return { reason: "notfound", message: I18n.tr("Réseau introuvable ou hors de portée") }
        if (t.indexOf("ip configuration") !== -1 || t.indexOf("dhcp") !== -1)
            return { reason: "dhcp", message: I18n.tr("Connecté au routeur mais aucune adresse IP attribuée (DHCP)") }
        if (t.indexOf("secrets were required") !== -1 || t.indexOf("no secrets") !== -1
            || t.indexOf("supplicant took too long") !== -1 || t.indexOf("authenticat") !== -1)
            return { reason: "password", message: I18n.tr("Mot de passe incorrect, réessayez") }
        if (t.indexOf("timeout expired") !== -1 || t.indexOf("timed out") !== -1 || t.indexOf("took too long") !== -1)
            return { reason: "timeout", message: I18n.tr("La connexion a expiré : le routeur ne répond pas") }
        var lines = (raw || "").split("\n")
        var line = ""
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].replace(/^\s*(Error|Erreur)\s*:\s*/i, "").trim()
            if (l) { line = l; break }
        }
        if (line.length > 120) line = line.substring(0, 117) + "…"
        return { reason: "unknown",
                 message: line ? I18n.tr("Échec de la connexion : ") + line : I18n.tr("Échec de la connexion (cause inconnue)") }
    }

    function _finishAttempt(exitCode, errText) {
        var ssid = root._pendingSSID
        _connectTimeoutTimer.stop()
        root._pendingSSID = ""
        if (exitCode === 0) {
            root._timedOut = false
            root._setFailure(ssid, "")
        } else {
            var f = root._classify(errText, root._timedOut)
            root._timedOut = false
            var passwordCause = f.reason === "password"
            if (ssid && (passwordCause || !root._hadProfile)) {
                _cleanup.environment = ({ LANG: "C", LC_ALL: "C", LK_SSID: ssid })
                _cleanup.running = true
            }
            root._setFailure(ssid, f.message)
            if (passwordCause) root.passwordRequired(ssid)
            else root.connectionFailed(ssid, f.reason, f.message)
        }
        _getNetworks.running = true
        _getKnown.running    = true
    }

    function enableWifi(enabled) {
        _enableWifi.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"]
        _enableWifi.running = true
    }

    function connectToNetwork(ssid, password) {
        if (!ssid || _connect.running || _connectFresh.running) return
        root._pendingSSID = ssid
        root._timedOut    = false
        root._setFailure(ssid, "")
        _connectTimeoutTimer.restart()

        if (password === "") {
            root._hadProfile = root.networksKnown.some(function(n) { return n.ssid === ssid })
            _connect.environment = ({ LANG: "C", LC_ALL: "C", LK_SSID: ssid })
            _connect.command = ["sh", "-c", root._upScript]
            _connect.running = true
        } else {
            root._hadProfile = false
            _connectFresh.environment = ({ LANG: "C", LC_ALL: "C", LK_SSID: ssid, LK_PW: password })
            _connectFresh.command = ["sh", "-c", root._freshScript]
            _connectFresh.running = true
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
        root._setFailure(ssid, "")
        _forgetProfile.environment = ({ LANG: "C", LC_ALL: "C", LK_SSID: ssid })
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

    Timer {
        id: _connectTimeoutTimer
        interval: 40000
        repeat: false
        onTriggered: {
            if (_connect.running || _connectFresh.running) {
                root._timedOut = true
                _connect.running = false
                _connectFresh.running = false
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
        stderr: StdioCollector { id: _connectErr }
        onExited: (exitCode, exitStatus) => root._finishAttempt(exitCode, _connectErr.text)
    }

    Process {
        id: _connectFresh
        stderr: StdioCollector { id: _connectFreshErr }
        onExited: (exitCode, exitStatus) => root._finishAttempt(exitCode, _connectFreshErr.text)
    }

    Process {
        id: _cleanup
        command: ["sh", "-c", root._deleteScript]
        onExited: _getKnown.running = true
    }

    Process {
        id: _forgetProfile
        command: ["sh", "-c", root._deleteScript]
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
