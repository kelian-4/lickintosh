import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.components.glass
import qs.components

Scope {
    id: root

    property bool   _visible:     false
    property bool   _ready:       false
    property string _deviceName:  "Batterie"
    property real   _percentage:  0.0
    property bool   _isCharging:  false

    readonly property bool isShowing: _visible

    property var _notifiedLevels: ({})

    Timer {
        id: _bootGuard
        interval: 5000
        repeat:   false
        running:  true
        onTriggered: root._ready = true
    }

    IpcHandler {
        target: "batteryOSD"
        function testShow(): void {
            _testProc.running = true
        }
    }

    Process {
        id: _testProc
        command: ["sh", "-c", "upower -i $(upower -e | grep BAT | head -1) | grep percentage | awk '{print $2}' | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var dev = root._laptopBattery
                root._deviceName  = dev ? (dev.model || "Batterie") : "Batterie"
                root._percentage  = parseFloat(text.trim()) || (dev ? dev.percentage * 100 : 50)
                root._trigger()
            }
        }
    }

    function _shouldNotify(key, pct, notifiedMap, isCharging) {
        var pct100     = pct * 100
        var thresholds = isCharging ? [100, 80] : [20, 15, 10, 5]
        var crossed    = -1
        for (var i = 0; i < thresholds.length; i++) {
            var t = thresholds[i]
            if (pct100 >= t - 0.5 && pct100 <= t + 0.5) {
                crossed = t
                break
            }
        }
        if (crossed < 0) {
            if (notifiedMap[key] !== undefined) {
                var last = notifiedMap[key]
                if (Math.abs(pct100 - last) > 3) {
                    delete notifiedMap[key]
                }
            }
            return false
        }
        if (notifiedMap[key] === crossed) return false
        notifiedMap[key] = crossed
        return true
    }

    function _trigger() {
        _panelLoader.active = true
        _visible = true
    }

    function dismiss() {
        _visible = false
        _unloadTimer.restart()
    }

    property var _laptopBattery: null

    function _findLaptopBattery() {
        var devs = UPower.devices.values
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].isLaptopBattery) {
                root._laptopBattery = devs[i]
                return
            }
        }
    }

    function _checkBattery() {
        var dev = root._laptopBattery
        if (!dev) return
        var pct        = dev.percentage
        var isCharging = dev.state === UPowerDeviceState.Charging
                         || dev.state === UPowerDeviceState.FullyCharged
        if (!root._ready) return
        if (!root._shouldNotify("laptop", pct, root._notifiedLevels, isCharging)) return
        root._deviceName  = "Batterie"
        root._percentage  = pct * 100
        root._isCharging  = isCharging
        root._trigger()
    }

    Connections {
        target: root
        function on_LaptopBatteryChanged() {
            if (!root._laptopBattery) return
            _battConn.target = root._laptopBattery
        }
    }

    Connections {
        id: _battConn
        target: null
        function onPercentageChanged() {
            root._checkBattery()
        }
        function onStateChanged() {
            var dev = root._laptopBattery
            if (!dev || !root._ready) return
            root._deviceName  = "Batterie"
            root._percentage  = dev.percentage * 100
            root._isCharging  = dev.state === UPowerDeviceState.Charging
                                 || dev.state === UPowerDeviceState.FullyCharged
            root._trigger()
        }
    }

    Timer {
        interval: 60000
        running:  root._ready
        repeat:   true
        onTriggered: root._checkBattery()
    }

    Component.onCompleted: _findRetryTimer.start()

    Timer {
        id: _findRetryTimer
        interval: 200
        repeat:   true
        running:  false
        onTriggered: {
            root._findLaptopBattery()
            if (root._laptopBattery !== null) _findRetryTimer.stop()
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

                implicitWidth:  324
                implicitHeight: 108

                GlassBackdrop { id: glassBackdrop }

                Item {
                    id: pill
                    width:  300
                    height: 54
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
                        backdrop:     glassBackdrop
                        radius:       27
                        color:        "#30000000"
                        light:        "#55ffffff"
                        rimSize:      0.014
                        rimStrength:  1.1
                    }

                    RowLayout {
                        anchors {
                            fill:         parent
                            leftMargin:   14
                            rightMargin:  14
                        }
                        spacing: 10

                        CFVI {
                            icon: {
                                var p = Math.round(root._percentage / 10) * 10
                                p = Math.max(0, Math.min(100, p))
                                var pad = p < 10 ? "00" + p : (p < 100 ? "0" + p : "100")
                                return "battery/battery-" + pad + (root._isCharging ? "-charging" : "") + ".svg"
                            }
                            size:             20
                            color:            "#ccffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing:          2

                            CFText {
                                text:                root._deviceName
                                font.pixelSize:      13
                                font.weight:         Font.Bold
                                color:               "#ffffff"
                                elide:               Text.ElideRight
                                Layout.fillWidth:    true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            CFText {
                                text:                "Batterie système"
                                font.pixelSize:      11
                                color:               Qt.rgba(1, 1, 1, 0.55)
                                Layout.fillWidth:    true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item {
                            id:               ringItem
                            width:            42
                            height:           42
                            Layout.alignment: Qt.AlignVCenter

                            readonly property color ringColor: {
                                if (root._isCharging)          return "#30D158"
                                if (root._percentage <= 10)    return "#FF453A"
                                if (root._percentage <= 20)    return "#FF9F0A"
                                return "#ffffff"
                            }

                            onRingColorChanged:    ringCanvas.requestPaint()
                            Component.onCompleted: ringCanvas.requestPaint()

                            Connections {
                                target: root
                                function on_PercentageChanged() { ringCanvas.requestPaint() }
                                function on_IsChargingChanged() { ringCanvas.requestPaint() }
                            }

                            Canvas {
                                id:           ringCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx  = width / 2
                                    var cy  = height / 2
                                    var r   = width / 2 - 3.5
                                    var lw  = 4
                                    var pct = Math.max(0, Math.min(1, root._percentage / 100.0))

                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.18)
                                    ctx.lineWidth   = lw
                                    ctx.stroke()

                                    if (pct > 0) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, -Math.PI / 2,
                                                -Math.PI / 2 + Math.PI * 2 * pct)
                                        ctx.strokeStyle = ringItem.ringColor
                                        ctx.lineWidth   = lw
                                        ctx.lineCap     = "round"
                                        ctx.stroke()
                                    }
                                }
                            }

                            CFText {
                                anchors.centerIn: parent
                                text:             Math.round(root._percentage).toString()
                                font.pixelSize:   12
                                font.weight:      Font.Bold
                                color:            "#ffffff"
                            }
                        }
                    }
                }
            }
        }
    }
}
