pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components
import qs.components.glass
import qs.services

Item {
    id: root

    property Item glassBackdrop: null
    property bool open: false

    readonly property var sink: Pipewire.defaultAudioSink
    property bool hasBacklight: false
    property real brtValue: 0.5

    implicitWidth: 300
    implicitHeight: panel.implicitHeight
    width: implicitWidth
    height: implicitHeight

    visible: opacity > 0
    opacity: root.open ? 1 : 0
    scale: root.open ? 1 : 0.96
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Process {
        id: _brtProbe
        command: ["sh", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBacklight = text.trim() !== ""
                if (root.hasBacklight) _brtGet.running = true
            }
        }
    }

    Process {
        id: _brtGet
        command: ["brightnessctl", "-e2", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split(",")
                if (f.length >= 5) {
                    var pct = parseFloat(f[3])
                    if (isFinite(pct)) root.brtValue = pct / 100
                }
            }
        }
    }

    Process { id: _brtSet }

    Timer {
        id: _brtTimer
        interval: 50
        onTriggered: {
            _brtSet.command = ["brightnessctl", "-e2", "set", Math.round(root.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }

    onOpenChanged: {
        if (root.open) _brtProbe.running = true
    }

    component Tile: Item {
        id: _tile
        property string icon: ""
        property string label: ""
        property bool on: false
        signal activated()

        width: (panel.width - 16 * 2 - 10) / 2
        height: 64

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: _tile.on ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.10)
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            spacing: 10

            CFVI {
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                icon: _tile.icon
                color: "#ffffff"
            }

            CFText {
                anchors.verticalCenter: parent.verticalCenter
                text: _tile.label
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: "#ffffff"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: _tile.activated()
        }
    }

    component SliderRow: Item {
        id: _sr
        property string iconLow: ""
        property string iconHigh: ""
        property alias value: _slider.value
        signal moved(real value)

        width: panel.width - 32
        height: 28

        CFVI {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 14
            icon: _sr.iconLow
            color: "#ffffff"
        }

        CFSlider {
            id: _slider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            focusPolicy: Qt.NoFocus
            glassBackdrop: root.glassBackdrop
            fillColor: "#ffffff"
            from: 0
            to: 1
            onMoved: _sr.moved(value)
        }

        CFVI {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            size: 18
            icon: _sr.iconHigh
            color: "#ffffff"
        }
    }

    Item {
        id: panel
        width: root.width
        implicitHeight: _col.implicitHeight + 32

        BoxGlass {
            anchors.fill: parent
            backdrop: root.glassBackdrop
            radius: 24
            color: Qt.rgba(1, 1, 1, 0.10)
            light: Qt.rgba(1, 1, 1, 0.28)
            rimStrength: 0.7
            highlightEnabled: true
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: _col
            x: 16
            y: 16
            spacing: 14

            Row {
                spacing: 10

                Tile {
                    icon: NetworkManager.wifiEnabled ? "wifi/wifi-clear-3.svg" : "wifi/wifi-off-clear.svg"
                    label: "Wi-Fi"
                    on: NetworkManager.wifiEnabled
                    onActivated: NetworkManager.enableWifi(!NetworkManager.wifiEnabled)
                }

                Tile {
                    icon: BluetoothState.enabled ? "bluetooth/bluetooth.svg" : "bluetooth-off-clear.svg"
                    label: "Bluetooth"
                    on: BluetoothState.enabled
                    onActivated: {
                        if (BluetoothState.adapter) BluetoothState.adapter.enabled = !BluetoothState.adapter.enabled
                    }
                }
            }

            SliderRow {
                visible: root.hasBacklight
                iconLow: "sun-small.svg"
                iconHigh: "sun-small.svg"
                value: root.brtValue
                onMoved: function(v) {
                    root.brtValue = v
                    _brtTimer.restart()
                }
            }

            SliderRow {
                iconLow: "volume/audio-volume-1.svg"
                iconHigh: "volume/audio-volume-3.svg"
                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                onMoved: function(v) {
                    if (root.sink && root.sink.audio) root.sink.audio.volume = v
                }
            }
        }
    }
}
