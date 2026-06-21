import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.ui.glass
import qs.ui.primitives

Scope {
    id: root

    property real brtValue:    0.65
    property real kbdBrtValue: 0.0
    property bool blocked:     false

    property string _brtPath:     ""
    property string _kbdPath:     ""
    property string _kbdMaxPath:  ""
    property bool   _kbdFound:    false

    property bool _ready:    false
    property bool _brtReady: false
    property bool _kbdReady: false

    property bool   _visible:      false
    property string _currentType:  ""
    property real   _currentValue: 0.0
    property string _currentLabel: ""
    property color  _currentFill:  "#F5A623"
    property string _currentIconL: ""
    property string _currentIconH: ""
    property int    _currentSteps: 16

    property real _lastKbdValue: -1.0
    property real _lastBrtValue: -1.0

    Timer {
        id: _bootGuard
        interval: 1200
        repeat:   false
        running:  true
        onTriggered: root._ready = true
    }

    Timer {
        id: _brtBootGuard
        interval: 1200
        repeat:   false
        running:  true
        onTriggered: root._brtReady = true
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (!root._ready || root.blocked) return
            var sink = Pipewire.defaultAudioSink
            if (sink && sink.audio && sink.audio.muted && sink.audio.volume > 0) {
                sink.audio.muted = false
                return
            }
            root._showVolume()
        }
        function onMutedChanged() {
            if (!root._ready || root.blocked) return
            root._showVolume()
        }
    }

    function _showVolume() {
        var sink = Pipewire.defaultAudioSink
        var desc = sink && sink.properties ? sink.properties["node.description"] || "" : ""
        var muted = sink && sink.audio ? sink.audio.muted : false
        var vol   = sink && sink.audio ? sink.audio.volume : 0
        _currentType  = "volume"
        _currentValue = muted ? 0.0 : vol
        _currentLabel = desc || (sink ? sink.name : "") || "Volume"
        _currentFill  = "#F5A623"
        _currentIconL = "volume/audio-volume-1.svg"
        _currentIconH = "volume/audio-volume-3.svg"
        _currentSteps = 16
        _trigger()
    }

    onBrtValueChanged: {
        if (!root._brtReady || root.blocked) return
        _currentType  = "brightness"
        _currentValue = root.brtValue
        _currentLabel = "Luminosité"
        _currentFill  = "#1C7AFF"
        _currentIconL = "sun-small.svg"
        _currentIconH = "sun-huge.svg"
        _currentSteps = 20
        _trigger()
    }

    onKbdBrtValueChanged: {
        if (!root._kbdReady || root.blocked) return
        _currentType  = "kbdbrt"
        _currentValue = root.kbdBrtValue
        _currentLabel = "Luminosité clavier"
        _currentFill  = "#FFD60A"
        _currentIconL = "brightness/display-brightness-off-symbolic.svg"
        _currentIconH = "brightness/display-brightness-symbolic.svg"
        _currentSteps = 10
        _trigger()
    }

    function _trigger() {
        _hideTimer.restart()
        _panelLoader.active = true
        _visible = true
    }

    Process {
        id: _brtFindDev
        command: ["sh", "-c", "ls /sys/class/backlight/ | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var dev = text.trim()
                if (dev !== "") root._brtPath = "/sys/class/backlight/" + dev + "/brightness"
                _brtPoll.running = true
            }
        }
    }

    Process {
        id: _brtRead
        command: ["sh", "-c",
            "cat " + root._brtPath + " 2>/dev/null && cat " + root._brtPath.replace("/brightness", "/max_brightness") + " 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n")
                if (parts.length === 2) {
                    var cur = parseFloat(parts[0])
                    var max = parseFloat(parts[1])
                    if (max > 0) {
                        var v = cur / max
                        if (Math.abs(v - root._lastBrtValue) > 0.005) {
                            root._lastBrtValue = v
                            root.brtValue = v
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: _brtPoll
        interval: 300
        repeat:   true
        running:  false
        triggeredOnStart: true
        onTriggered: {
            if (root._brtPath !== "") _brtRead.running = true
        }
    }

    Process {
        id: _kbdInitProc
        command: ["sh", "-c", "ls /sys/class/leds/ | grep -i kbd | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var name = text.trim()
                if (name !== "") {
                    root._kbdPath    = "/sys/class/leds/" + name + "/brightness"
                    root._kbdMaxPath = "/sys/class/leds/" + name + "/max_brightness"
                    root._kbdFound   = true
                    _kbdPoll.running = true
                }
            }
        }
    }

    Process {
        id: _kbdRead
        command: ["sh", "-c",
            "cat " + root._kbdPath + " 2>/dev/null && cat " + root._kbdMaxPath + " 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n")
                if (parts.length === 2) {
                    var cur = parseFloat(parts[0])
                    var max = parseFloat(parts[1])
                    if (max > 0) {
                        var v = cur / max
                        if (Math.abs(v - root._lastKbdValue) > 0.01) {
                            if (root._lastKbdValue >= 0) {
                                root._kbdReady = true
                            }
                            root._lastKbdValue = v
                            root.kbdBrtValue = v
                        } else if (!root._kbdReady && root._lastKbdValue >= 0) {
                            root._kbdReady = true
                        }
                        if (root._lastKbdValue < 0) root._lastKbdValue = v
                    }
                }
            }
        }
    }

    Timer {
        id: _kbdPoll
        interval: 300
        repeat:   true
        running:  false
        triggeredOnStart: true
        onTriggered: {
            if (root._kbdFound) _kbdRead.running = true
        }
    }

    Component.onCompleted: {
        _brtFindDev.running  = true
        _kbdInitProc.running = true
    }

    Timer {
        id: _hideTimer
        interval: 2400
        repeat:   false
        onTriggered: root._visible = false
    }

    Timer {
        id: _unloadTimer
        interval: 250
        repeat:   false
        onTriggered: _panelLoader.active = false
    }

    on_VisibleChanged: {
        if (!_visible) _unloadTimer.restart()
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

                WlrLayershell.namespace:     "quickshell:osd"
                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                color:         "transparent"
                exclusiveZone: -1

                anchors {
                    top:   true
                    right: true
                }

                implicitWidth:  320
                implicitHeight: 106

                Item {
                    id: pill
                    width:  300
                    height: 66
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   40
                    anchors.rightMargin: 12

                    opacity: root._visible ? 1.0 : 0.0
                    scale:   root._visible ? 1.0 : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration:    200
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration:    220
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.25
                        }
                    }

                    transformOrigin: Item.TopRight

                    BoxGlass {
                        anchors.fill: parent
                        radius:       16
                        color:        "#30000000"
                        light:        "#55ffffff"
                        rimSize:      0.014
                        rimStrength:  1.1
                    }

                    Item {
                        id: contentArea
                        anchors {
                            fill:         parent
                            leftMargin:   14
                            rightMargin:  14
                            topMargin:    9
                            bottomMargin: 9
                        }

                        CFText {
                            id: _label
                            anchors.top:  parent.top
                            anchors.left: parent.left
                            text:           root._currentLabel
                            font.pixelSize: 12
                            font.weight:    Font.Bold
                            color:          "#ffffff"
                        }

                        Item {
                            id: sliderRow
                            anchors.top:       _label.bottom
                            anchors.left:      parent.left
                            anchors.right:     parent.right
                            anchors.topMargin: 7
                            height: 16

                            CFVI {
                                id: iconLeft
                                anchors.left:           parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                icon:  root._currentIconL
                                size:  14
                                color: "#bbffffff"
                            }

                            CFVI {
                                id: iconRight
                                anchors.right:          parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                icon:  root._currentIconH
                                size:  18
                                color: "#ffffffff"
                            }

                            Item {
                                id: trackArea
                                anchors.left:           iconLeft.right
                                anchors.right:          iconRight.left
                                anchors.leftMargin:     8
                                anchors.rightMargin:    8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6

                                Rectangle {
                                    anchors.fill: parent
                                    radius:       3
                                    color:        Qt.rgba(1, 1, 1, 0.20)
                                }

                                Rectangle {
                                    anchors.left:   parent.left
                                    anchors.top:    parent.top
                                    anchors.bottom: parent.bottom
                                    radius:         3
                                    color:          root._currentFill
                                    width: {
                                        var v = Math.max(0.0, Math.min(1.0, root._currentValue))
                                        return Math.max(6, parent.width * v)
                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            duration:    90
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            id: dotsRow
                            anchors.top:         sliderRow.bottom
                            anchors.topMargin:   5
                            anchors.left:        sliderRow.left
                            anchors.leftMargin:  iconLeft.width + 8
                            anchors.right:       sliderRow.right
                            anchors.rightMargin: iconRight.width + 8

                            Repeater {
                                model: root._currentSteps
                                delegate: Item {
                                    required property int index
                                    width:  dotsRow.width / root._currentSteps
                                    height: 8

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width:   4
                                        height:  4
                                        radius:  2
                                        color: (index + 1) <= Math.round(root._currentValue * root._currentSteps)
                                               ? "#ffffffff"
                                               : Qt.rgba(1, 1, 1, 0.28)

                                        Behavior on color {
                                            ColorAnimation { duration: 80 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
