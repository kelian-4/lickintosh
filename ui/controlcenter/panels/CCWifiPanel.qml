import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../components/glass"

Item {
    id: root
 
     BoxGlass {
    anchors.fill: parent
    radius: 20
    color: Qt.rgba(1, 1, 1, 0.06)
    light: Qt.rgba(1, 1, 1, 0.22)
    rimStrength: 0.6
    rimSize: 0.012
    }

    readonly property int _headerH: 56
    readonly property int _rowH:    46
    readonly property int _labelH:  28
    readonly property int _pwdH:    82
    readonly property int _footerH: 44

    property bool   wifiOn:      false
    property var    activeNet:   null    // {ssid, secured}
    property var    knownNets:   []      // [{ssid, secured}] — profils connus non actifs
    property var    otherNets:   []      // [{ssid, signal, secured}] — inconnus
    property bool   otherShown:  false
    property int    pwdIndex:    -1

    height: {
        var h = _headerH + 1
        h += activeNet  ? _labelH + _rowH : 0
        h += knownNets.length > 0 ? _labelH + knownNets.length * _rowH : 0
        h += 1 + _labelH
        if (otherShown) {
            for (var j = 0; j < otherNets.length; j++)
                h += (pwdIndex === j) ? _pwdH : _rowH
        }
        h += 1 + _footerH + 8
        return h
    }

    Process {
        id: _nmAll
        command: ["sh", "-c",
        "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,NAME device wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var active  = null
                var known   = []
                var other   = []
                var seenSSID = []

                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p       = lines[i].split(":")
                    var inuse   = p[0] ? p[0].trim() : ""
                    var ssid    = p[1] ? p[1].trim() : ""
                    var signal  = parseInt(p[2]) || 0
                    var secured = p[3] ? p[3].trim() !== "--" : false
                    var name    = p[4] ? p[4].trim() : ""  // nom du profil nmcli

                    if (!ssid) continue
                        // Dédoublonner par SSID
                        if (seenSSID.indexOf(ssid) !== -1) continue
                            seenSSID.push(ssid)

                            if (inuse === "*") {
                                // Réseau actif
                                active = { ssid: ssid, secured: secured, profile: name }
                            } else if (name !== "") {
                                // Profil connu mais pas actif
                                known.push({ ssid: ssid, secured: secured, profile: name })
                            } else {
                                // Inconnu
                                other.push({ ssid: ssid, signal: signal, secured: secured })
                            }
                }

                root.activeNet  = active
                root.knownNets  = known
                root.otherNets  = other
            }
        }
    }

    Process {
        id: _nmRadio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }

    Process { id: _nmOn;  command: ["nmcli", "radio", "wifi", "on"]  }
    Process { id: _nmOff; command: ["nmcli", "radio", "wifi", "off"] }

    // Connexion via nom de profil (réseau connu)
    Process { id: _nmUp; command: [] }

    // Connexion nouveau réseau avec ou sans mdp
    Process { id: _nmNew; command: [] }

    // Déconnexion
    Process {
        id: _nmDisc
        command: ["sh", "-c",
        "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device 2>/dev/null | grep ':wifi' | cut -d: -f1 | head -1) 2>/dev/null"]
    }

    Process { id: _nmSettings; command: ["nm-connection-editor"] }

    Timer {
        id: _refresh; interval: 2500; running: false; repeat: false
        onTriggered: _nmAll.running = true
    }

    Timer {
        interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true
        onTriggered: { _nmRadio.running = true; _nmAll.running = true }
    }

    function connectKnown(profile) {
        // Connexion par nom de profil nmcli (pas SSID) — plus fiable
        _nmUp.command = ["nmcli", "connection", "up", profile]
        _nmUp.running = true
        _refresh.restart()
    }

    function connectNew(ssid, pwd) {
        if (pwd !== "")
            _nmNew.command = ["nmcli", "device", "wifi", "connect", ssid, "password", pwd]
            else
                _nmNew.command = ["nmcli", "device", "wifi", "connect", ssid]
                _nmNew.running = true
                root.pwdIndex = -1
                _refresh.restart()
    }

    // ── UI ────────────────────────────────────────────────
    Item {
        id: _hdr
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._headerH

        Text {
            anchors.left: parent.left; anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi"; font.pixelSize: 16; font.weight: Font.Bold
            font.family: "SF Pro Display"; color: "#fff"
        }

        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 50; height: 28; radius: 14
            color: root.wifiOn ? "#1C7AFF" : Qt.rgba(1,1,1,0.22)
            Behavior on color { ColorAnimation { duration: 200 } }
            Rectangle {
                width: 22; height: 22; radius: 11; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.wifiOn ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.wifiOn = !root.wifiOn
                    if (root.wifiOn) _nmOn.running = true
                        else            _nmOff.running = true
                }
            }
        }
    }

    /*Rectangle {
        id: _sep1
        anchors.top: _hdr.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 30; height: 0
        color: "transparent"
    }*/

    Column {
        anchors.top: _hdr.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // ── Connecté ──────────────────────────────────────
        Item {
            width: parent.width
            height: root.activeNet ? root._labelH : 0
            visible: root.activeNet !== null
            Text {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "Connecté"; font.pixelSize: 11; font.weight: Font.Medium
                font.family: "SF Pro Display"; color: Qt.rgba(1,1,1,0.50)
            }
        }

        NetRow {
            width: parent.width
            height: root.activeNet ? root._rowH : 0
            visible: root.activeNet !== null
            ssid:     root.activeNet ? root.activeNet.ssid : ""
            isActive: true
            showPwd:  false
            onConnect: _nmDisc.running = true
        }

        // ── Connus ────────────────────────────────────────
        Item {
            width: parent.width
            height: root.knownNets.length > 0 ? root._labelH : 0
            visible: root.knownNets.length > 0
            Text {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "Réseaux connus"; font.pixelSize: 11; font.weight: Font.Medium
                font.family: "SF Pro Display"; color: Qt.rgba(1,1,1,0.50)
            }
        }

        Repeater {
            model: root.knownNets
            delegate: NetRow {
                required property var modelData
                required property int index
                width: parent.width; height: root._rowH
                ssid:    modelData.ssid
                showPwd: false
                // Tap = connexion directe via nom de profil (pas de mdp requis)
                onConnect: root.connectKnown(modelData.profile)
            }
        }

        // ── Séparateur + Disponibles ──────────────────────
        Rectangle {
            width: parent.width - 36; height: 1; x: 18
            color: Qt.rgba(1,1,1,0.10)
        }

        Item {
            width: parent.width; height: root._labelH
            Text {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "Disponibles"; font.pixelSize: 11; font.weight: Font.Medium
                font.family: "SF Pro Display"; color: Qt.rgba(1,1,1,0.50)
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "›"; font.pixelSize: 20; color: Qt.rgba(1,1,1,0.40)
                rotation: root.otherShown ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.otherShown = !root.otherShown
            }
        }

        Repeater {
            model: root.otherShown ? root.otherNets : []
            delegate: NetRow {
                required property var modelData
                required property int index
                width: parent.width
                height: root.pwdIndex === index ? root._pwdH : root._rowH
                ssid:    modelData.ssid
                secured: modelData.secured
                showPwd: root.pwdIndex === index
                onConnect: {
                    if (modelData.secured)
                        root.pwdIndex = (root.pwdIndex === index) ? -1 : index
                        else
                            root.connectNew(modelData.ssid, "")
                }
                onConnectPwd: function(pwd) { root.connectNew(modelData.ssid, pwd) }
            }
        }

        Rectangle {
            width: parent.width - 36; height: 1; x: 18
            color: Qt.rgba(1,1,1,0.10)
        }

        Item {
            width: parent.width; height: root._footerH
            Text {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "Paramètres Wi-Fi…"; font.pixelSize: 13
                font.family: "SF Pro Display"; color: Qt.rgba(1,1,1,0.65)
            }
            MouseArea {
                anchors.fill: parent
                onClicked:  _nmSettings.running = true
                onPressed:  parent.opacity = 0.6
                onReleased: parent.opacity = 1.0
            }
        }
        Item { width: 1; height: 8 }
    }

    // ── Composant NetRow ──────────────────────────────────
    component NetRow: Item {
        id: _nr
        property string ssid:     ""
        property bool   isActive: false
        property bool   secured:  false
        property bool   showPwd:  false
        property bool   _hov:     false

        signal connect()
        signal connectPwd(string pwd)

        clip: true

        onShowPwdChanged: {
            if (showPwd) { _pwdInput.forceActiveFocus(); _pwdInput.text = "" }
        }

        Rectangle {
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 10; anchors.rightMargin: 10
            radius: 10
            color: _nr._hov ? Qt.rgba(1,1,1,0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Rectangle {
            id: _ic
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.top: parent.top; anchors.topMargin: 8
            width: 30; height: 30; radius: 15
            color: _nr.isActive ? "#1C7AFF" : Qt.rgba(1,1,1,0.16)
            Behavior on color { ColorAnimation { duration: 200 } }
            VectorImage {
                anchors.centerIn: parent; width: 18; height: 14
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/wifi/wifi.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1; colorizationColor: "#fff" }
            }
        }

        Column {
            anchors.left: _ic.right; anchors.leftMargin: 10
            anchors.verticalCenter: _ic.verticalCenter
            spacing: 2
            Text {
                text: _nr.ssid; font.pixelSize: 13; font.family: "SF Pro Display"
                color: "#fff"; elide: Text.ElideRight; width: _nr.width - 120
            }
            Text {
                visible: _nr.isActive
                text: "Connecté"; font.pixelSize: 10; font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.50)
            }
        }

        Text {
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: _ic.verticalCenter
            visible: _nr.isActive
            text: "✓"; font.pixelSize: 15; font.weight: Font.Bold; color: "#1C7AFF"
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: _ic.verticalCenter
            visible: !_nr.isActive && _nr.secured
            text: "🔒"; font.pixelSize: 11; opacity: 0.55
        }

        Rectangle {
            id: _pwdRect
            anchors.left: _ic.right; anchors.leftMargin: 10
            anchors.bottom: parent.bottom; anchors.bottomMargin: 8
            anchors.right: _joinBtn.left; anchors.rightMargin: 8
            visible: _nr.showPwd; height: 26; radius: 8
            color: Qt.rgba(0.15, 0.16, 0.20, 0.95)
            border.color: Qt.rgba(1,1,1,0.22); border.width: 0.8
            MouseArea { anchors.fill: parent; onClicked: _pwdInput.forceActiveFocus() }
            TextInput {
                id: _pwdInput
                anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 10; anchors.rightMargin: 6
                focus: true; activeFocusOnPress: true
                echoMode: TextInput.Password; passwordCharacter: "•"
                font.pixelSize: 13; font.family: "SF Pro Display"
                color: "#fff"; selectionColor: "#1C7AFF"; selectedTextColor: "#fff"
                verticalAlignment: TextInput.AlignVCenter; clip: true
                onAccepted: _nr.connectPwd(_pwdInput.text)
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "Mot de passe"; font.pixelSize: 13
                    font.family: "SF Pro Display"; color: Qt.rgba(1,1,1,0.35)
                    visible: _pwdInput.text === ""; z: -1
                }
            }
        }

        Rectangle {
            id: _joinBtn
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.bottom: parent.bottom; anchors.bottomMargin: 8
            visible: _nr.showPwd; width: 70; height: 26; radius: 8; color: "#1C7AFF"
            Text { anchors.centerIn: parent; text: "Rejoindre"; font.pixelSize: 11; font.weight: Font.Medium; font.family: "SF Pro Display"; color: "#fff" }
            MouseArea { anchors.fill: parent; onClicked: _nr.connectPwd(_pwdInput.text); onPressed: _joinBtn.opacity = 0.75; onReleased: _joinBtn.opacity = 1.0 }
        }

        MouseArea {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: _nr.showPwd ? _pwdRect.top : parent.bottom
            hoverEnabled: true
            onEntered: _nr._hov = true; onExited: _nr._hov = false
            onClicked: _nr.connect()
        }
    }
}
