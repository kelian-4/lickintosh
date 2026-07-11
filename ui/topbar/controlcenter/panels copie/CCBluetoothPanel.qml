import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    property var adapter: Bluetooth.defaultAdapter
    property bool btOn: adapter ? adapter.enabled : false
    
    signal closeRequested()

    
    readonly property int rowHeight: 48
    readonly property int iconSize: 22

    property var devices: {
        if (!adapter || !btOn) return []
        var d = adapter.devices.values.filter(function(device) {
            return device.name !== ""
        })
        return d
    }

    implicitHeight: content.height + 20

    Item {
        id: content
        width: parent.width
        height: title.height + list.height + 40

        CFText {
            id: title
            text: "Bluetooth"
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
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: title.verticalCenter
            checked: root.btOn
            onCheckedChanged: {
                if (adapter) {
                    adapter.enabled = checked
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
            spacing: 5

            
            CFText {
                text: "Mes appareils"
                font.pixelSize: 13
                gray: true
                visible: root.devices.some(function(d){return d.paired})
                leftPadding: 20
                bottomPadding: 5
            }

            Repeater {
                model: root.devices.filter(function(d){return d.paired})
                delegate: DeviceRow {}
            }

            
            CFText {
                text: "Autres appareils"
                font.pixelSize: 13
                gray: true
                visible: root.devices.some(function(d){return !d.paired})
                leftPadding: 20
                topPadding: 5
                bottomPadding: 5
            }

            Repeater {
                model: root.devices.filter(function(d){return !d.paired})
                delegate: DeviceRow {}
            }

            Rectangle {
                width: parent.width - 40
                height: 1
                color: "#10ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                visible: btOn
            }

            CFText {
                text: "Paramètres Bluetooth…"
                font.pixelSize: 14
                gray: true
                leftPadding: 20
                topPadding: 10
                visible: btOn
            }
        }
    }

    component DeviceRow: Item {
        id: _br
        required property var modelData
        width: list.width
        height: root.rowHeight
        property bool hovered: false
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: _br.hovered ? "#15ffffff" : "transparent"
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
                color: modelData.connected ? "#fff" : "#25ffffff"
                CFVI {
                    anchors.centerIn: parent
                    icon: "bluetooth/bluetooth.svg"
                    size: root.iconSize
                    color: modelData.connected ? "#1C7AFF" : "#fff"
                }
            }
            
            CFText {
                text: modelData.name
                font.pixelSize: 14
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            CFText {
                text: "Connexion..."
                font.pixelSize: 12
                gray: true
                visible: modelData.connecting && !modelData.connected
            }
            
            CFText {
                text: "✓"
                visible: modelData.connected && !modelData.connecting
                color: "#1C7AFF"
                font.weight: Font.Bold
                font.pixelSize: 16
            }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { _br.hovered = true }
            onExited: { _br.hovered = false }
            onClicked: {
                if (modelData.connected) {
                    modelData.disconnect()
                } else {
                    var paired = root.devices.filter(function(d){return d.paired})
                    for (var i = 0; i < paired.length; i++) {
                        if (paired[i].connected && paired[i] !== modelData) paired[i].disconnect()
                    }
                    modelData.connect()
                }
            }
        }
    }
}
