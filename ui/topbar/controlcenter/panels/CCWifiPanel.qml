import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core.network
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    signal closeRequested()

    readonly property int rowHeight:       44
    readonly property int iconSize:        20
    readonly property int maxScrollHeight: 360

    property string _passwordForSSID:  ""
    property string _connectingSSID:   ""
    property string _disconnectingSSID: ""
    property bool needsKeyboard:       _passwordForSSID !== ""
    property var  _failedSSIDs:        ({})

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

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            if (!NetworkManager.busy) {
                NetworkManager.refresh()
            }
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
            if (!NetworkManager.busy) {
                root._connectingSSID = ""
            }
        }
    }

    implicitHeight: _layout.implicitHeight

    ColumnLayout {
        id: _layout
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   parent.top
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.topMargin: 10
            height: 54

            CFText {
                text:           "Wi-Fi"
                font.weight:    Font.Bold
                font.pixelSize: 18
                anchors.left:           parent.left
                anchors.leftMargin:     20
                anchors.verticalCenter: parent.verticalCenter
            }

            CFSwitch {
                anchors.right:          parent.right
                anchors.rightMargin:    15
                anchors.verticalCenter: parent.verticalCenter
                checked: NetworkManager.wifiEnabled
                onCheckedChanged: NetworkManager.enableWifi(checked)
            }
        }

        Rectangle {
            Layout.fillWidth:            true
            Layout.leftMargin:           20
            Layout.rightMargin:          20
            height: 1
            color:  "#20ffffff"
        }

        ScrollView {
            id: _scrollArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(_col.implicitHeight, root.maxScrollHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ScrollBar.vertical: ScrollBar {
                id: _vbar
                parent: _scrollArea
                x: _scrollArea.width - width
                width: 4
                policy: ScrollBar.AsNeeded

                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#50ffffff"
                    opacity: _vbar.pressed ? 0.9 : (_vbar.hovered ? 0.7 : 0.0)
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                background: Item {}
            }

            Column {
                id: _col
                width:   _scrollArea.width
                spacing: 0

                Item { width: parent.width; height: 10 }

                CFText {
                    text:          "Connecté"
                    font.pixelSize: 13
                    gray:           true
                    visible:        NetworkManager.active !== null
                    leftPadding:    20
                    bottomPadding:  4
                }

                NetRow {
                    width:    parent.width
                    net:      NetworkManager.active
                    isActive: true
                    visible:  NetworkManager.active !== null
                }

                Item { width: parent.width; height: NetworkManager.networksKnown.length > 0 ? 8 : 0 }

                CFText {
                    text:           "Réseaux connus"
                    font.pixelSize: 13
                    gray:           true
                    visible:        NetworkManager.networksKnown.filter(function(n) { return !n.active }).length > 0
                    leftPadding:    20
                    bottomPadding:  4
                }

                Repeater {
                    model: NetworkManager.networksKnown.filter(function(n) { return !n.active })
                    delegate: NetRow {
                        required property var modelData
                        width:    parent.width
                        net:      modelData
                        isActive: false
                    }
                }

                Item { width: parent.width; height: 8 }

                Rectangle {
                    width:   parent.width - 40
                    height:  1
                    color:   "#10ffffff"
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: _otherNets.count > 0
                }

                Item {
                    id:      _otherHeader
                    width:   parent.width
                    height:  38
                    visible: _otherNets.count > 0
                    property bool _shown: false

                    CFText {
                        text:           "Autres réseaux"
                        font.pixelSize: 13
                        gray:           true
                        anchors.left:           parent.left
                        anchors.leftMargin:     20
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    CFVI {
                        anchors.right:          parent.right
                        anchors.rightMargin:    20
                        anchors.verticalCenter: parent.verticalCenter
                        icon:     "chevron-right.svg"
                        size:     14
                        rotation: _otherHeader._shown ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    _otherHeader._shown = !_otherHeader._shown
                    }
                }

                Column {
                    width:   parent.width
                    visible: _otherHeader._shown
                    spacing: 0

                    Repeater {
                        id: _otherNets
                        model: NetworkManager.networks.filter(function(n) {
                            return !n.active && NetworkManager.networksKnown.indexOf(n) === -1
                        })
                        delegate: NetRow {
                            required property var modelData
                            width:    parent.width
                            net:      modelData
                            isActive: false
                        }
                    }
                }

                Item { width: parent.width; height: 8 }
            }
        }

        Rectangle {
            Layout.fillWidth:   true
            Layout.leftMargin:  20
            Layout.rightMargin: 20
            height: 1
            color:  "#10ffffff"
        }

        Item {
            Layout.fillWidth: true
            height: 44

            CFText {
                text:           "Paramètres Wi-Fi…"
                font.pixelSize: 14
                gray:           true
                anchors.left:           parent.left
                anchors.leftMargin:     20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component NetRow: Item {
        id:           _nr
        property var  net:      null
        property bool isActive: false
        property bool _hovered: false

        readonly property string signalIcon: {
            var s = _nr.net ? (_nr.net.strength || 0) : 0
            if (s >= 80) return "wifi/nm-signal-100-symbolic.svg"
            if (s >= 55) return "wifi/nm-signal-66-symbolic.svg"
            if (s >= 25) return "wifi/nm-signal-33-symbolic.svg"
            return "wifi/nm-signal-0-symbolic.svg"
        }

        readonly property bool _showPassword: !isActive
                                              && net !== null
                                              && net.isSecure
                                              && root._passwordForSSID === net.ssid

        readonly property bool _showError: _nr.net
                                           && root._failedSSIDs[_nr.net.ssid] === true
                                           && _nr._showPassword

        height: _showPassword ? rowHeight + (_showError ? 68 : 48) : rowHeight
        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
        }

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 4
            radius:          10
            color:           _nr._hovered && !_nr._showPassword ? "#15ffffff" : "transparent"
        }

        RowLayout {
            id:                  _row
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.top:         parent.top
            anchors.leftMargin:  20
            anchors.rightMargin: 20
            height:              rowHeight
            spacing:             14

            Rectangle {
                width:  30
                height: 30
                radius: 15
                color:  _nr.isActive ? "#fff" : "#25ffffff"
                CFVI {
                    anchors.centerIn: parent
                    icon:  _nr.signalIcon
                    size:  root.iconSize
                    color: _nr.isActive ? "#1C7AFF" : "#fff"
                }
            }

            CFText {
                text:             _nr.net ? _nr.net.ssid : ""
                font.pixelSize:   14
                Layout.fillWidth: true
                elide:            Text.ElideRight
            }

            CFText {
                text:           "Déconnexion…"
                font.pixelSize: 12
                gray:           true
                visible:        _nr.isActive && _nr.net && root._disconnectingSSID === _nr.net.ssid
            }

            CFText {
                text:           "Connexion…"
                font.pixelSize: 12
                gray:           true
                visible:        !_nr.isActive && _nr.net && root._connectingSSID === _nr.net.ssid
            }

            CFVI {
                icon:    "lock.svg"
                size:    13
                visible: _nr.net && _nr.net.isSecure
                gray:    true
            }
        }

        Item {
            id:                  _pwArea
            anchors.top:         _row.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  20
            anchors.rightMargin: 20
            height:              _nr._showError ? 64 : 44
            visible:             _nr._showPassword
            opacity:             _nr._showPassword ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 160 } }

            CFText {
                id: _errorText
                visible:        _nr._showError
                text:           "Mot de passe incorrect, réessayez"
                color:          "#FF6B6B"
                font.pixelSize: 11
                anchors.top:        parent.top
                anchors.left:       parent.left
                bottomPadding:      6
            }

            TextField {
                id: _pwField
                anchors.top:             _nr._showError ? _errorText.bottom : parent.top
                anchors.left:            parent.left
                anchors.right:           _joinBtn.left
                anchors.rightMargin:     8
                height:                  32
                echoMode:                TextInput.Password
                placeholderText:         "Mot de passe"
                color:                   "#ffffff"
                font.pixelSize:          13
                font.family:             "SF Pro Rounded"
                renderType:              Text.NativeRendering
                selectionColor:          "#50ffffff"
                selectedTextColor:       "#ffffff"
                placeholderTextColor:    "#60ffffff"
                background: Rectangle {
                    radius:       8
                    color:        Qt.rgba(1, 1, 1, 0.12)
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
                id:              _joinBtn
                anchors.top:     _pwField.top
                anchors.right:   parent.right
                width:  72
                height: 32
                radius: 8
                color:  Qt.rgba(0.11, 0.47, 1, 0.85)

                CFText {
                    anchors.centerIn: parent
                    text:           "Joindre"
                    font.pixelSize: 13
                    font.weight:    Font.DemiBold
                    color:          "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
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
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   parent.top
            height:        rowHeight
            hoverEnabled:  true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered:     _nr._hovered = true
            onExited:      _nr._hovered = false
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

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: root._ctxNet !== null
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeContextMenu()
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
