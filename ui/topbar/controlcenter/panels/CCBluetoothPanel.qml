import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    signal closeRequested()

    readonly property int rowHeight: 48
    readonly property int iconSize:  22

    property var  _adapter: Bluetooth.defaultAdapter
    property bool _btOn:    _adapter ? _adapter.enabled : false

    property var _devices: {
        if (!_adapter || !_btOn) return []
        return _adapter.devices.values.filter(function(d) { return d.name !== "" })
    }

    implicitHeight: _content.implicitHeight + 20

    Column {
        id: _content
        width:            parent.width
        anchors.top:      parent.top
        anchors.topMargin: 10
        spacing: 0

        Item {
            width:  parent.width
            height: 54

            CFText {
                text:           "Bluetooth"
                font.weight:    Font.Bold
                font.pixelSize: 18
                anchors.left:        parent.left
                anchors.leftMargin:  20
                anchors.verticalCenter: parent.verticalCenter
            }

            CFSwitch {
                anchors.right:          parent.right
                anchors.rightMargin:    15
                anchors.verticalCenter: parent.verticalCenter
                checked: root._btOn
                onCheckedChanged: {
                    if (root._adapter && checked !== root._btOn) {
                        root._adapter.enabled = checked
                    }
                }
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
            text:           "Mes appareils"
            font.pixelSize: 13
            gray:           true
            visible:        root._devices.some(function(d) { return d.paired })
            leftPadding:    20
            bottomPadding:  4
        }

        Repeater {
            model: root._devices.filter(function(d) { return d.paired })
            delegate: DeviceRow {}
        }

        Item { width: parent.width; height: 8 }

        CFText {
            text:          "Autres appareils"
            font.pixelSize: 13
            gray:           true
            visible:        root._devices.some(function(d) { return !d.paired })
            leftPadding:    20
            bottomPadding:  4
        }

        Repeater {
            model: root._devices.filter(function(d) { return !d.paired })
            delegate: DeviceRow {}
        }

        Rectangle {
            width:   parent.width - 40
            height:  1
            color:   "#10ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root._btOn
        }

        Item {
            width:   parent.width
            height:  42
            visible: root._btOn

            CFText {
                text:           "Paramètres Bluetooth…"
                font.pixelSize: 14
                gray:           true
                anchors.left:        parent.left
                anchors.leftMargin:  20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component DeviceRow: Item {
        id:             _dr
        required property var modelData
        width:          parent.width
        height:         root.rowHeight
        property bool   _hovered:      false
        property bool   _connecting:   false
        property bool   _disconnecting: false

        Connections {
            target: _dr.modelData
            function onConnectedChanged() {
                if (_dr.modelData.connected) {
                    _dr._connecting    = false
                } else {
                    _dr._disconnecting = false
                }
            }
        }

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 4
            radius:          10
            color:           _dr._hovered ? "#15ffffff" : "transparent"
        }

        RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  20
            anchors.rightMargin: 20
            spacing: 15

            CFClippingRect {
                width:  32
                height: 32
                radius: 16
                color:  _dr.modelData.connected ? "#fff" : "#25ffffff"
                CFVI {
                    anchors.centerIn: parent
                    icon:  "bluetooth/bluetooth.svg"
                    size:  root.iconSize
                    color: _dr.modelData.connected ? "#1C7AFF" : "#fff"
                }
            }

            CFText {
                text:             _dr.modelData.name
                font.pixelSize:   14
                Layout.fillWidth: true
                elide:            Text.ElideRight
            }

            CFText {
                text:    "Connexion…"
                font.pixelSize: 12
                gray:    true
                visible: _dr._connecting && !_dr.modelData.connected
            }

            CFText {
                text:    "Déconnexion…"
                font.pixelSize: 12
                gray:    true
                visible: _dr._disconnecting && _dr.modelData.connected
            }

            CFText {
                text:           "✓"
                visible:        _dr.modelData.connected && !_dr._connecting && !_dr._disconnecting
                color:          "#1C7AFF"
                font.weight:    Font.Bold
                font.pixelSize: 16
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered:    _dr._hovered = true
            onExited:     _dr._hovered = false
            onClicked: {
                if (_dr.modelData.connected) {
                    _dr._disconnecting = true
                    _dr._connecting    = false
                    _dr.modelData.disconnect()
                } else {
                    var paired = root._devices.filter(function(d) { return d.paired })
                    for (var i = 0; i < paired.length; i++) {
                        if (paired[i].connected && paired[i] !== _dr.modelData) {
                            paired[i].disconnect()
                        }
                    }
                    _dr._connecting    = true
                    _dr._disconnecting = false
                    _dr.modelData.connect()
                }
            }
        }
    }
}
