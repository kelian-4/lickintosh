import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    property bool otherNetworksShown: false
    property string connectingSSID: ""
    
    signal closeRequested()

    
    readonly property int rowHeight: 48
    readonly property int iconSize: 22

    implicitHeight: content.height + 20

    
    Process { id: _nmUp; command: [] }
    Process { id: _nmDisc; command: ["sh", "-c", "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device 2>/dev/null | grep ':wifi' | cut -d: -f1 | head -1) 2>/dev/null"] }

    Item {
        id: content
        width: parent.width
        height: title.height + list.height + 60

        CFText {
            id: title
            text: "Wi-Fi"
            font.weight: 700
            font.pixelSize: 18
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 20
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }
        }

        CFSwitch {
            id: sw
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: title.verticalCenter
            checked: wifiOn
            onCheckedChanged: {
                if (checked) {
                    _nmOn.running = true
                } else {
                    _nmOff.running = true
                }
            }
        }

        Rectangle {
            id: sep
            width: parent.width - 40
            height: 1
            anchors.top: parent.top
            anchors.topMargin: 55
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#20ffffff"
        }

        Column {
            id: list
            anchors.top: sep.bottom
            anchors.topMargin: 15
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            
            CFText {
                text: "Connecté"
                font.pixelSize: 13
                gray: true
                visible: activeNet !== null
                leftPadding: 20
            }

            NetRow {
                width: parent.width
                ssid: activeNet ? activeNet.ssid : ""
                isActive: true
                visible: activeNet !== null
                profile: activeNet ? activeNet.profile : ""
            }

            
            CFText {
                text: "Réseaux connus"
                font.pixelSize: 13
                gray: true
                visible: knownNets.length > 0
                leftPadding: 20
                topPadding: 5
            }

            Repeater {
                model: knownNets
                delegate: NetRow {
                    width: parent.width
                    ssid: modelData.ssid
                    secured: modelData.secured
                    profile: modelData.profile
                }
            }

            
            Rectangle {
                width: parent.width - 40
                height: 1
                color: "#10ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                visible: otherNets.length > 0
            }

            Item {
                width: parent.width
                height: 35
                visible: otherNets.length > 0
                
                CFText {
                    text: "Autres réseaux"
                    font.pixelSize: 13
                    gray: true
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                CFVI {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "spotlight/chevron-right.svg"
                    size: 16
                    rotation: root.otherNetworksShown ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.otherNetworksShown = !root.otherNetworksShown
                    }
                }
            }

            Column {
                id: listOther
                width: parent.width
                visible: root.otherNetworksShown
                spacing: 4
                Repeater {
                    model: otherNets
                    delegate: NetRow {
                        width: listOther.width
                        ssid: modelData.ssid
                        secured: modelData.secured
                    }
                }
            }

            Rectangle {
                width: parent.width - 40
                height: 1
                color: "#10ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            CFText {
                text: "Paramètres Wi-Fi…"
                font.pixelSize: 14
                gray: true
                leftPadding: 20
                topPadding: 5
            }
        }
    }

    component NetRow: Item {
        id: _nr
        property string ssid: ""
        property string profile: ""
        property bool isActive: false
        property bool secured: false
        property bool hovered: false
        property bool isConnecting: root.connectingSSID === _nr.ssid && !isActive
        height: root.rowHeight
        width: parent.width

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: _nr.hovered ? "#15ffffff" : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 15

            CFClippingRect {
                width: 32
                height: 32
                radius: 16
                color: _nr.isActive ? "#fff" : "#25ffffff"
                CFVI {
                    anchors.centerIn: parent
                    icon: "wifi/nm-signal-100-symbolic.svg"
                    size: root.iconSize
                    color: _nr.isActive ? "#1C7AFF" : "#fff"
                }
            }

            CFText {
                text: _nr.ssid
                font.pixelSize: 14
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            CFText {
                text: "Connexion..."
                font.pixelSize: 12
                gray: true
                visible: _nr.isConnecting
            }

            CFVI {
                icon: "lock.svg"
                size: 14
                visible: _nr.secured && !_nr.isActive && !_nr.isConnecting
                gray: true
            }

            CFText {
                text: "✓"
                visible: _nr.isActive
                color: "#1C7AFF"
                font.weight: Font.Bold
                font.pixelSize: 16
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { _nr.hovered = true }
            onExited: { _nr.hovered = false }
            onClicked: {
                if (_nr.isActive) return
                if (activeNet) _nmDisc.running = true
                root.connectingSSID = _nr.ssid
                if (_nr.profile !== "") {
                    _nmUp.command = ["nmcli", "connection", "up", _nr.profile]
                    _nmUp.running = true
                } else {
                    connectNew(_nr.ssid, "")
                }
            }
        }
    }
}
