pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import qs.components
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property int rowHeight: 52
    readonly property int iconSize:  22

    Component.onCompleted: BluetoothState.setDiscovering(true)
    Component.onDestruction: BluetoothState.setDiscovering(false)

    // ---------------- Bluetooth : toggle + description ----------------
    ContentSection {
        title: ""

        ConfigSwitch {
            text: "Bluetooth"
            description: "Se connecter à des accessoires pour diffuser de la musique, saisir du texte, jouer et bien plus encore."
            checked: BluetoothState.enabled
            onToggled: function(value) {
                if (BluetoothState.adapter) BluetoothState.adapter.enabled = value
            }
        }
    }

    // ---------------- Mes appareils ----------------
    ContentSection {
        title: "Mes appareils"
        visible: BluetoothState.enabled && BluetoothState.pairedDevices.length > 0

        Repeater {
            model: BluetoothState.pairedDevices
            delegate: DeviceRow {
                required property BluetoothDevice modelData
                Layout.fillWidth: true
                dev: modelData
            }
        }
    }

    // ---------------- Appareils à proximité ----------------
    ContentSection {
        title: "Appareils à proximité"
        visible: BluetoothState.enabled

        Repeater {
            model: BluetoothState.otherDevices
            delegate: DeviceRow {
                required property BluetoothDevice modelData
                Layout.fillWidth: true
                dev: modelData
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFVI {
                icon: "search.svg"
                size: 13
                gray: true
            }

            CFText {
                text: BluetoothState.isScanning ? "Recherche…" : "Aucun appareil trouvé"
                font.pixelSize: 13
                gray: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 24
                opacity: BluetoothState.isScanning ? 0.4 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                radius: 6
                color: _rescanMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Rechercher"
                    font.pixelSize: 11
                    color: "#fff"
                }

                MouseArea {
                    id: _rescanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !BluetoothState.isScanning
                    onClicked: BluetoothState.rescan()
                }
            }
        }
    }

    property var  _ctxDevice: null
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

    component DeviceRow: Item {
        id: _dr
        property var dev: null
        property bool _hovered: false

        readonly property bool _connecting:    dev !== null && BluetoothState.isConnecting(dev)
        readonly property bool _disconnecting: dev !== null && BluetoothState.isDisconnecting(dev)
        readonly property bool _pairing:       dev !== null && dev.pairing

        Layout.preferredHeight: root.rowHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: _dr._hovered ? "#12ffffff" : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: _dr.dev && _dr.dev.connected ? "#fff" : "#25ffffff"

                CFVI {
                    anchors.centerIn: parent
                    icon: _dr.dev ? BluetoothState.deviceIcon(_dr.dev) : "bluetooth/bluetooth.svg"
                    size: root.iconSize
                    color: _dr.dev && _dr.dev.connected ? "#1C7AFF" : "#fff"
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                CFText {
                    text: _dr.dev ? _dr.dev.name : ""
                    font.pixelSize: 14
                    color: "#fff"
                    elide: Text.ElideRight
                    width: parent.width
                }

                RowLayout {
                    spacing: 6
                    visible: statusLabel.text.length > 0

                    CFText {
                        id: statusLabel
                        text: _dr.dev ? BluetoothState.statusText(_dr.dev) : ""
                        font.pixelSize: 12
                        color: _dr.dev && _dr.dev.connected ? "#4CD964" : "#888"
                    }

                    CFText {
                        text: _dr.dev ? BluetoothState.batteryText(_dr.dev) : ""
                        font.pixelSize: 12
                        color: "#888"
                        visible: text.length > 0
                    }
                }
            }

            CFVI {
                icon: _dr.dev ? BluetoothState.batteryIcon(_dr.dev) : ""
                size: 20
                gray: true
                visible: _dr.dev && _dr.dev.connected && BluetoothState.batteryText(_dr.dev).length > 0
            }

            Rectangle {
                id: _optBtn
                Layout.preferredWidth: 84
                Layout.preferredHeight: 26
                radius: 7
                color: _optBtnMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Options…"
                    font.pixelSize: 12
                    color: "#fff"
                }

                MouseArea {
                    id: _optBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (!_dr.dev) return
                        var pos = _optBtn.mapToItem(root, 0, _optBtn.height)
                        root.openContextMenu(_dr.dev, pos.x, pos.y)
                    }
                }
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 84 + 14 + 10
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: _dr._hovered = true
            onExited:  _dr._hovered = false
            onClicked: function(mouse) {
                if (!_dr.dev) return
                if (mouse.button === Qt.RightButton) {
                    var pos = _dr.mapToItem(root, mouse.x, mouse.y)
                    root.openContextMenu(_dr.dev, pos.x, pos.y)
                    return
                }
                BluetoothState.toggleConnection(_dr.dev)
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
        active: root._ctxDevice !== null
        z: 9999

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
}
