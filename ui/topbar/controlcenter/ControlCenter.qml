import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import qs.ui.topbar.controlcenter.panels
import qs.ui.glass
import qs.ui.primitives

Scope {
    id: root

    property bool opened: false
    signal closing()

    property bool wifiOpened: false
    property bool btOpened:   false
    property bool subOpened:  wifiOpened || btOpened

    readonly property int box:        65
    readonly property int boxMargin:  10
    readonly property int gridW:      4
    readonly property int gridH:      6
    readonly property int animationDur: 300

    readonly property int gridImplicitWidth:  ((box*gridW)+(boxMargin*gridW)+boxMargin)
    readonly property int gridImplicitHeight: ((box*gridH)+(boxMargin*gridH)+boxMargin)

    readonly property color glassColor: "#20000000"
    readonly property color textColor:  "#ffffff"
    readonly property color glassRimColor: "#80ffffff"
    readonly property real  glassRimStrength: 1.0

    
    Process { id: _kdeConnect; command: ["kdeconnect-app"] }
    
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

    property bool   wifiOn:   false
    property string wifiSSID: "Wi-Fi"
    property var    activeNet: null
    property var    knownNets: []
    property var    otherNets: []

    Process {
        id: _nmRadioGet
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }
    
    Process {
        id: _nmAll
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,NAME device wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var active = null
                var known = []
                var other = []
                var seen = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split(":")
                    var inuse = p[0] || ""
                    var ssid = p[1] || ""
                    var secured = p[3] ? p[3].trim() !== "--" : false
                    var name = p[4] || ""
                    if (!ssid || seen.indexOf(ssid) !== -1) continue
                    seen.push(ssid)
                    var net = { ssid: ssid, secured: secured, profile: name }
                    if (inuse === "*") active = net
                    else if (name !== "" && name !== "--") known.push(net)
                    else other.push(net)
                }
                root.activeNet = active
                root.knownNets = known
                root.otherNets = other
                if (active) root.wifiSSID = active.ssid
                else root.wifiSSID = "Wi-Fi"
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
        onTriggered: {
            _nmRadioGet.running = true
            _nmAll.running = true
        }
    }

    property string musicTitle:  "Not Playing"
    property string musicArtist: ""
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

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    property string brtPath: ""
    property string brtMaxPath: ""
    
    Process {
        id: _brtInit
        command: ["sh", "-c", "for dev in /sys/class/backlight/*; do if [ -d \"$dev\" ]; then echo \"$dev\"; break; fi; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var dev = text.trim()
                if (dev !== "") {
                    root.brtPath = dev + "/brightness"
                    root.brtMaxPath = dev + "/max_brightness"
                    _brtGet.running = true
                }
            }
        }
    }
    Component.onCompleted: _brtInit.running = true

    Process {
        id: _brtGet
        command: ["sh", "-c", "cat " + root.brtPath + " && cat " + root.brtMaxPath]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split("\n")
                if (p.length === 2) {
                    var c = parseFloat(p[0])
                    var m = parseFloat(p[1])
                    if (m > 0) {
                        var val = c / m
                        if (Math.abs(appRoot.brtValue - val) > 0.01) {
                            appRoot.brtValue = val
                        }
                    }
                }
            }
        }
    }

    FileView {
        path: root.brtPath
        watchChanges: true
        onFileChanged: {
            _brtGet.running = true
        }
    }

    Process { id: _brtSet; command: [] }
    Timer {
        id: _brtT
        interval: 50
        repeat: false
        onTriggered: {
            _brtSet.command = ["brightnessctl", "set", Math.round(appRoot.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }

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
    Process { id: _calcCmd;    command: ["foot", "--title=calculator", "-e", "python3", "/home/kelian/code/macos shell/shell gemini/tools/calculator/calc.py"] }
    Process { id: _shOn;       command: ["sh", "-c", "wf-recorder -f ~/Videos/screencast_$(date +%s).mp4"] }
    Process { id: _shOff;      command: ["killall", "-SIGINT", "wf-recorder"] }

    
    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: ccWindow
                
                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace:     "quickshell:cc"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer:         WlrLayer.Overlay
                color:         "transparent"
                exclusiveZone: -1
                
                anchors {
                    top:    true
                    right:  true
                    bottom: true
                    left:   true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.wifiOpened = false
                        root.btOpened   = false
                        root.closing()
                    }
                }

                Item {
                    id: ccContent
                    width:  root.gridImplicitWidth
                    height: root.gridImplicitHeight
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 20
                    anchors.rightMargin: 10
                    scale: root.subOpened ? 0.8 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.animationDur
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: false
                        onClicked: function(e) {
                            e.accepted = true
                        }
                    }

                    function gridX(x) {
                        return x*(root.box+root.boxMargin)+root.boxMargin
                    }
                    function gridY(y) {
                        return y*(root.box+root.boxMargin)+root.boxMargin
                    }

                    component BoxButton: BoxGlass {
                        id: boxbutton
                        radius: 40
                        property bool enabled: false
                        property bool hideCause: false
                        property bool scaleCause: false
                        property bool forceTransparentRim: false
                        property bool isPressed: false
                        
                        opacity: boxbutton.hideCause ? 0 : 1
                        scale: boxbutton.scaleCause ? 1.25 : (boxbutton.isPressed ? 0.93 : 1.0)
                        
                        transformOrigin: Item.Top
                        
                        property int xPos: 0
                        property int yPos: 0
                        property bool overwriteX: false
                        property bool overwriteY: false
                        property int overwriteXPos: 0
                        property int overwriteYPos: 0

                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: boxbutton.overwriteX ? boxbutton.overwriteXPos : ccContent.gridX(boxbutton.xPos)
                            topMargin: boxbutton.overwriteY ? boxbutton.overwriteYPos : ccContent.gridY(boxbutton.yPos)
                        }

                        Behavior on anchors.topMargin {
                            NumberAnimation {
                                duration: root.animationDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 1
                            }
                        }
                        Behavior on anchors.leftMargin {
                            NumberAnimation {
                                duration: root.animationDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 1
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.animationDur/2
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: root.animationDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.5
                            }
                        }
                        
                        light: boxbutton.forceTransparentRim ? "transparent" : root.glassRimColor
                        rimStrength: boxbutton.forceTransparentRim ? 0 : root.glassRimStrength
                        color: boxbutton.forceTransparentRim ? "transparent" : root.glassColor
                    }

                    
                    BoxButton {
                        id: wifiWidget
                        xPos: 0
                        yPos: 0
                        width: root.wifiOpened ? root.gridImplicitWidth : root.box*2+root.boxMargin
                        height: root.wifiOpened ? _wPanel.implicitHeight : root.box
                        radius: root.wifiOpened ? 12 : 40
                        enabled: root.wifiOn
                        hideCause: root.btOpened
                        scaleCause: root.wifiOpened
                        overwriteX: root.wifiOpened
                        overwriteY: root.wifiOpened
                        overwriteXPos: 0
                        overwriteYPos: 0
                        
                        z: root.wifiOpened ? 100 : 0
                        forceTransparentRim: root.wifiOpened

                        CFClippingRect {
                            anchors.fill: parent
                            radius: 12
                            visible: root.wifiOpened
                            opacity: root.wifiOpened ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: root.animationDur/2 } }
                            
                            BoxGlass {
                                anchors.fill: parent
                                radius: 12
                                color: root.glassColor
                                light: root.glassRimColor
                                rimStrength: 1.3
                                
                                MouseArea {
                                    anchors.fill: parent
                                    preventStealing: true
                                    propagateComposedEvents: false
                                    onPressed: function(e) { e.accepted = true }
                                    onClicked: function(e) { e.accepted = true }
                                }

                                CCWifiPanel {
                                    id: _wPanel
                                    width: root.gridImplicitWidth
                                    onCloseRequested: root.wifiOpened = false
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: !root.wifiOpened
                            CFClippingRect {
                                id: wifiCircle
                                width: 34
                                height: 34
                                radius: 17
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.wifiOn ? "#fff" : Qt.rgba(1,1,1,0.18)
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 25
                                    height: 25
                                    icon: "wifi/nm-signal-100-symbolic.svg"
                                    color: root.wifiOn ? "#1C7AFF" : "#fff"
                                }
                            }
                            Column {
                                anchors.left: wifiCircle.right
                                anchors.leftMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                CFText {
                                    text: "Wi-Fi"
                                    font.weight: Font.Bold
                                    font.pixelSize: 12
                                    color: "#fff"
                                }
                                CFText {
                                    text: root.wifiSSID
                                    font.pixelSize: 10
                                    color: Qt.rgba(1,1,1,0.55)
                                    width: root.box - 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.wifiOpened
                            pressAndHoldInterval: 300
                            onClicked: {
                                root.wifiOn = !root.wifiOn
                                if (root.wifiOn) {
                                    _nmOn.running = true
                                } else {
                                    _nmOff.running = true
                                }
                            }
                            onPressAndHold: {
                                root.wifiOpened = true
                                root.btOpened = false
                            }
                            onPressed: wifiWidget.isPressed = true
                            onReleased: wifiWidget.isPressed = false
                            onCanceled: wifiWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: btWidget
                        xPos: 0
                        yPos: 1
                        width: root.btOpened ? root.gridImplicitWidth : root.box
                        height: root.btOpened ? _btPanel.implicitHeight : root.box
                        radius: root.btOpened ? 12 : 40
                        property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        enabled: btOn
                        hideCause: root.wifiOpened
                        scaleCause: root.btOpened
                        overwriteX: root.btOpened
                        overwriteY: root.btOpened
                        overwriteXPos: 0
                        overwriteYPos: 0
                        
                        z: root.btOpened ? 100 : 0
                        forceTransparentRim: root.btOpened

                        CFClippingRect {
                            anchors.fill: parent
                            radius: 12
                            visible: root.btOpened
                            opacity: root.btOpened ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: root.animationDur/2 } }
                            
                            BoxGlass {
                                anchors.fill: parent
                                radius: 12
                                color: root.glassColor
                                light: root.glassRimColor
                                rimStrength: 1.3
                                
                                MouseArea {
                                    anchors.fill: parent
                                    preventStealing: true
                                    propagateComposedEvents: false
                                    onPressed: function(e) { e.accepted = true }
                                    onClicked: function(e) { e.accepted = true }
                                }

                                CCBluetoothPanel {
                                    id: _btPanel
                                    width: root.gridImplicitWidth
                                    onCloseRequested: root.btOpened = false
                                }
                            }
                        }

                        CFClippingRect {
                            anchors.centerIn: parent
                            width: 34; height: 34; radius: 17
                            visible: !root.btOpened
                            color: btWidget.enabled ? "#fff" : Qt.rgba(1,1,1,0.18)
                            CFVI {
                                anchors.centerIn: parent
                                width: 25; height: 25
                                icon: "bluetooth/bluetooth.svg"
                                color: btWidget.enabled ? "#1C7AFF" : "#fff"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.btOpened
                            pressAndHoldInterval: 300
                            onClicked: {
                                if (Bluetooth.defaultAdapter) {
                                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                }
                            }
                            onPressAndHold: {
                                root.btOpened = true
                                root.wifiOpened = false
                            }
                            onPressed: btWidget.isPressed = true
                            onReleased: btWidget.isPressed = false
                            onCanceled: btWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: adWidget
                        xPos: 1
                        yPos: 1
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.btOpened
                        enabled: true
                        CFVI {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            icon: "devices/smartphone.svg"
                            color: "#1C7AFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _kdeConnect.running = true
                            }
                            onPressed: adWidget.isPressed = true
                            onReleased: adWidget.isPressed = false
                            onCanceled: adWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: musicWidget
                        xPos: 2
                        yPos: 0
                        width: root.box*2+root.boxMargin
                        height: root.box*2+root.boxMargin
                        radius: 25
                        hideCause: root.wifiOpened || root.btOpened
                        Rectangle {
                            id: artRect
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 12
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
                            }
                            CFText {
                                anchors.centerIn: parent
                                text: "♪"
                                font.pixelSize: 22
                                gray: true
                                visible: root.musicArt === ""
                            }
                        }
                        CFText {
                            id: titleTxt
                            anchors.top: artRect.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 8
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            text: root.musicTitle
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        CFText {
                            anchors.top: titleTxt.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 2
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            text: root.musicArtist
                            font.pixelSize: 10
                            gray: true
                            elide: Text.ElideRight
                        }
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: Qt.rgba(1,1,1,0.14)
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 14
                                    icon: "music/backward.svg"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        _pPrev.running = true
                                    }
                                }
                            }
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: Qt.rgba(1,1,1,0.14)
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    icon: root.musicPlaying ? "music/pause.svg" : "music/play.svg"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        _pPlay.running = true
                                    }
                                }
                            }
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: Qt.rgba(1,1,1,0.14)
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 14
                                    icon: "music/forward.svg"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        _pNext.running = true
                                    }
                                }
                            }
                        }
                    }

                    
                    BoxButton {
                        id: focusWidget
                        xPos: 0
                        yPos: 2
                        width: root.box*2+root.boxMargin
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.btOpened
                        enabled: root.focusOn
                        CFClippingRect {
                            id: focusCircle
                            anchors.left: parent.left
                            anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34; height: 34; radius: 17
                            color: root.focusOn ? "#fff" : Qt.rgba(1,1,1,0.18)
                            CFVI {
                                anchors.centerIn: parent
                                icon: "dnd.svg"
                                size: 20
                                color: root.focusOn ? "#8E44AD" : "#fff"
                            }
                        }
                        CFText {
                            anchors.left: focusCircle.right
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Focus"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusOn = !root.focusOn
                                if (root.focusOn) {
                                    _dndOn.running = true
                                } else {
                                    _dndOff.running = true
                                }
                            }
                            onPressed: focusWidget.isPressed = true
                            onReleased: focusWidget.isPressed = false
                            onCanceled: focusWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: stageWidget
                        xPos: 2
                        yPos: 2
                        width: root.box
                        height: root.box
                        radius: 22
                        hideCause: root.wifiOpened || root.btOpened
                        CFVI {
                            anchors.centerIn: parent
                            width: 24
                            height: 20
                            icon: "stageman.svg"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: stageWidget.isPressed = true
                            onReleased: stageWidget.isPressed = false
                            onCanceled: stageWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: shareWidget
                        xPos: 3
                        yPos: 2
                        width: root.box
                        height: root.box
                        radius: 22
                        hideCause: root.wifiOpened || root.btOpened
                        enabled: root.recording
                        CFVI {
                            anchors.centerIn: parent
                            width: 26
                            height: 20
                            icon: "screenshare.svg"
                            color: root.recording ? "#1C7AFF" : "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.recording = !root.recording
                                if (root.recording) {
                                    _shOn.running = true
                                } else {
                                    _shOff.running = true
                                }
                            }
                            onPressed: shareWidget.isPressed = true
                            onReleased: shareWidget.isPressed = false
                            onCanceled: shareWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: displayWidget
                        xPos: 0
                        yPos: 3
                        width: root.box*4+root.boxMargin*3
                        height: root.box
                        radius: 25
                        hideCause: root.wifiOpened || root.btOpened
                        
                        CFSlider {
                            anchors.fill: parent
                            anchors.leftMargin: 40
                            anchors.rightMargin: 40
                            value: appRoot.brtValue
                            onMoved: {
                                appRoot.brtValue = value
                                _brtT.restart()
                            }
                        }
                        CFVI {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "sun-small.svg"
                            size: 14
                        }
                        CFVI {
                            anchors.right: parent.right
                            anchors.rightMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "sun-huge.svg"
                            size: 18
                        }
                    }

                    
                    BoxButton {
                        id: volumeWidget
                        xPos: 0
                        yPos: 4
                        width: root.box*4+root.boxMargin*3
                        height: root.box
                        radius: 25
                        hideCause: root.wifiOpened || root.btOpened
                        
                        CFSlider {
                            anchors.fill: parent
                            anchors.leftMargin: 40
                            anchors.rightMargin: 40
                            value: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
                            onMoved: {
                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                    Pipewire.defaultAudioSink.audio.volume = value
                                }
                            }
                        }
                        CFVI {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "volume/audio-volume-1.svg"
                            size: 14
                        }
                        CFVI {
                            anchors.right: parent.right
                            anchors.rightMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "volume/audio-volume-3.svg"
                            size: 18
                        }
                    }

                    
                    
                    BoxButton {
                        id: darkWidget
                        xPos: 0
                        yPos: 5
                        width: root.box*2+root.boxMargin
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.btOpened
                        enabled: root.darkOn
                        CFClippingRect {
                            id: darkCircle
                            anchors.left: parent.left
                            anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34; height: 34; radius: 17
                            color: root.darkOn ? "#fff" : Qt.rgba(1,1,1,0.18)
                            CFVI {
                                anchors.centerIn: parent
                                icon: root.darkOn ? "notch/moon.svg" : "weather/sun.svg"
                                size: 20
                                color: root.darkOn ? "#F1C40F" : "#fff"
                            }
                        }
                        CFText {
                            anchors.left: darkCircle.right
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Dark Mode"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.darkOn = !root.darkOn
                                _darkToggleCmd.running = true
                            }
                            onPressed: darkWidget.isPressed = true
                            onReleased: darkWidget.isPressed = false
                            onCanceled: darkWidget.isPressed = false
                        }
                    }
                    
                    
                    BoxButton {
                        id: calcWidget
                        xPos: 2
                        yPos: 5
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.btOpened
                        CFVI {
                            anchors.centerIn: parent
                            size: 30
                            icon: "spotlight/actions.svg"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _calcCmd.running = true
                            }
                            onPressed: if (!root.subOpened) calcWidget.isPressed = true
                            onReleased: calcWidget.isPressed = false
                            onCanceled: calcWidget.isPressed = false
                        }
                    }

                    
                    BoxButton {
                        id: clockWidget
                        xPos: 3
                        yPos: 5
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.btOpened
                        CFVI {
                            anchors.centerIn: parent
                            size: 26
                            icon: "dropdown/clock.svg"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _timerCmd.running = true
                            }
                            onPressed: if (!root.subOpened) clockWidget.isPressed = true
                            onReleased: clockWidget.isPressed = false
                            onCanceled: clockWidget.isPressed = false
                        }
                    }
                } 
            } 
        }
    }
}
