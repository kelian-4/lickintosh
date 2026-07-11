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

    readonly property int rowHeight: 44
    readonly property int iconSize:  20

    property int  _passwordForIndex: -1
    property bool _disconnecting:    false
    property bool needsKeyboard:     _passwordForIndex !== -1
    property var  _failedSSIDs:      ({})

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: NetworkManager.refresh()
    }

    Connections {
        target: NetworkManager
        function onActiveChanged() {
            if (NetworkManager.active !== null) {
                root._disconnecting = false
                if (NetworkManager.active.ssid) {
                    delete root._failedSSIDs[NetworkManager.active.ssid]
                    root._failedSSIDsChanged()
                }
                root._passwordForIndex = -1
            }
        }
        function onConnectionFailed(ssid) {
            root._failedSSIDs[ssid] = true
            root._failedSSIDsChanged()
            var nets = NetworkManager.networks
            for (var i = 0; i < nets.length; i++) {
                if (nets[i].ssid === ssid) {
                    var isKnown = NetworkManager.networksKnown.indexOf(nets[i]) !== -1
                    root._passwordForIndex = isKnown ? i : 10000 + i
                    break
                }
            }
        }
    }

    implicitHeight: _col.implicitHeight + 20

    Column {
        id: _col
        width:             parent.width
        anchors.top:       parent.top
        anchors.topMargin: 10
        spacing:           0

        Item {
            width:  parent.width
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
            width:  parent.width - 40
            height: 1
            color:  "#20ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

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
            rowIndex: -1
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
                required property int index
                width:    parent.width
                net:      modelData
                isActive: false
                rowIndex: index
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
                    required property int index
                    width:    parent.width
                    net:      modelData
                    isActive: false
                    rowIndex: 10000 + index
                }
            }
        }

        Rectangle {
            width:  parent.width - 40
            height: 1
            color:  "#10ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width:  parent.width
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
        property int  rowIndex: -1
        property bool _hovered: false

        readonly property bool _showPassword: !isActive
                                              && net !== null
                                              && net.isSecure
                                              && root._passwordForIndex === rowIndex

        height: _showPassword ? rowHeight + 48 : rowHeight
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

            CFClippingRect {
                width:  30
                height: 30
                radius: 15
                color:  _nr.isActive ? "#fff" : "#25ffffff"
                CFVI {
                    anchors.centerIn: parent
                    icon:  "wifi/nm-signal-100-symbolic.svg"
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
                visible:        _nr.isActive && root._disconnecting
            }

            CFText {
                text:           "Connexion…"
                font.pixelSize: 12
                gray:           true
                visible:        !_nr.isActive && root._passwordForIndex === -2
                                && NetworkManager.active === null
            }

            CFVI {
                icon:    "lock.svg"
                size:    13
                visible: _nr.net && _nr.net.isSecure && !_nr.isActive
                         && root._passwordForIndex !== _nr.rowIndex
                gray:    true
            }

            CFText {
                text:           "✓"
                visible:        _nr.isActive && !root._disconnecting
                color:          "#1C7AFF"
                font.weight:    Font.Bold
                font.pixelSize: 16
            }
        }

        Item {
            id:                  _pwArea
            anchors.top:         _row.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  20
            anchors.rightMargin: 20
            height:              44
            visible:             _nr._showPassword
            opacity:             _nr._showPassword ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 160 } }

            TextField {
                id: _pwField
                anchors.left:            parent.left
                anchors.right:           _joinBtn.left
                anchors.rightMargin:     8
                anchors.verticalCenter:  parent.verticalCenter
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
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                }
                onAccepted: {
                    if (_nr.net) {
                        NetworkManager.connectToNetwork(_nr.net.ssid, text)
                        text = ""
                        root._passwordForIndex = -1
                    }
                }
                onVisibleChanged: {
                    if (visible) forceActiveFocus()
                }
            }

            Rectangle {
                id:                     _joinBtn
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                width:  72
                height: 32
                radius: 8
                color:  Qt.rgba(0.11, 0.47, 1, 0.85)

                CFText {
                    anchors.centerIn: parent
                    text:           "Joindre"
                    font.pixelSize: 13
                    font.weight:    Font.SemiBold
                    color:          "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        if (_nr.net) {
                            NetworkManager.connectToNetwork(_nr.net.ssid, _pwField.text)
                            _pwField.text = ""
                            root._passwordForIndex = -1
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
            onEntered:     _nr._hovered = true
            onExited:      _nr._hovered = false
            onClicked: {
                if (_nr.isActive) {
                    root._disconnecting = true
                    NetworkManager.disconnectFromNetwork()
                    return
                }
                var isKnown  = NetworkManager.networksKnown.indexOf(_nr.net) !== -1
                var isFailed = _nr.net && root._failedSSIDs[_nr.net.ssid] === true
                if (_nr.net && (_nr.net.isSecure && !isKnown || isFailed)) {
                    root._passwordForIndex = (root._passwordForIndex === _nr.rowIndex)
                                             ? -1 : _nr.rowIndex
                } else if (_nr.net) {
                    NetworkManager.connectToNetwork(_nr.net.ssid, "")
                }
            }
        }
    }
}
