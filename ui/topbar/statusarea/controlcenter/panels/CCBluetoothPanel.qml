pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import qs.components.glass
import qs.components
import qs.services

Item {
    id: root

    signal closeRequested()

    readonly property int rowHeight: 48
    readonly property int iconSize:  22
    readonly property int maxScrollHeight: 360

    readonly property var  _adapter: BluetoothState.adapter
    readonly property bool _btOn:    BluetoothState.enabled
    readonly property var  _devices: BluetoothState.devices

    property var _ctxDevice: null
    property real _ctxX: 0
    property real _ctxY: 0

    function openContextMenu(dev, x, y) {
        root._ctxDevice = dev
        root._ctxX = x
        root._ctxY = y
    }

    function closeContextMenu() {
        root._ctxDevice = null
    }

    implicitHeight: _content.implicitHeight + 20

    Component.onCompleted: BluetoothState.setDiscovering(true)
    Component.onDestruction: BluetoothState.setDiscovering(false)

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

        ScrollView {
            id: _btScrollArea
            width: parent.width
            height: Math.min(_btCol.implicitHeight, root.maxScrollHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ScrollBar.vertical: ScrollBar {
                id: _btVbar
                parent: _btScrollArea
                x: _btScrollArea.width - width
                width: 4
                policy: ScrollBar.AsNeeded

                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#50ffffff"
                    opacity: _btVbar.pressed ? 0.9 : (_btVbar.hovered ? 0.7 : 0.0)
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                background: Item {}
            }

            Column {
                id: _btCol
                width:   _btScrollArea.width
                spacing: 0

                CFText {
                    text:           "Mes appareils"
                    font.pixelSize: 13
                    font.weight:    Font.Bold
                    color:          "#fff"
                    visible:        root._devices.some(function(d) { return d.paired })
                    leftPadding:    20
                    bottomPadding:  4
                }

                Repeater {
                    model: root._adapter ? root._adapter.devices : []
                    delegate: DeviceRow {
                        visible: modelData !== null && modelData.name !== "" && modelData.paired
                        height: visible ? root.rowHeight : 0
                    }
                }

                Item { width: parent.width; height: 8 }

                CFText {
                    text:          "Autres appareils"
                    font.pixelSize: 13
                    font.weight:    Font.Bold
                    color:          "#fff"
                    visible:        root._devices.some(function(d) { return !d.paired })
                    leftPadding:    20
                    bottomPadding:  4
                }

                Repeater {
                    model: root._adapter ? root._adapter.devices : []
                    delegate: DeviceRow {
                        visible: modelData !== null && modelData.name !== "" && !modelData.paired
                        height: visible ? root.rowHeight : 0
                    }
                }

                Item { width: parent.width; height: 8 }
            }
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
                font.weight:    Font.Bold
                color:          "#fff"
                anchors.left:        parent.left
                anchors.leftMargin:  20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component DeviceRow: Item {
        id:             _dr
        required property BluetoothDevice modelData
        width:          parent.width
        height:         modelData !== null ? root.rowHeight : 0
        visible:        modelData !== null
        property bool   _hovered:      false
        readonly property bool _connecting:    modelData !== null && BluetoothState.isConnecting(_dr.modelData)
        readonly property bool _disconnecting: modelData !== null && BluetoothState.isDisconnecting(_dr.modelData)
        readonly property bool _pairing:       modelData !== null && _dr.modelData.pairing

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
            visible: _dr.modelData !== null

            Rectangle {
                width:  32
                height: 32
                radius: 16
                color:  _dr.modelData !== null && _dr.modelData.connected ? "#fff" : "#25ffffff"

                CFVI {
                    anchors.centerIn: parent
                    icon:  _dr.modelData !== null ? BluetoothState.deviceIcon(_dr.modelData) : "bluetooth/bluetooth.svg"
                    size:  root.iconSize
                    color: _dr.modelData !== null && _dr.modelData.connected ? "#1C7AFF" : "#fff"
                }
            }

            CFText {
                text:           _dr.modelData !== null ? _dr.modelData.name : ""
                font.pixelSize: 14
                font.weight:    Font.Bold
                color:          "#fff"
                Layout.fillWidth: true
                elide:            Text.ElideRight
            }

            CFText {
                text:           _dr.modelData !== null ? BluetoothState.statusText(_dr.modelData) : ""
                font.pixelSize: 12
                font.weight:    Font.Bold
                color:          "#fff"
                visible:        _dr._connecting || _dr._disconnecting || _dr._pairing
            }

            Row {
                spacing: 8
                readonly property string _pct: _dr.modelData !== null ? BluetoothState.batteryText(_dr.modelData) : ""
                readonly property string _battIcon: _dr.modelData !== null ? BluetoothState.batteryIcon(_dr.modelData) : ""
                visible: _dr.modelData !== null && _dr.modelData.connected && !_dr._connecting && !_dr._disconnecting && _pct.length > 0

                CFText {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           parent._pct
                    font.weight:    Font.Bold
                    color:          "#fff"
                    font.pixelSize: 16
                }

                CFVI {
                    anchors.verticalCenter: parent.verticalCenter
                    icon:  parent._battIcon
                    size:  26
                    color: "#fff"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            enabled: _dr.modelData !== null
            onEntered:    _dr._hovered = true
            onExited:     _dr._hovered = false
            onClicked: function(mouse) {
                if (_dr.modelData === null) return
                if (mouse.button === Qt.RightButton) {
                    var pos = _dr.mapToItem(root, mouse.x, mouse.y)
                    root.openContextMenu(_dr.modelData, pos.x, pos.y)
                    return
                }
                if (_dr.modelData.connected) {
                    BluetoothState.disconnectDevice(_dr.modelData)
                } else {
                    var paired = root._devices.filter(function(d) { return d.paired })
                    for (var i = 0; i < paired.length; i++) {
                        if (paired[i].connected && paired[i] !== _dr.modelData) {
                            BluetoothState.disconnectDevice(paired[i])
                        }
                    }
                    BluetoothState.connectDevice(_dr.modelData)
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
        visible: root._ctxDevice !== null
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeContextMenu()
        }

        Rectangle {
            id: _ctxMenu
            x: Math.min(root._ctxX, root.width - width - 8)
            y: root._ctxY
            width: 170
            radius: 10
            color: "#e6202020"
            border.color: "#20ffffff"
            border.width: 1
            implicitHeight: _ctxCol.implicitHeight + 8
            height: implicitHeight

            Column {
                id: _ctxCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 4
                spacing: 2

                CtxItem {
                    label: root._ctxDevice && root._ctxDevice.connected ? "Déconnecter" : "Connecter"
                    onActivated: {
                        if (!root._ctxDevice) return
                        BluetoothState.toggleConnection(root._ctxDevice)
                    }
                }

                CtxItem {
                    visible: root._ctxDevice && root._ctxDevice.paired
                    height: visible ? 32 : 0
                    label: "Supprimer"
                    destructive: true
                    onActivated: {
                        if (root._ctxDevice) {
                            BluetoothState.forgetDevice(root._ctxDevice)
                        }
                    }
                }
            }
        }
    }
}
