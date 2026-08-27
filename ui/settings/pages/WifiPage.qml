pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core.network
import qs.ui.primitives
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property int rowHeight: 44
    readonly property int iconSize:  20

    property string _passwordForSSID:   ""
    property string _connectingSSID:    ""
    property string _disconnectingSSID: ""
    property var    _failedSSIDs:       ({})

    readonly property var _knownNetworks: NetworkManager.networksKnown.filter(function(n) { return !n.active })
    readonly property var _otherNetworks: NetworkManager.networks.filter(function(n) {
        return !n.active && NetworkManager.networksKnown.indexOf(n) === -1
    })

    Timer {
        interval: 4000
        running:  true
        repeat:   true
        onTriggered: {
            var interacting = root._passwordForSSID !== "" || root._ctxNet !== null || root._detailsOpen
            if (!NetworkManager.busy && !interacting) NetworkManager.refresh()
        }
    }

    Connections {
        target: NetworkManager
        function onActiveChanged() {
            if (NetworkManager.active !== null) {
                root._disconnectingSSID = ""
                if (NetworkManager.active.ssid) {
                    delete root._failedSSIDs[NetworkManager.active.ssid]
                    root._failedSSIDsChanged()
                }
                root._passwordForSSID = ""
            }
        }
        function onConnectionFailed(ssid) {
            root._failedSSIDs[ssid] = true
            root._failedSSIDsChanged()
            root._passwordForSSID = ssid
        }
        function onPasswordRequired(ssid) {
            root._passwordForSSID = ssid
        }
        function onBusyChanged() {
            if (!NetworkManager.busy) root._connectingSSID = ""
        }
    }

    // ---------------- Wi-Fi : toggle + réseau actif ----------------
    ContentSection {
        title: ""

        ConfigSwitch {
            text: "Wi-Fi"
            description: "Configurer le Wi-Fi pour connecter cet appareil à internet."
            checked: NetworkManager.wifiEnabled
            onToggled: function(value) { NetworkManager.enableWifi(value) }
        }

        RowLayout {
            id: _activeRow
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10
            visible: NetworkManager.wifiEnabled

            MouseArea {
                anchors.left: parent.left
                anchors.right: _detailsBtn.visible ? _detailsBtn.left : parent.right
                anchors.rightMargin: _detailsBtn.visible ? 10 : 0
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                z: 10
                hoverEnabled: true
                enabled: NetworkManager.active !== null
                cursorShape: NetworkManager.active !== null ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (NetworkManager.active) {
                        root._disconnectingSSID = NetworkManager.active.ssid
                        NetworkManager.disconnectFromNetwork()
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: NetworkManager.active ? "#fff" : "#25ffffff"

                CFVI {
                    anchors.centerIn: parent
                    icon: root._signalIcon(NetworkManager.active)
                    size: root.iconSize
                    color: NetworkManager.active ? "#1C7AFF" : "#fff"
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                CFText {
                    text: NetworkManager.active ? NetworkManager.active.ssid
                          : (NetworkManager.wifiEnabled ? "Non connecté" : "Wi-Fi désactivé")
                    font.pixelSize: 14
                    color: "#fff"
                }

                CFText {
                    text: NetworkManager.active ? "Connecté" : ""
                    font.pixelSize: 12
                    color: "#4CD964"
                    visible: NetworkManager.active !== null
                }
            }

            CFVI {
                icon: "lock.svg"
                size: 13
                gray: true
                visible: NetworkManager.active && NetworkManager.active.isSecure
            }

            Rectangle {
                id: _detailsBtn
                visible: NetworkManager.active !== null
                Layout.preferredWidth: 70
                Layout.preferredHeight: 28
                radius: 8
                color: _detailsBtnMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Détails…"
                    font.pixelSize: 12
                    color: "#fff"
                }

                MouseArea {
                    id: _detailsBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (NetworkManager.active) {
                            root.openDetails(NetworkManager.active.ssid)
                        }
                    }
                }
            }
        }
    }

    // ---------------- Réseaux connus ----------------
    ContentSection {
        title: "Réseau connu"
        visible: NetworkManager.wifiEnabled && root._knownNetworks.length > 0

        Repeater {
            model: root._knownNetworks
            delegate: NetRow {
                required property var modelData
                Layout.fillWidth: true
                net: modelData
                isActive: false
            }
        }
    }

    // ---------------- Autres réseaux ----------------
    ContentSection {
        title: "Autres réseaux"
        visible: NetworkManager.wifiEnabled && _otherNets.count > 0

        Repeater {
            id: _otherNets
            model: root._otherNetworks
            delegate: NetRow {
                required property var modelData
                Layout.fillWidth: true
                net: modelData
                isActive: false
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 76
                Layout.preferredHeight: 28
                radius: 8
                color: _otherBtnMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Autre…"
                    font.pixelSize: 12
                    color: "#fff"
                }

                MouseArea {
                    id: _otherBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openManualJoin()
                }
            }
        }
    }

    // ---------------- Options de jointure automatique ----------------
    ContentSection {
        title: ""

        ConfigSwitch {
            text: "Demander à rejoindre les réseaux"
            description: "Les réseaux connus sont rejoints automatiquement. Si aucun réseau connu n'est disponible, vous devrez en choisir un manuellement."
            checked: false
        }

        ConfigSwitch {
            text: "Demander à rejoindre les points d'accès"
            description: "Permettre à cet appareil de découvrir automatiquement les points d'accès personnels à proximité quand aucun réseau Wi-Fi n'est disponible."
            checked: false
        }
    }

    function _signalIcon(net) {
        var s = net ? (net.strength || 0) : 0
        if (s >= 80) return "wifi/nm-signal-100-symbolic.svg"
        if (s >= 55) return "wifi/nm-signal-66-symbolic.svg"
        if (s >= 25) return "wifi/nm-signal-33-symbolic.svg"
        return "wifi/nm-signal-0-symbolic.svg"
    }

    property var  _ctxNet: null
    property real _ctxX: 0
    property real _ctxY: 0

    function openContextMenu(net, x, y) {
        root._ctxNet = net
        root._ctxX = x
        root._ctxY = y
    }

    function closeContextMenu() {
        root._ctxNet = null
    }

    property bool _detailsOpen: false

    function openDetails(ssid) {
        root._detailsOpen = true
        NetworkManager.fetchConnectionDetails(ssid)
    }

    function closeDetails() {
        root._detailsOpen = false
        NetworkManager.clearConnectionDetails()
    }

    property bool   _manualJoinOpen: false
    property string _manualSSID:     ""
    property string _manualPassword: ""
    property bool   _manualSecure:   true
    property bool   _manualError:    false

    function openManualJoin() {
        root._manualSSID     = ""
        root._manualPassword = ""
        root._manualSecure   = true
        root._manualError    = false
        root._manualJoinOpen = true
    }

    function closeManualJoin() {
        root._manualJoinOpen = false
    }

    function submitManualJoin() {
        if (root._manualSSID.trim().length === 0) {
            root._manualError = true
            return
        }
        root._connectingSSID = root._manualSSID
        NetworkManager.connectToNetwork(root._manualSSID, root._manualSecure ? root._manualPassword : "")
        root.closeManualJoin()
    }

    component NetRow: Item {
        id: _nr
        property var  net:      null
        property bool isActive: false
        property bool _hovered: false

        readonly property string signalIcon: root._signalIcon(_nr.net)

        readonly property bool _showPassword: !isActive
                                              && net !== null
                                              && net.isSecure
                                              && root._passwordForSSID === net.ssid

        readonly property bool _showError: _nr.net
                                           && root._failedSSIDs[_nr.net.ssid] === true
                                           && _nr._showPassword

        Layout.preferredHeight: _showPassword ? root.rowHeight + _pwArea.height : root.rowHeight

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 4
            radius:          10
            color:           _nr._hovered && !_nr._showPassword ? "#15ffffff" : "transparent"
        }

        RowLayout {
            id: _row
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   parent.top
            height: root.rowHeight
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 15
                color: _nr.isActive ? "#fff" : "#25ffffff"

                CFVI {
                    anchors.centerIn: parent
                    icon: _nr.signalIcon
                    size: root.iconSize
                    color: _nr.isActive ? "#1C7AFF" : "#fff"
                }
            }

            CFText {
                text: _nr.net ? _nr.net.ssid : ""
                font.pixelSize: 14
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            CFText {
                text: "Déconnexion…"
                font.pixelSize: 12
                gray: true
                visible: _nr.isActive && _nr.net && root._disconnectingSSID === _nr.net.ssid
            }

            CFText {
                text: "Connexion…"
                font.pixelSize: 12
                gray: true
                visible: !_nr.isActive && _nr.net && root._connectingSSID === _nr.net.ssid
            }

            CFVI {
                icon: "lock.svg"
                size: 13
                visible: _nr.net && _nr.net.isSecure
                gray: true
            }
        }

        Item {
            id: _pwArea
            anchors.top:   _row.bottom
            anchors.left:  parent.left
            anchors.right: parent.right
            height: (_nr._showError ? _errorText.implicitHeight + _errorText.bottomPadding : 0) + _pwField.height + 8
            visible: _nr._showPassword
            opacity: _nr._showPassword ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 160 } }

            CFText {
                id: _errorText
                visible: _nr._showError
                text: "Mot de passe incorrect, réessayez"
                color: "#FF6B6B"
                font.pixelSize: 11
                anchors.top:  parent.top
                anchors.left: parent.left
                bottomPadding: 6
            }

            TextField {
                id: _pwField
                anchors.top: _nr._showError ? _errorText.bottom : parent.top
                anchors.left: parent.left
                anchors.right: _joinBtn.left
                anchors.rightMargin: 8
                height: 32
                echoMode: TextInput.Password
                placeholderText: "Mot de passe"
                color: "#ffffff"
                font.pixelSize: 13
                renderType: Text.NativeRendering
                selectionColor: "#50ffffff"
                selectedTextColor: "#ffffff"
                placeholderTextColor: "#60ffffff"
                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.12)
                    border.color: _nr._showError ? Qt.rgba(1, 0.42, 0.42, 0.5) : Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                }
                onAccepted: {
                    if (_nr.net) {
                        root._connectingSSID  = _nr.net.ssid
                        root._passwordForSSID = ""
                        NetworkManager.connectToNetwork(_nr.net.ssid, text)
                        text = ""
                    }
                }
                onVisibleChanged: {
                    if (visible) forceActiveFocus()
                }
            }

            Rectangle {
                id: _joinBtn
                anchors.top: _pwField.top
                anchors.right: parent.right
                width: 72
                height: 32
                radius: 8
                color: _joinBtnMouse.containsMouse ? Qt.rgba(0.15, 0.51, 1, 0.9) : Qt.rgba(0.11, 0.47, 1, 0.85)
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Joindre"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                }

                MouseArea {
                    id: _joinBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (_nr.net) {
                            root._connectingSSID  = _nr.net.ssid
                            root._passwordForSSID = ""
                            NetworkManager.connectToNetwork(_nr.net.ssid, _pwField.text)
                            _pwField.text = ""
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: _row.bottom
            z: 10
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: _nr._hovered = true
            onExited:  _nr._hovered = false
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    if (!_nr.net) return
                    var pos = _nr.mapToItem(root, mouse.x, mouse.y)
                    root.openContextMenu(_nr.net, pos.x, pos.y)
                    return
                }
                if (_nr.isActive) {
                    if (_nr.net) root._disconnectingSSID = _nr.net.ssid
                    NetworkManager.disconnectFromNetwork()
                    return
                }
                var isKnown  = NetworkManager.networksKnown.indexOf(_nr.net) !== -1
                var isFailed = _nr.net && root._failedSSIDs[_nr.net.ssid] === true
                if (_nr.net && (_nr.net.isSecure && !isKnown || isFailed)) {
                    root._passwordForSSID = (root._passwordForSSID === _nr.net.ssid)
                                             ? "" : _nr.net.ssid
                } else if (_nr.net) {
                    root._connectingSSID = _nr.net.ssid
                    NetworkManager.connectToNetwork(_nr.net.ssid, "")
                }
            }
        }
    }

    component CtxItem: Rectangle {
        id: _ci
        property string label: ""
        property bool destructive: false
        signal activated()
        width: parent.width
        height: 32
        radius: 6
        property bool _hov: false
        color: _ci._hov ? "#18ffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        CFText {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: _ci.label
            font.pixelSize: 13
            font.weight: Font.Bold
            color: _ci.destructive ? "#FF6B6B" : "#fff"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: _ci._hov = true
            onExited:  _ci._hov = false
            onClicked: {
                _ci.activated()
                root.closeContextMenu()
            }
        }
    }

    Loader {
        parent: root
        anchors.fill: parent
        active: root._ctxNet !== null
        z: 1000

        sourceComponent: Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeContextMenu()
                onWheel: function(wheel) { wheel.accepted = true }
            }

            Rectangle {
                id: _wifiCtxMenu
                x: Math.min(root._ctxX, root.width - width - 8)
                y: root._ctxY
                width: 170
                radius: 10
                color: "#e6202020"
                border.color: "#20ffffff"
                border.width: 1
                implicitHeight: _wifiCtxCol.implicitHeight + 8
                height: implicitHeight

                Column {
                    id: _wifiCtxCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 4
                    spacing: 2

                    CtxItem {
                        label: root._ctxNet && root._ctxNet.active ? "Déconnecter" : "Connecter"
                        onActivated: {
                            if (!root._ctxNet) return
                            if (root._ctxNet.active) {
                                root._disconnectingSSID = root._ctxNet.ssid
                                NetworkManager.disconnectFromNetwork()
                            } else {
                                root._connectingSSID = root._ctxNet.ssid
                                NetworkManager.connectToNetwork(root._ctxNet.ssid, "")
                            }
                        }
                    }

                    CtxItem {
                        visible: root._ctxNet && NetworkManager.networksKnown.indexOf(root._ctxNet) !== -1
                        height: visible ? 32 : 0
                        label: "Oublier ce réseau"
                        destructive: true
                        onActivated: {
                            if (root._ctxNet) {
                                NetworkManager.forgetNetwork(root._ctxNet.ssid)
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        parent: root
        anchors.fill: parent
        active: root._detailsOpen
        z: 9999

        sourceComponent: Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeDetails()
                onWheel: function(wheel) { wheel.accepted = true }
            }

            Rectangle {
                id: _detailsCard
            width: Math.min(560, root.width - 32)
            height: _detailsCol.implicitHeight + 32
            anchors.centerIn: parent
            radius: 14
            color: "#e6202020"
            border.color: "#20ffffff"
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: _detailsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: "#fff"

                        CFVI {
                            anchors.centerIn: parent
                            icon: root._signalIcon(NetworkManager.active && NetworkManager.active.ssid === NetworkManager.detailsSSID ? NetworkManager.active : null)
                            size: 16
                            color: "#1C7AFF"
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        CFText {
                            text: NetworkManager.detailsSSID
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        CFText {
                            text: NetworkManager.active && NetworkManager.active.ssid === NetworkManager.detailsSSID ? "Connecté" : "Non connecté"
                            font.pixelSize: 12
                            color: NetworkManager.active && NetworkManager.active.ssid === NetworkManager.detailsSSID ? "#4CD964" : "#888"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 11
                        color: _closeBtnMouse.containsMouse ? "#18ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        CFVI {
                            anchors.centerIn: parent
                            icon: "x.svg"
                            size: 12
                            gray: true
                        }

                        MouseArea {
                            id: _closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeDetails()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#18ffffff"
                }

                CFText {
                    text: "Analyse en cours…"
                    font.pixelSize: 12
                    gray: true
                    visible: NetworkManager.detailsLoading
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !NetworkManager.detailsLoading

                    component DetailRow: RowLayout {
                        property string label: ""
                        property string value: ""
                        Layout.fillWidth: true
                        visible: value.length > 0

                        CFText {
                            text: label
                            font.pixelSize: 12
                            gray: true
                            Layout.preferredWidth: 150
                        }

                        CFText {
                            text: value
                            font.pixelSize: 12
                            color: "#fff"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    component DetailDropdown: RowLayout {
                        id: _ddRoot
                        property string label: ""
                        property string value: ""
                        Layout.fillWidth: true

                        CFText {
                            text: _ddRoot.label
                            font.pixelSize: 12
                            gray: true
                            Layout.preferredWidth: 150
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            radius: 6
                            color: "#14ffffff"
                            border.color: "#18ffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 4

                                CFText {
                                    text: _ddRoot.value
                                    font.pixelSize: 12
                                    color: "#fff"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                CFVI {
                                    icon: "chevron-down.svg"
                                    size: 9
                                    gray: true
                                }
                            }
                        }
                    }

                    CFText {
                        text: "Configuration IPv4"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        gray: true
                        Layout.topMargin: 4
                    }

                    DetailDropdown { label: "Configurer IPv4"; value: NetworkManager.detailsIPv4Method.length > 0 ? NetworkManager.detailsIPv4Method : "Utilisation du DHCP" }
                    DetailRow { label: "Adresse IP";              value: NetworkManager.detailsIPv4 }
                    DetailRow { label: "Masque de sous-réseau";   value: NetworkManager.detailsSubnet }
                    DetailRow { label: "Routeur";                 value: NetworkManager.detailsRouter }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            Layout.preferredHeight: 28
                            radius: 7
                            color: _renewBtnMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                            border.color: "#14ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            CFText {
                                anchors.centerIn: parent
                                text: "Renouveler le bail DHCP"
                                font.pixelSize: 12
                                color: "#fff"
                            }

                            MouseArea {
                                id: _renewBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkManager.renewDhcpLease(NetworkManager.detailsSSID)
                            }
                        }
                    }

                    DetailRow { label: "ID client DHCP (si requis)"; value: "" }

                    CFText {
                        text: "Configuration IPv6"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        gray: true
                        Layout.topMargin: 8
                    }

                    DetailDropdown { label: "Configurer IPv6"; value: NetworkManager.detailsIPv6Method.length > 0 ? NetworkManager.detailsIPv6Method : "Automatiquement" }
                    DetailRow { label: "Adresse IPv6"; value: NetworkManager.detailsIPv6 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: "#18ffffff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: _forgetLabel.implicitWidth + 24
                        Layout.preferredHeight: 28
                        radius: 7
                        color: _forgetBtnMouse.containsMouse ? "#14FF6B6B" : "transparent"
                        border.color: "#20ffffff"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        CFText {
                            id: _forgetLabel
                            anchors.centerIn: parent
                            text: "Oublier ce réseau…"
                            font.pixelSize: 12
                            color: "#FF6B6B"
                        }

                        MouseArea {
                            id: _forgetBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkManager.forgetNetwork(NetworkManager.detailsSSID)
                                root.closeDetails()
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 28
                        radius: 7
                        color: _cancelBtnMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        CFText {
                            anchors.centerIn: parent
                            text: "Annuler"
                            font.pixelSize: 12
                            color: "#fff"
                        }

                        MouseArea {
                            id: _cancelBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeDetails()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 28
                        radius: 7
                        color: _okBtnMouse.containsMouse ? Qt.rgba(0.15, 0.51, 1, 1) : "#1C7AFF"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        CFText {
                            anchors.centerIn: parent
                            text: "OK"
                            font.pixelSize: 12
                            color: "#fff"
                        }

                        MouseArea {
                            id: _okBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeDetails()
                        }
                    }
                }
            }
        }
        }
    }

    Loader {
        parent: root
        anchors.fill: parent
        active: root._manualJoinOpen
        z: 9999

        sourceComponent: Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeManualJoin()
                onWheel: function(wheel) { wheel.accepted = true }
            }

            Rectangle {
                id: _manualCard
                width: Math.min(380, root.width - 32)
                height: _manualCol.implicitHeight + 32
                anchors.centerIn: parent
                radius: 14
                color: "#e6202020"
                border.color: "#20ffffff"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: _manualCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20
                    spacing: 14

                    CFText {
                        text: "Autre réseau"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    CFText {
                        text: "Saisissez le nom d'un réseau Wi-Fi non diffusé."
                        font.pixelSize: 12
                        gray: true
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 4

                        CFText {
                            text: "Nom du réseau"
                            font.pixelSize: 11
                            gray: true
                        }

                        TextField {
                            id: _ssidField
                            width: parent.width
                            height: 32
                            text: root._manualSSID
                            onTextChanged: {
                                root._manualSSID = text
                                if (text.trim().length > 0) root._manualError = false
                            }
                            placeholderText: "Nom du réseau"
                            color: "#ffffff"
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                            selectionColor: "#50ffffff"
                            selectedTextColor: "#ffffff"
                            placeholderTextColor: "#60ffffff"
                            background: Rectangle {
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.12)
                                border.color: root._manualError ? Qt.rgba(1, 0.42, 0.42, 0.5) : Qt.rgba(1, 1, 1, 0.18)
                                border.width: 1
                            }
                        }

                        CFText {
                            text: "Un nom de réseau est requis"
                            font.pixelSize: 11
                            color: "#FF6B6B"
                            visible: root._manualError
                        }
                    }

                    ConfigSwitch {
                        text: "Réseau sécurisé"
                        checked: root._manualSecure
                        onToggled: function(v) { root._manualSecure = v }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root._manualSecure

                        CFText {
                            text: "Mot de passe"
                            font.pixelSize: 11
                            gray: true
                        }

                        TextField {
                            id: _manualPwField
                            width: parent.width
                            height: 32
                            text: root._manualPassword
                            onTextChanged: root._manualPassword = text
                            echoMode: TextInput.Password
                            placeholderText: "Mot de passe"
                            color: "#ffffff"
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                            selectionColor: "#50ffffff"
                            selectedTextColor: "#ffffff"
                            placeholderTextColor: "#60ffffff"
                            background: Rectangle {
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.18)
                                border.width: 1
                            }
                            Keys.onReturnPressed: root.submitManualJoin()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 28
                            radius: 7
                            color: _manualCancelMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                            border.color: "#14ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            CFText {
                                anchors.centerIn: parent
                                text: "Annuler"
                                font.pixelSize: 12
                                color: "#fff"
                            }

                            MouseArea {
                                id: _manualCancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeManualJoin()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 28
                            radius: 7
                            color: _manualJoinMouse.containsMouse ? Qt.rgba(0.15, 0.51, 1, 1) : "#1C7AFF"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            CFText {
                                anchors.centerIn: parent
                                text: "Joindre"
                                font.pixelSize: 12
                                color: "#fff"
                            }

                            MouseArea {
                                id: _manualJoinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitManualJoin()
                            }
                        }
                    }
                }
            }
        }
    }
}
