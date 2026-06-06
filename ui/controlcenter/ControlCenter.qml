import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import "./panels"
import "../components/glass"

Scope {
    id: root

    
    property bool opened: false
    signal closing()

    property bool wifiOpened: false
    property bool btOpened:   false
    property bool subOpened:  wifiOpened || btOpened

   
    readonly property int box:   68
    readonly property int bm:    10
    readonly property int cols:  4
    readonly property int gridW: cols*(box+bm)+bm

    function gx(c) { return c*(box+bm)+bm }
    function gy(r) { return r*(box+bm)+bm }

   
    readonly property color glassOff: Qt.rgba(1, 1, 1, 0.06)
    readonly property color glassOn:  Qt.rgba(1, 1, 1, 0.88)
    readonly property color rimOff:   Qt.rgba(1, 1, 1, 0.22)
    readonly property color rimOn:    Qt.rgba(1, 1, 1, 0.65)
    readonly property int   dur: 260
    
    Process { id: _kdeConnect; command: ["kdeconnect-app"] }

	
    //close cc on move

    property string _currentWs: ""

Process {
    id: _wsGet
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
        onStreamFinished: {
            try {
                var ws = JSON.parse(text.trim())
                if (root._currentWs === "") {
                    root._currentWs = ws.name
                } else if (ws.name !== root._currentWs) {
                    root._currentWs = ws.name
                    root.wifiOpened = false
                    root.btOpened   = false
                    root.closing()
                }
            } catch(e) {}
        }
    }
}

