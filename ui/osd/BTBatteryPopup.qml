import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components.glass
import qs.components

Scope {
    id: root

    property string deviceName: ""
    property real   pct:        -1
    property bool   isCharging: false
    property bool   _isAirpods: false
    property int    xPos:       0
    property bool   _visible:   false

    function toggle() {
        if (_visible) {
            _visible = false
            _unloadTimer.restart()
        } else {
            _panelLoader.active = true
            _visible = true
            _hideTimer.restart()
        }
    }

    function dismiss() {
        _visible = false
        _unloadTimer.restart()
    }

    Timer {
        id: _hideTimer
        interval: 4000
        repeat:   false
        onTriggered: root.dismiss()
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

                WlrLayershell.namespace:     "quickshell:btbattery"
                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                color:         "transparent"
                exclusiveZone: -1

                anchors {
                    top:   true
                    left:  true
                    right: true
                }

                implicitWidth:  324
                implicitHeight: 108

                Item {
                    id: pill
                    width:  300
                    height: 54
                    anchors.top:         parent.top
                    anchors.left:        parent.left
                    anchors.topMargin:   40
                    anchors.leftMargin:  root.xPos - 140

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
                            icon:             "bluetooth/bluetooth.svg"
                            size:             18
                            color:            "#ccffffff"
                            Layout.alignment: Qt.AlignVCenter
                            visible:          !root._isAirpods
                        }

                        Image {
                            source:            Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/devices/airpods.png")
                            width:             22
                            height:            18
                            fillMode:          Image.PreserveAspectFit
                            sourceSize.width:  44
                            sourceSize.height: 44
                            Layout.alignment:  Qt.AlignVCenter
                            visible:           root._isAirpods
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing:          2

                            CFText {
                                text:                root.deviceName
                                font.pixelSize:      13
                                font.weight:         Font.Bold
                                color:               "#ffffff"
                                elide:               Text.ElideRight
                                Layout.fillWidth:    true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            CFText {
                                text:                "Connecté"
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
                            visible:          root.pct >= 0

                            readonly property color ringColor: {
                                if (root.pct <= 10) return "#FF453A"
                                if (root.pct <= 20) return "#FF9F0A"
                                return "#30D158"
                            }

                            onRingColorChanged:    ringCanvas.requestPaint()
                            Component.onCompleted: ringCanvas.requestPaint()

                            Connections {
                                target: root
                                function onPctChanged() { ringCanvas.requestPaint() }
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
                                    var pct = Math.max(0, Math.min(1, root.pct / 100.0))

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
                                text:             root.pct >= 0 ? Math.round(root.pct).toString() : ""
                                font.pixelSize:   12
                                font.weight:      Font.Bold
                                color:            "#ffffff"
                            }
                        }

                        CFText {
                            text:             "N/A"
                            font.pixelSize:   12
                            color:            Qt.rgba(1, 1, 1, 0.4)
                            visible:          root.pct < 0
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
