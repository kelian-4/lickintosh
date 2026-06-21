import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.ui.glass
import qs.ui.primitives

Scope {
    id: root

    property bool   _visible:     false
    property bool   _ready:       false
    property string _deviceName:  ""
    property real   _percentage:  0.0
    property bool   _isBluetooth: false

    readonly property var _thresholds: [100, 80, 50, 20, 15, 10, 5]
    property var _notifiedLevels:   ({})
    property var _btNotifiedLevels: ({})

    Timer {
        id: _bootGuard
        interval: 3000
        repeat:   false
        running:  true
        onTriggered: root._ready = true
    }

    function _shouldNotify(key, pct, notifiedMap) {
        var crossed = -1
        for (var i = 0; i < root._thresholds.length; i++) {
            var t = root._thresholds[i]
            if (pct >= t - 0.5 && pct <= t + 1.5) {
                crossed = t
                break
            }
        }
        if (crossed < 0) return false
        if (notifiedMap[key] === crossed) return false
        notifiedMap[key] = crossed
        return true
    }

    function _showLaptop(dev) {
        _deviceName  = dev.model || "Batterie"
        _percentage  = dev.percentage
        _isBluetooth = false
        _trigger()
    }

    function _showBluetooth(dev) {
        _deviceName  = dev.name || "Périphérique"
        _percentage  = dev.battery ? dev.battery.percentage : 0
        _isBluetooth = true
        _trigger()
    }

    function _trigger() {
        _panelLoader.active = true
        _visible = true
    }

    function dismiss() {
        _visible = false
        _unloadTimer.restart()
    }

    Instantiator {
        model: UPower.devices
        delegate: QtObject {
            required property var modelData
            property var _conn: Connections {
                target: modelData
                function onPercentageChanged() {
                    if (!root._ready) return
                    if (!modelData.isLaptopBattery) return
                    if (!root._shouldNotify("laptop", modelData.percentage, root._notifiedLevels)) return
                    root._showLaptop(modelData)
                }
            }
        }
    }

    Instantiator {
        model: Bluetooth.connectedDevices
        delegate: QtObject {
            required property var modelData
            property var _conn: Connections {
                target: modelData.battery ?? null
                function onPercentageChanged() {
                    if (!root._ready) return
                    var key = "bt_" + modelData.name
                    if (!root._shouldNotify(key, modelData.battery.percentage, root._btNotifiedLevels)) return
                    root._showBluetooth(modelData)
                }
            }
        }
    }

    Timer {
        id: _unloadTimer
        interval: 220
        repeat:   false
        onTriggered: _panelLoader.active = false
    }

    Loader {
        id: _panelLoader
        active: false
        sourceComponent: Component {
            PanelWindow {
                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) {
                            return sc.name === focused.name
                        })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace:     "quickshell:batteryosd"
                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                color:         "transparent"
                exclusiveZone: -1

                anchors {
                    top:   true
                    right: true
                }

                implicitWidth:  320
                implicitHeight: 90

                Item {
                    id: pill
                    width:  300
                    height: 52
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   40
                    anchors.rightMargin: 12

                    opacity: root._visible ? 1.0 : 0.0
                    scale:   root._visible ? 1.0 : 0.94

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.25 }
                    }

                    transformOrigin: Item.TopRight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.dismiss()
                    }

                    BoxGlass {
                        anchors.fill: parent
                        radius:       26
                        color:        "#30000000"
                        light:        "#55ffffff"
                        rimSize:      0.014
                        rimStrength:  1.1
                    }

                    RowLayout {
                        anchors {
                            fill:         parent
                            leftMargin:   12
                            rightMargin:  12
                            topMargin:    0
                            bottomMargin: 0
                        }
                        spacing: 10

                        CFVI {
                            icon:             root._isBluetooth
                                              ? "bluetooth/bluetooth.svg"
                                              : "settings/battery.svg"
                            size:             18
                            color:            "#ccffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing:          1

                            CFText {
                                text:             root._deviceName
                                font.pixelSize:   13
                                font.weight:      Font.Bold
                                color:            "#ffffff"
                                elide:            Text.ElideRight
                                Layout.fillWidth: true
                            }

                            CFText {
                                text:           root._isBluetooth ? "Connecté" : "Batterie système"
                                font.pixelSize: 11
                                color:          Qt.rgba(1, 1, 1, 0.55)
                            }
                        }

                        Item {
                            id:               ringItem
                            width:            40
                            height:           40
                            Layout.alignment: Qt.AlignVCenter

                            readonly property color ringColor: {
                                if (root._percentage <= 10) return "#FF453A"
                                if (root._percentage <= 20) return "#FF9F0A"
                                return "#30D158"
                            }

                            onRingColorChanged: ringCanvas.requestPaint()

                            Component.onCompleted: ringCanvas.requestPaint()

                            Connections {
                                target: root
                                function on_PercentageChanged() { ringCanvas.requestPaint() }
                            }

                            Canvas {
                                id:          ringCanvas
                                anchors.fill: parent

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx  = width / 2
                                    var cy  = height / 2
                                    var r   = width / 2 - 3
                                    var lw  = 3.5
                                    var pct = Math.max(0, Math.min(1, root._percentage / 100.0))

                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.18)
                                    ctx.lineWidth   = lw
                                    ctx.stroke()

                                    if (pct > 0) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct)
                                        ctx.strokeStyle = ringItem.ringColor
                                        ctx.lineWidth   = lw
                                        ctx.lineCap     = "round"
                                        ctx.stroke()
                                    }
                                }
                            }

                            CFText {
                                anchors.centerIn: parent
                                text:           Math.round(root._percentage).toString()
                                font.pixelSize: 11
                                font.weight:    Font.Bold
                                color:          "#ffffff"
                            }
                        }
                    }
                }
            }
        }
    }
}