Timer {
    interval: 300
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: _wsGet.running = true
}

    // État WiFi
    property bool   wifiOn:   false
    property string wifiSSID: "Wi-Fi"

    // Radio state — séparé du réseau actif
    Process {
        id: _nmRadioGet
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }

    //player

    property string musicTitle:  "Not Playing"
    property string musicArtist: ""

    // SSID actif seulement — ne touche PAS wifiOn
    Process {
        id: _nmStatus
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID device wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var s = text.trim()
                root.wifiSSID = s !== "" ? s : "Wi-Fi"
            }
        }
    }
    Process { id: _nmOn;  command: ["nmcli", "radio", "wifi", "on"]  }
    Process { id: _nmOff; command: ["nmcli", "radio", "wifi", "off"] }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { _nmRadioGet.running = true; _nmStatus.running = true }
    }

    // Media
    property bool   musicPlaying: false
    property string musicArt:     ""

    Process {
        id: _pTitle
        command: ["sh", "-c", "playerctl metadata title 2>/dev/null || echo ''"]
        stdout: StdioCollector { onStreamFinished: root.musicTitle  = text.trim() || "Not Playing" }
    }
    Process {
        id: _pArtist
        command: ["sh", "-c", "playerctl metadata artist 2>/dev/null || echo ''"]
        stdout: StdioCollector { onStreamFinished: root.musicArtist = text.trim() }
    }
    Process {
        id: _pStatus
        command: ["sh", "-c", "playerctl status 2>/dev/null || echo ''"]
        stdout: StdioCollector { onStreamFinished: root.musicPlaying = text.trim() === "Playing" }
    }
    Process {
        id: _pArt
        command: ["sh", "-c", "playerctl metadata mpris:artUrl 2>/dev/null || echo ''"]
        stdout: StdioCollector { onStreamFinished: root.musicArt = text.trim() }
    }
    Process { id: _pPrev; command: ["sh", "-c", "playerctl previous   2>/dev/null"] }
    Process { id: _pPlay; command: ["sh", "-c", "playerctl play-pause 2>/dev/null"] }
    Process { id: _pNext; command: ["sh", "-c", "playerctl next       2>/dev/null"] }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _pTitle.running  = true
            _pArtist.running = true
            _pStatus.running = true
            _pArt.running    = true
        }
    }

    // Volume
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Process { id: _muteCmd; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }

    // Brightness
    property real brtValue: 0.65
    Process {
        id: _brtGet
        command: ["sh", "-c", "echo \"$(brightnessctl get)/$(brightnessctl max)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split("/")
                if (p.length === 2) {
                    var c = parseFloat(p[0])
                    var m = parseFloat(p[1])
                    if (m > 0) root.brtValue = Math.max(0, Math.min(1, c / m))
                }
            }
        }
    }
    Process { id: _brtSet; command: [] }
    Timer {
        id: _brtT
        interval: 80
        repeat: false
        onTriggered: {
            _brtSet.command = ["brightnessctl", "set", Math.round(root.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }
    Timer {
        interval: 500
        running: true
        repeat: false
        triggeredOnStart: true
        onTriggered: {
            _brtGet.running = true
            _dndStatus.running = true
        }
    }

    // Focus / Dark
    property bool focusOn: false
    property bool darkOn:  false
    property bool recording: false

    Process { id: _dndOn;      command: ["dunstctl", "set-paused", "true"]  }
    Process { id: _dndOff;     command: ["dunstctl", "set-paused", "false"] }
    Process {
        id: _dndStatus
        command: ["dunstctl", "is-paused"]
        stdout: StdioCollector {
            onStreamFinished: root.focusOn = text.trim() === "true"
        }
    }
    Process { id: _darkToggleCmd; command: ["sh", "-c", "~/.config/hypr/scripts/toggle-theme.sh"] }
    Process { id: _timerCmd;   command: ["foot", "--title=timer", "-e", "tty-clock", "-c", "-s"] }
    Process { id: _calcCmd;    command: ["gnome-calculator"] }
    Process { id: _shOn;       command: ["sh", "-c", "wf-recorder -f ~/Videos/screencast_$(date +%s).mp4"] }
    Process { id: _shOff;      command: ["killall", "-SIGINT", "wf-recorder"] }

    // PanelWindow full-screen
  Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                anchors.top:    true
                anchors.right:  true
                anchors.bottom: true
                anchors.left:   true
                WlrLayershell.namespace:     "quickshell:cc"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer:         WlrLayer.Overlay
                color:         "transparent"
                exclusiveZone: -1

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.0)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.wifiOpened = false
                            root.btOpened   = false
                            //root.opened     = false
                            root.closing()
                        }
                    }
                }

                Item {
                    id: _grid
        width:  root.gridW
        height: 6*(root.box+root.bm)+root.bm
        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   24
        anchors.rightMargin: 0
        opacity: root.opened ? 1 : 0
        enabled: root.opened
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked:  function(e) { e.accepted = true }
            onPressed:  function(e) { e.accepted = true }
        }
    }    

            // Brique glass réutilisable
            component GBtn: Item {
                id: _gb
                property bool  active: false
                property bool  hidden: false
                property real  cr:     40
                property bool showHighlight: true
	 	opacity: hidden ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: root.dur/2 } }
                Behavior on width   { NumberAnimation { duration: root.dur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                Behavior on height  { NumberAnimation { duration: root.dur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                Behavior on anchors.topMargin  { NumberAnimation { duration: root.dur; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                Behavior on anchors.leftMargin { NumberAnimation { duration: root.dur; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }

                BoxGlass {
                    id: _gbBg
                    anchors.fill:      parent
                    radius:            _gb.cr
                    color:             _gb.active ? root.glassOn : root.glassOff
                    light:             _gb.active ? root.rimOn   : root.rimOff
                    rimStrength:       0.6
                    highlightEnabled:  _gb.showHighlight
                    lightDir:          Qt.vector2d(0.5, -1.0)

                    Behavior on color { ColorAnimation { duration: root.dur/2 } }
                }
            }

            // ── ROW 0 : Wi-Fi (2×1) ──────────────────────────
            GBtn {
                id: _wBtn
		showHighlight: !root.wifiOpened
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.wifiOpened ? root.gy(0) : root.gy(0)
                anchors.leftMargin: root.gx(0)
                width:  root.wifiOpened ? root.gridW : root.box*2+root.bm
                height: root.wifiOpened ? _wPanel.implicitHeight + 10 : root.box
                cr:     root.wifiOpened ? 20 : 40
                hidden: root.btOpened
                active: !root.wifiOpened && root.wifiOn

                Rectangle {
                    id: _wCircle
                    width: 34
                    height: 34
                    radius: 17
                    anchors.left:          parent.left
                    anchors.leftMargin:    13
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.wifiOpened
                    color: root.wifiOn ? "#1C7AFF" : Qt.rgba(1,1,1,0.18)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    VectorImage {
                        anchors.centerIn: parent
                        width: 20
                        height: 15
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/wifi/wifi.svg")
                        preferredRendererType: VectorImage.CurveRenderer
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1
                            colorizationColor: "#fff" }
                    }
                }

                Column {
                    anchors.left:           _wCircle.right
                    anchors.leftMargin:     9
                    anchors.verticalCenter: _wCircle.verticalCenter
                    visible: !root.wifiOpened
                    spacing: 2

                    Text {
                        text: "Wi-Fi"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: "SF Pro Display"
                        color: root.wifiOn ? "#111" : "#fff"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        text: root.wifiSSID
                        font.pixelSize: 10
                        font.family: "SF Pro Display"
                        elide: Text.ElideRight
                        width: root.box - 10
                        color: root.wifiOn ? Qt.rgba(0,0,0,0.45) : Qt.rgba(1,1,1,0.55)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                CCWifiPanel {
                    id: _wPanel
                    anchors.top:   parent.top
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 5
                    visible: root.wifiOpened
                    opacity: root.wifiOpened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: root.dur/2 } }
                }

                MouseArea {
                    anchors.fill: parent
                    pressAndHoldInterval: 400
                    onClicked: {
                        if (root.wifiOpened) {
                            // Ferme la popup
                            root.wifiOpened = false
                        } else if (!root.subOpened) {
                            // Toggle WiFi
                            root.wifiOn = !root.wifiOn
                            if (root.wifiOn) _nmOn.running = true
                                else _nmOff.running = true
                        }
                    }
                    onPressAndHold: {
                        root.wifiOpened = true
                        root.btOpened   = false
                    }
                    onPressed:  _wBtn.scale = 0.93
                    onReleased: _wBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
            }

            // ── ROW 1 : BT (1×1) ─────────────────────────────
            GBtn {
                id: _btBtn
		showHighlight: !root.btOpened
                property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.btOpened ? root.gy(0) : root.gy(1)
                anchors.leftMargin: root.gx(0)
                width:  root.btOpened ? root.gridW : root.box
                height: root.btOpened ? _btPanel.implicitHeight + 10 : root.box
                cr:     root.btOpened ? 20 : 999
                hidden: root.wifiOpened
                active: !root.btOpened && _btBtn.btOn

                VectorImage {
                    anchors.centerIn: parent
                    width: 22
                    height: 28
                    visible: !root.btOpened
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/bluetooth/bluetooth.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: _btBtn.btOn ? "#1C7AFF" : "#fff"
                    }
                }

                CCBluetoothPanel {
                    id: _btPanel
                    anchors.top:   parent.top
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 5
                    visible: root.btOpened
                    opacity: root.btOpened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: root.dur/2 } }
                }

                MouseArea {
                    anchors.fill: parent
                    pressAndHoldInterval: 400
                    onClicked: {
                        if (root.btOpened) {
                            root.btOpened = false
                        } else if (!root.subOpened) {
                            // Toggle BT
                            if (Bluetooth.defaultAdapter)
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                        }
                        root.wifiOpened = false
                    }
                    onPressAndHold: {
                        root.btOpened   = true
                        root.wifiOpened = false
                    }
                    onPressed:  _btBtn.scale = 0.90
                    onReleased: _btBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
            }

            // ── AirDrop (1×1) ─────────────────────────────────
	    GBtn {
    id: _adBtn
    anchors.top:        _grid.top
    anchors.left:       _grid.left
    anchors.topMargin:  root.gy(1)
    anchors.leftMargin: root.gx(1)
    width: root.box
    height: root.box
    cr: 999
    hidden: root.wifiOpened || root.btOpened

    VectorImage {
        anchors.centerIn: parent
        width: 26
        height: 26
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/devices/smartphone.svg")
        preferredRendererType: VectorImage.CurveRenderer
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1
            colorizationColor: "#fff" }
    }
    MouseArea {
        anchors.fill: parent
        onClicked:  _kdeConnect.running = true
        onPressed:  _adBtn.scale = 0.90
        onReleased: _adBtn.scale = 1.0
    }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
}


            // ── Musique (2×2) ──────────────────────────────────
            GBtn {
                id: _mBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(0)
                anchors.leftMargin: root.gx(2)
                width:  root.box*2+root.bm
                height: root.box*2+root.bm
                cr: 26
                hidden: root.wifiOpened || root.btOpened

                Rectangle {
                    id: _art
                    anchors.top:     parent.top
                    anchors.left:    parent.left
                    anchors.topMargin:  12
                    anchors.leftMargin: 12
                    width: 44
                    height: 44
                    radius: 9
                    color: Qt.rgba(1,1,1,0.18)

                    Image {
                        anchors.fill: parent
                        source: root.musicArt
                        fillMode: Image.PreserveAspectCrop
                        visible: root.musicArt !== ""
                        layer.enabled: true
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: 22
                        color: Qt.rgba(1,1,1,0.55)
                        visible: root.musicArt === ""
                    }
                }

                Text {
                    id: _titleTxt
                    anchors.top:        _art.bottom
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.topMargin:  8
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    text: root.musicTitle
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.family: "SF Pro Display"
                    color: "#fff"
                    elide: Text.ElideRight
                }
                Text {
                    id: _artistTxt
                    anchors.top:        _titleTxt.bottom
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.topMargin:  2
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    text: root.musicArtist
                    font.pixelSize: 10
                    font.family: "SF Pro Display"
                    color: Qt.rgba(1,1,1,0.55)
                    elide: Text.ElideRight
                }

                Row {
                    anchors.bottom:           parent.bottom
                    anchors.bottomMargin:     12
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Qt.rgba(1,1,1,0.14)
                        VectorImage {
                            anchors.centerIn: parent
                            width: 18
                            height: 14
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/music/backward.svg")
                            preferredRendererType: VectorImage.CurveRenderer
                            layer.enabled: true
                            layer.effect: MultiEffect { colorization: 1
                                colorizationColor: "#fff" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: _pPrev.running = true; onPressed: parent.scale = 0.85; onReleased: parent.scale = 1.0 }
                        Behavior on scale { NumberAnimation { duration: 80 } }
                    }
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Qt.rgba(1,1,1,0.14)
                        VectorImage {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: root.musicPlaying
                            ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/music/pause.svg")
                            : Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/music/play.svg")
                            preferredRendererType: VectorImage.CurveRenderer
                            layer.enabled: true
                            layer.effect: MultiEffect { colorization: 1
                                colorizationColor: "#fff" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: _pPlay.running = true; onPressed: parent.scale = 0.85; onReleased: parent.scale = 1.0 }
                        Behavior on scale { NumberAnimation { duration: 80 } }
                    }
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Qt.rgba(1,1,1,0.14)
                        VectorImage {
                            anchors.centerIn: parent
                            width: 18
                            height: 14
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/music/forward.svg")
                            preferredRendererType: VectorImage.CurveRenderer
                            layer.enabled: true
                            layer.effect: MultiEffect { colorization: 1
                                colorizationColor: "#fff" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: _pNext.running = true; onPressed: parent.scale = 0.85; onReleased: parent.scale = 1.0 }
                        Behavior on scale { NumberAnimation { duration: 80 } }
                    }
                }
            }

            // ── ROW 2 : Focus | Stage | Screenshare ───────────
            GBtn {
                id: _fBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(2)
                anchors.leftMargin: root.gx(0)
                width: root.box*2+root.bm
                height: root.box
                cr: 40
                hidden: root.wifiOpened || root.btOpened
                active: root.focusOn

                VectorImage {
                    id: _fIco
                    anchors.left:          parent.left
                    anchors.leftMargin:    14
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/dnd.svg")
                    width: 36
                    height: 36
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: root.focusOn ? "#1C7AFF" : "#fff" }
                }
                Text {
                    anchors.left:           _fIco.right
                    anchors.leftMargin:     8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Focus"
                    font.pixelSize: 13
                    font.weight: Font.SemiBold
                    font.family: "SF Pro Display"
                    color: root.focusOn ? "#111" : "#fff"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.focusOn = !root.focusOn; if (root.focusOn) _dndOn.running = true; else _dndOff.running = true }
                    onPressed:  _fBtn.scale = 0.93
                    onReleased: _fBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
            }

            GBtn {
                id: _stBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(2)
                anchors.leftMargin: root.gx(2)
                width: root.box
                height: root.box
                cr: 22
                hidden: root.wifiOpened || root.btOpened

                VectorImage {
                    anchors.centerIn: parent
                    width: 24
                    height: 20
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/stageman.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }
                MouseArea { anchors.fill: parent; onPressed: _stBtn.scale = 0.88; onReleased: _stBtn.scale = 1.0 }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            GBtn {
                id: _shBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(2)
                anchors.leftMargin: root.gx(3)
                width: root.box
                height: root.box
                cr: 22
                hidden: root.wifiOpened || root.btOpened
                active: root.recording

                VectorImage {
                    anchors.centerIn: parent
                    width: 26
                    height: 20
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/screenshare.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: root.recording ? "#1C7AFF" : "#fff"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.recording = !root.recording
                        if (root.recording) _shOn.running = true
                            else _shOff.running = true
                    }
                    onPressed: _shBtn.scale = 0.88
                    onReleased: _shBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // ── ROW 3 : Display slider ─────────────────────────
            GBtn {
                id: _dBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(3)
                anchors.leftMargin: root.gx(0)
                width: root.box*4+root.bm*3
                height: root.box
                cr: 26
                hidden: root.wifiOpened || root.btOpened

                Text {
                    id: _dLbl
                    anchors.top:       parent.top
                    anchors.left:      parent.left
                    anchors.topMargin: 9
                    anchors.leftMargin: 15
                    text: "Display"
                    font.pixelSize: 10
                    font.weight: Font.SemiBold
                    font.family: "SF Pro Display"
                    color: Qt.rgba(1,1,1,0.80)
                }

                VectorImage {
                    anchors.right:         _bTk.left
                    anchors.rightMargin:   6
                    anchors.verticalCenter: _bTk.verticalCenter
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/sun-small.svg")
                    width: 14
                    height: 14
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }

                Item {
                    id: _bTk
                    anchors.top:        _dLbl.bottom
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.topMargin:  7
                    anchors.leftMargin: 30
                    anchors.rightMargin: 30
                    height: 22

                    Rectangle { anchors.fill: parent; radius: 11; color: Qt.rgba(1,1,1,0.20) }

                    Rectangle {
                        id: _bFill
                        width: Math.max(30, _bTk.width * root.brtValue)
                        height: parent.height
                        radius: 11
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#49a3fc" }
                            GradientStop { position: 1.0; color: "#3681ee" }
                        }
                        Behavior on width { NumberAnimation { duration: 60 } }

                        Rectangle {
                            id: _bThumb
                            anchors.right:         parent.right
                            anchors.rightMargin:   -14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            height: 34
                            radius: 17
                            color: "white"

                            Rectangle {
                                anchors.top:              parent.top
                                anchors.topMargin:        2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.55
                                height: 1
                                radius: 1
                                color: Qt.rgba(1,1,1,0.90)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        property real _sx: 0
                        property real _sv: 0
                        onPressed:  function(m) { _sx = m.x; _sv = root.brtValue; _bThumb.scale = 1.05 }
                        onReleased: _bThumb.scale = 1.0
                        onPositionChanged: function(m) {
                            root.brtValue = Math.max(0, Math.min(1, _sv + (m.x - _sx) / _bTk.width))
                            _brtT.restart()
                        }
                        onWheel: function(w) {
                            root.brtValue = Math.max(0, Math.min(1, root.brtValue + w.angleDelta.y / 1200))
                            _brtT.restart()
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }

                VectorImage {
                    anchors.left:          _bTk.right
                    anchors.leftMargin:    6
                    anchors.verticalCenter: _bTk.verticalCenter
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/sun-huge.svg")
                    width: 18
                    height: 18
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }
            }

            // ── ROW 4 : Sound slider ───────────────────────────
            GBtn {
                id: _sBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(4)
                anchors.leftMargin: root.gx(0)
                width: root.box*4+root.bm*3
                height: root.box
                cr: 26
                hidden: root.wifiOpened || root.btOpened

                Text {
                    id: _sLbl
                    anchors.top:        parent.top
                    anchors.left:       parent.left
                    anchors.topMargin:  9
                    anchors.leftMargin: 15
                    text: "Sound"
                    font.pixelSize: 10
                    font.weight: Font.SemiBold
                    font.family: "SF Pro Display"
                    color: Qt.rgba(1,1,1,0.80)
                }

                VectorImage {
                    anchors.right:          _vTk.left
                    anchors.rightMargin:    6
                    anchors.verticalCenter: _vTk.verticalCenter
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/volume/audio-volume-1.svg")
                    width: 14
                    height: 14
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }

                Item {
                    id: _vTk
                    anchors.top:         _sLbl.bottom
                    anchors.left:        parent.left
                    anchors.right:       _mBtn2.left
                    anchors.topMargin:   7
                    anchors.leftMargin:  30
                    anchors.rightMargin: 8
                    height: 22
                    property real vol: Pipewire.defaultAudioSink ? (Pipewire.defaultAudioSink.audio.volume) : 0

                    Rectangle { anchors.fill: parent; radius: 11; color: Qt.rgba(1,1,1,0.20) }

                    Rectangle {
                        id: _vFill
                        width: Math.max(30, _vTk.width * Math.min(_vTk.vol, 1.0))
                        height: parent.height
                        radius: 11
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#49a3fc" }
                            GradientStop { position: 1.0; color: "#3681ee" }
                        }
                        Behavior on width { NumberAnimation { duration: 60 } }

                        Rectangle {
                            id: _vThumb
                            anchors.right:          parent.right
                            anchors.rightMargin:    -14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            height: 34
                            radius: 17
                            color: "white"

                            Rectangle {
                                anchors.top:              parent.top
                                anchors.topMargin:        2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.55
                                height: 1
                                radius: 1
                                color: Qt.rgba(1,1,1,0.90)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        property real _sx: 0
                        property real _sv: 0
                        onPressed:  function(m) { _sx = m.x; _sv = _vTk.vol; _vThumb.scale = 1.05 }
                        onReleased: _vThumb.scale = 1.0
                        onPositionChanged: function(m) {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, _sv + (m.x - _sx) / _vTk.width))
                        }
                        onWheel: function(w) {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                                Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, _vTk.vol + w.angleDelta.y / 1200))
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }

                VectorImage {
                    anchors.right:          _mBtn2.left
                    anchors.rightMargin:    6
                    anchors.verticalCenter: _vTk.verticalCenter
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/volume/audio-volume-3.svg")
                    width: 18
                    height: 18
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }

                Rectangle {
                    id: _mBtn2
                    anchors.right:          parent.right
                    anchors.rightMargin:    12
                    anchors.verticalCenter: _vTk.verticalCenter
                    width: 34
                    height: 34
                    radius: 10
                    color: Qt.rgba(1,1,1,0.13)
                    border.color: Qt.rgba(1,1,1,0.22)
                    border.width: 0.8

                    Rectangle {
                        anchors.top:              parent.top
                        anchors.topMargin:        1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.48
                        height: 1
                        radius: 1
                        color: Qt.rgba(1,1,1,0.45)
                    }

                    VectorImage {
                        anchors.centerIn: parent
                        width: 16
                        height: 14
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/volume/audio-volume-0.svg")
                        preferredRendererType: VectorImage.CurveRenderer
                        layer.enabled: true
                        layer.effect: MultiEffect { colorization: 1
                            colorizationColor: "#fff" }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked:  _muteCmd.running = true
                        onPressed:  _mBtn2.scale = 0.88
                        onReleased: _mBtn2.scale = 1.0
                    }
                    Behavior on scale { NumberAnimation { duration: 80 } }
                }
            }

            // ── ROW 5 : Dark Mode | Timer | Calc ──────────────
            GBtn {
                id: _dkBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(5)
                anchors.leftMargin: root.gx(0)
                width: root.box*2+root.bm
                height: root.box
                cr: 40
                hidden: root.wifiOpened || root.btOpened
                active: root.darkOn

                Rectangle {
                    anchors.left:           parent.left
                    anchors.leftMargin:     14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: root.darkOn ? "#111" : Qt.rgba(1,1,1,0.88)

                    VectorImage {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: root.darkOn ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/moon.svg") : Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/weather/sun.svg")
                        preferredRendererType: VectorImage.CurveRenderer
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: root.darkOn ? "#fff" : "#111"
                        }
                    }
                }

                Column {
                    anchors.left:           parent.left
                    anchors.leftMargin:     48
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Dark Mode"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: "SF Pro Display"
                        color: root.darkOn ? "#111" : "#fff"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        text: root.darkOn ? "On" : "Off"
                        font.pixelSize: 10
                        font.family: "SF Pro Display"
                        color: root.darkOn ? Qt.rgba(0,0,0,0.42) : Qt.rgba(1,1,1,0.52)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.darkOn = !root.darkOn
                        _darkToggleCmd.running = true
                    }
                    onPressed:  _dkBtn.scale = 0.93
                    onReleased: _dkBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
            }

            GBtn {
                id: _tmBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(5)
                anchors.leftMargin: root.gx(2)
                width: root.box
                height: root.box
                cr: 999
                hidden: root.wifiOpened || root.btOpened

                VectorImage {
                    anchors.centerIn: parent
                    width: 26
                    height: 28
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/screenshot/timer.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked:  _timerCmd.running = true
                    onPressed:  _tmBtn.scale = 0.86
                    onReleased: _tmBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
            }

            GBtn {
                id: _clBtn
                anchors.top:        _grid.top
                anchors.left:       _grid.left
                anchors.topMargin:  root.gy(5)
                anchors.leftMargin: root.gx(3)
                width: root.box
                height: root.box
                cr: 999
                hidden: root.wifiOpened || root.btOpened

                VectorImage {
                    anchors.centerIn: parent
                    width: 20
                    height: 24
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/settings/calculator.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1
                        colorizationColor: "#fff" }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked:  _calcCmd.running = true
                    onPressed:  _clBtn.scale = 0.86
                    onReleased: _clBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
            }

        } // fin _grid
    } // fin PanelWindow
  }
}  // fin Scope
