import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import qs.ui.topbar.statusarea.controlcenter.panels
import qs.ui.topbar.statusarea.notifcenter
import qs.services
import qs.components
import qs.components.glass

Scope {
    id: root

    property bool opened: false
    signal closing()
    property bool wifiOpened: false
    property bool btOpened:   false
    property bool timerOpened: false
    property bool alarmOpened: false
    property bool stopwatchOpened: false
    property bool subOpened:  wifiOpened || btOpened || timerOpened || alarmOpened || stopwatchOpened
    property bool playerExpanded: false

    // Ces flags pilotent les animations (taille/position/contenu étendu).
    // Ils ne passent à true qu'après le délai du Timer correspondant, donc
    // plus aucune dépendance à un timing d'animation imbriqué.
    property bool wifiGrowReady:   false
    property bool btGrowReady:     false
    property bool playerGrowReady: false
    property bool timerGrowReady:  false
    property bool alarmGrowReady:  false
    property bool stopwatchGrowReady: false
    property bool wifiClosing:   false
    property bool btClosing:     false
    property bool playerClosing: false
    property bool timerClosing:  false
    property bool alarmClosing:  false
    property bool stopwatchClosing: false

    Timer { id: _wifiGrowTimer;  interval: root.animationDur*0.65; onTriggered: root.wifiGrowReady = true }
    Timer { id: _wifiCloseTimer; interval: root.animationDur*1.3;  onTriggered: root.wifiClosing = false }
    Timer { id: _btGrowTimer;    interval: root.animationDur*0.65; onTriggered: root.btGrowReady = true }
    Timer { id: _btCloseTimer;   interval: root.animationDur*1.3;  onTriggered: root.btClosing = false }
    Timer { id: _playerGrowTimer;  interval: root.animationDur*0.65; onTriggered: root.playerGrowReady = true }
    Timer { id: _playerCloseTimer; interval: root.animationDur*1.3;  onTriggered: root.playerClosing = false }
    Timer { id: _timerGrowTimer;   interval: root.animationDur*0.65; onTriggered: root.timerGrowReady = true }
    Timer { id: _timerCloseTimer;  interval: root.animationDur*1.3;  onTriggered: root.timerClosing = false }
    Timer { id: _alarmGrowTimer;   interval: root.animationDur*0.65; onTriggered: root.alarmGrowReady = true }
    Timer { id: _alarmCloseTimer;  interval: root.animationDur*1.3;  onTriggered: root.alarmClosing = false }
    Timer { id: _stopwatchGrowTimer;  interval: root.animationDur*0.65; onTriggered: root.stopwatchGrowReady = true }
    Timer { id: _stopwatchCloseTimer; interval: root.animationDur*1.3;  onTriggered: root.stopwatchClosing = false }

    onWifiOpenedChanged: {
        if (wifiOpened) {
            wifiGrowReady = false
            _wifiCloseTimer.stop()
            _wifiGrowTimer.restart()
        } else {
            wifiGrowReady = false
            wifiClosing = true
            _wifiGrowTimer.stop()
            _wifiCloseTimer.restart()
        }
    }
    onBtOpenedChanged: {
        if (btOpened) {
            btGrowReady = false
            _btCloseTimer.stop()
            _btGrowTimer.restart()
        } else {
            btGrowReady = false
            btClosing = true
            _btGrowTimer.stop()
            _btCloseTimer.restart()
        }
    }
    onPlayerExpandedChanged: {
        if (playerExpanded) {
            playerGrowReady = false
            _playerCloseTimer.stop()
            _playerGrowTimer.restart()
        } else {
            playerGrowReady = false
            playerClosing = true
            _playerGrowTimer.stop()
            _playerCloseTimer.restart()
        }
    }
    onTimerOpenedChanged: {
        if (timerOpened) {
            timerGrowReady = false
            _timerCloseTimer.stop()
            _timerGrowTimer.restart()
        } else {
            timerGrowReady = false
            timerClosing = true
            _timerGrowTimer.stop()
            _timerCloseTimer.restart()
        }
    }
    onAlarmOpenedChanged: {
        if (alarmOpened) {
            alarmGrowReady = false
            _alarmCloseTimer.stop()
            _alarmGrowTimer.restart()
        } else {
            alarmGrowReady = false
            alarmClosing = true
            _alarmGrowTimer.stop()
            _alarmCloseTimer.restart()
        }
    }
    onStopwatchOpenedChanged: {
        if (stopwatchOpened) {
            stopwatchGrowReady = false
            _stopwatchCloseTimer.stop()
            _stopwatchGrowTimer.restart()
        } else {
            stopwatchGrowReady = false
            stopwatchClosing = true
            _stopwatchGrowTimer.stop()
            _stopwatchCloseTimer.restart()
        }
    }

    readonly property int box:        65
    readonly property int boxMargin:  10
    readonly property int gridW:      4
    readonly property int gridH:      8
    readonly property int animationDur: 300

    readonly property int gridImplicitWidth:  ((box*gridW)+(boxMargin*gridW)+boxMargin)
    readonly property int gridImplicitHeight: ((box*gridH)+(boxMargin*gridH)+boxMargin)

    readonly property var _fixedWidgetBottomRows: [
        { id: "wifiWidget",     row: 0 },
        { id: "btWidget",       row: 1 },
        { id: "adWidget",       row: 1 },
        { id: "musicWidget",    row: 1 },
        { id: "focusWidget",    row: 2 },
        { id: "stageWidget",    row: 2 },
        { id: "shareWidget",    row: 2 },
        { id: "displayWidget",  row: 3 },
        { id: "volumeWidget",   row: 4 }
    ]

    readonly property var _packableWidgets: [
        { id: "darkWidget",      wUnits: 2, hUnits: 1 },
        { id: "calcWidget",      wUnits: 1, hUnits: 1 },
        { id: "gameModeWidget",  wUnits: 1, hUnits: 1 },
        { id: "timerWidget",     wUnits: 1, hUnits: 1 },
        { id: "alarmWidget",     wUnits: 1, hUnits: 1 },
        { id: "stopwatchWidget", wUnits: 1, hUnits: 1 }
    ]

    readonly property int _packStartRow: 5

    readonly property var _packedLayout: {
        var layout = {}
        var cursorX = 0
        var cursorY = root._packStartRow
        for (var i = 0; i < root._packableWidgets.length; i++) {
            var w = root._packableWidgets[i]
            if (!ShellConfig.ccWidgetVisible(w.id)) continue
            if (cursorX + w.wUnits > root.gridW) {
                cursorX = 0
                cursorY++
            }
            layout[w.id] = { xPos: cursorX, yPos: cursorY, wUnits: w.wUnits, hUnits: w.hUnits }
            cursorX += w.wUnits
        }
        return layout
    }

    function packedX(id) {
        return root._packedLayout[id] ? root._packedLayout[id].xPos : 0
    }
    function packedY(id) {
        return root._packedLayout[id] ? root._packedLayout[id].yPos : root._packStartRow
    }

    readonly property int _lastVisibleRow: {
        var maxRow = 0
        for (var i = 0; i < root._fixedWidgetBottomRows.length; i++) {
            var w = root._fixedWidgetBottomRows[i]
            if (ShellConfig.ccWidgetVisible(w.id) && w.row > maxRow) maxRow = w.row
        }
        var packedKeys = Object.keys(root._packedLayout)
        for (var j = 0; j < packedKeys.length; j++) {
            var p = root._packedLayout[packedKeys[j]]
            if (p.yPos > maxRow) maxRow = p.yPos
        }
        return maxRow
    }

    readonly property int _visibleGridHeight: (box*(_lastVisibleRow+1)) + (boxMargin*(_lastVisibleRow+1)) + boxMargin

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
                        root.playerExpanded = false
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
    property real   musicPosition: 0
    property real   musicLength:   0

    function formatTime(s) {
        var t = Math.max(0, Math.floor(s))
        var m = Math.floor(t/60)
        var sec = t%60
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

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

    Process {
        id: _pPosition
        command: ["sh", "-c", "playerctl position 2>/dev/null || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.musicPosition = parseFloat(text.trim()) || 0 }
    }
    Process {
        id: _pLength
        command: ["sh", "-c", "playerctl metadata mpris:length 2>/dev/null || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.musicLength = (parseFloat(text.trim()) || 0) / 1000000 }
    }
    Process { id: _pSeek; command: [] }

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

    Timer {
        interval: 1000
        running: root.playerExpanded
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _pPosition.running = true
            _pLength.running   = true
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    property string brtPath: ""
    property string brtMaxPath: ""
    property real   brtValue: 0.5

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
                        if (Math.abs(root.brtValue - val) > 0.01) {
                            root.brtValue = val
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
            _brtSet.command = ["brightnessctl", "set", Math.round(root.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }

    property bool focusOn: false
    property bool darkOn:  false
    property bool recording: false

    Process { id: _darkToggleCmd; command: ["sh", "-c", "~/.config/hypr/scripts/toggle-theme.sh"] }
    Process {
        id: _calcCmd
        command: ["foot", "--title=calculator", "-e", "qalc", "-i"]
        stderr: SplitParser {
            onRead: line => console.warn("Calculator launch error: " + line)
        }
    }
    Process { id: _shOn;       command: ["sh", "-c", "exec wf-recorder -f ~/Videos/screencast_$(date +%s).mp4"] }
    Process {
        id: _screenshotCmd
        command: ["sh", "-c", "mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/$(date +%F_%T).png | wl-copy"]
        stderr: SplitParser {
            onRead: line => console.warn("Screenshot error: " + line)
        }
    }


    property bool _ccLoaderActive: false
    onOpenedChanged: {
        if (opened) {
            _ccCloseTimer.stop()
            _ccLoaderActive = true
        } else {
            _ccCloseTimer.restart()
        }
    }
    Timer {
        id: _ccCloseTimer
        interval: root.animationDur
        onTriggered: root._ccLoaderActive = false
    }

    Loader {
        active: root._ccLoaderActive
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
                        if (root.wifiOpened || root.btOpened || root.playerExpanded) {
                            root.wifiOpened = false
                            root.btOpened   = false
                            root.playerExpanded = false
                        } else {
                            root.closing()
                        }
                    }
                }

                Item {
                    id: ccContent
                    width:  root.gridImplicitWidth
                    height: root._visibleGridHeight
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 30 - (1 - showProgress) * 24
                    anchors.rightMargin: 10
                    transformOrigin: Item.TopRight
                    scale: 1.0
                    opacity: showProgress

                    property real showProgress: 0
                    Behavior on showProgress {
                        NumberAnimation {
                            duration: root.animationDur
                            easing.type: Easing.OutCubic
                        }
                    }
                    Component.onCompleted: showProgress = 1
                    Connections {
                        target: root
                        function onOpenedChanged() {
                            if (!root.opened) ccContent.showProgress = 0
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: root.animationDur
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !(root.wifiOpened || root.btOpened || root.playerExpanded)
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
                        property bool growing: false
                        property string widgetId: ""
                        readonly property bool hiddenByUser: boxbutton.widgetId !== "" && !ShellConfig.ccWidgetVisible(boxbutton.widgetId)

                        opacity: (boxbutton.hideCause || boxbutton.hiddenByUser) ? 0 : 1
                        visible: opacity > 0
                        scale: boxbutton.scaleCause ? 1.25 : (boxbutton.isPressed ? 0.93 : 1.0)

                        transformOrigin: Item.Top

                        property int xPos: 0
                        property int yPos: 0
                        property bool overwriteX: false
                        property bool overwriteY: false
                        property int overwriteXPos: 0
                        property bool overwriteXFromRight: false
                        property int overwriteRightPos: 0
                        property int overwriteYPos: 0

                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: boxbutton.overwriteXFromRight
                                            ? (boxbutton.overwriteRightPos - boxbutton.width)
                                            : (boxbutton.overwriteX ? boxbutton.overwriteXPos : ccContent.gridX(boxbutton.xPos))
                            topMargin: boxbutton.overwriteY ? boxbutton.overwriteYPos : ccContent.gridY(boxbutton.yPos)
                        }

                        // Ancrage dérivé de la largeur (pas d'anim propre nécessaire : elle suit
                        // déjà width image par image, donc désactivée pour éviter un décalage).
                        // Explicitement désactivé pour les boutons qui ne bougent jamais (pas de
                        // overwriteX/Y) afin d'exclure toute possibilité de mouvement résiduel.
                        // Le délai avant croissance est géré en amont par un Timer qui ne fait
                        // passer la valeur cible à sa taille finale qu'après le fondu des voisins
                        // -> ici on anime simplement, sans pause imbriquée.
                        Behavior on anchors.leftMargin {
                            enabled: !boxbutton.overwriteXFromRight
                            NumberAnimation { duration: root.animationDur*1.3; easing.type: Easing.OutCubic }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: root.animationDur*1.3; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: root.animationDur*0.35; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: root.animationDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.5
                            }
                        }
                        Behavior on width {
                            NumberAnimation { duration: root.animationDur*1.3; easing.type: Easing.OutCubic }
                        }
                        Behavior on height {
                            NumberAnimation { duration: root.animationDur*1.3; easing.type: Easing.OutCubic }
                        }
                        Behavior on radius {
                            NumberAnimation { duration: root.animationDur*1.3; easing.type: Easing.OutCubic }
                        }

                        light: boxbutton.forceTransparentRim ? "transparent" : root.glassRimColor
                        rimStrength: boxbutton.forceTransparentRim ? 0 : root.glassRimStrength
                        color: boxbutton.forceTransparentRim ? "transparent" : root.glassColor
                    }

                    component CFFlatSlider: Item {
                        id: flatSlider
                        height: 16
                        property real value: 0
                        property real trackHeight: 4
                        property color fillColor: "#fff"
                        property color trackColor: Qt.rgba(1,1,1,0.25)
                        signal moved(real value)

                        property bool _active: _fsArea.pressed

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: flatSlider.trackHeight
                            radius: height/2
                            color: flatSlider.trackColor
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(flatSlider.trackHeight, flatSlider.value * parent.width)
                            height: flatSlider.trackHeight
                            radius: height/2
                            color: flatSlider.fillColor
                        }
                        Rectangle {
                            id: _fsThumb
                            width: 12
                            height: 12
                            radius: 6
                            color: "#fff"
                            visible: flatSlider._active
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.min(Math.max(flatSlider.value * parent.width - width/2, 0), parent.width - width)
                        }
                        MouseArea {
                            id: _fsArea
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            onPressed: function(e) {
                                var v = Math.min(Math.max(e.x / width, 0), 1)
                                flatSlider.value = v
                                flatSlider.moved(v)
                            }
                            onPositionChanged: function(e) {
                                if (pressed) {
                                    var v = Math.min(Math.max(e.x / width, 0), 1)
                                    flatSlider.value = v
                                    flatSlider.moved(v)
                                }
                            }
                        }
                    }


                    BoxButton {
                        id: wifiWidget
                        widgetId: "wifiWidget"
                        xPos: 0
                        yPos: 0
                        width: root.wifiGrowReady ? root.gridImplicitWidth : root.box*2+root.boxMargin
                        height: root.wifiGrowReady ? _wPanel.implicitHeight : root.box
                        radius: root.wifiGrowReady ? 12 : 40
                        enabled: root.wifiOn
                        hideCause: root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        overwriteX: root.wifiGrowReady
                        overwriteY: root.wifiGrowReady
                        overwriteXPos: 0
                        overwriteYPos: root.boxMargin

                        z: (root.wifiOpened || root.wifiClosing) ? 100 : 0
                        forceTransparentRim: root.wifiOpened

                            CFClippingRect {
                                anchors.fill: parent
                                radius: 12
                                visible: opacity > 0
                                opacity: root.wifiGrowReady ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: root.animationDur*0.8; easing.type: Easing.OutCubic }
                                }

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
                                width: root.box*2+root.boxMargin
                                height: root.box
                                anchors.left: parent.left
                                anchors.top: parent.top
                                visible: opacity > 0
                                opacity: (!root.wifiOpened && !root.wifiClosing) ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: root.animationDur*0.5; easing.type: Easing.OutCubic }
                                }
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
                                    root.playerExpanded = false
                                }
                                onPressed: wifiWidget.isPressed = true
                                onReleased: wifiWidget.isPressed = false
                                onCanceled: wifiWidget.isPressed = false
                            }
                    }


                    BoxButton {
                        id: btWidget
                        widgetId: "btWidget"
                        xPos: 0
                        yPos: 1
                        width: root.btGrowReady ? root.gridImplicitWidth : root.box
                        height: root.btGrowReady ? _btPanel.implicitHeight : root.box
                        radius: root.btGrowReady ? 12 : 40
                        property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        enabled: btOn
                        hideCause: root.wifiOpened || root.wifiClosing || root.playerExpanded || root.playerClosing
                        overwriteX: root.btGrowReady
                        overwriteY: root.btGrowReady
                        overwriteXPos: 0
                        overwriteYPos: root.boxMargin

                        z: (root.btOpened || root.btClosing) ? 100 : 0
                        forceTransparentRim: root.btOpened
                        light: btWidget.forceTransparentRim ? "transparent" : (btWidget.enabled ? "transparent" : root.glassRimColor)
                        rimStrength: btWidget.forceTransparentRim ? 0 : (btWidget.enabled ? 0 : root.glassRimStrength)
                        color: btWidget.forceTransparentRim ? "transparent" : (btWidget.enabled ? "#fff" : root.glassColor)
                        Behavior on color { ColorAnimation { duration: root.animationDur*0.5 } }
                        Behavior on light { ColorAnimation { duration: root.animationDur*0.5 } }
                        Behavior on rimStrength { NumberAnimation { duration: root.animationDur*0.5 } }

                            CFClippingRect {
                                anchors.fill: parent
                                radius: 12
                                visible: opacity > 0
                                opacity: root.btGrowReady ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: root.animationDur*0.8; easing.type: Easing.OutCubic }
                                }

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

                            Item {
                                width: root.box
                                height: root.box
                                anchors.left: parent.left
                                anchors.top: parent.top
                                visible: opacity > 0
                                opacity: (!root.btOpened && !root.btClosing) ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: root.animationDur*0.5; easing.type: Easing.OutCubic }
                                }
                            CFClippingRect {
                                anchors.centerIn: parent
                                width: 38; height: 38; radius: 19
                                color: btWidget.enabled ? "#fff" : Qt.rgba(1,1,1,0.18)
                                Behavior on color { ColorAnimation { duration: root.animationDur*0.5 } }
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 30; height: 30
                                    icon: "bluetooth/bluetooth.svg"
                                    color: btWidget.enabled ? "#1C7AFF" : "#fff"
                                    Behavior on color { ColorAnimation { duration: root.animationDur*0.5 } }
                                }
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
                                    root.playerExpanded = false
                                }
                                onPressed: btWidget.isPressed = true
                                onReleased: btWidget.isPressed = false
                                onCanceled: btWidget.isPressed = false
                            }
                    }


                    BoxButton {
                        id: adWidget
                        widgetId: "adWidget"
                        xPos: 1
                        yPos: 1
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
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
                        widgetId: "musicWidget"
                        xPos: 2
                        yPos: 0
                        width: root.playerGrowReady ? root.gridImplicitWidth : root.box*2+root.boxMargin
                        height: root.playerGrowReady ? expCol.implicitHeight + 32 : root.box*2+root.boxMargin
                        radius: root.playerGrowReady ? 24 : 25
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing
                        overwriteY: root.playerGrowReady
                        overwriteXFromRight: root.playerExpanded || root.playerClosing
                        overwriteRightPos: ccContent.gridX(2) + (root.box*2+root.boxMargin)
                        overwriteYPos: root.boxMargin
                        z: (root.playerExpanded || root.playerClosing) ? 100 : 0
                        forceTransparentRim: false

                        Item {
                            width: root.box*2+root.boxMargin
                            height: root.box*2+root.boxMargin
                            anchors.left: parent.left
                            anchors.top: parent.top
                            visible: opacity > 0
                            opacity: (!root.playerExpanded && !root.playerClosing) ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: root.animationDur*0.5; easing.type: Easing.OutCubic }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.playerExpanded = true
                                    _pPosition.running = true
                                    _pLength.running   = true
                                }
                            }

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
                                anchors.bottomMargin: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 22
                                CFVI {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 13
                                    icon: "music/backward.svg"
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        onClicked: {
                                            _pPrev.running = true
                                        }
                                    }
                                }
                                CFVI {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    height: 18
                                    icon: root.musicPlaying ? "music/pause.svg" : "music/play.svg"
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        onClicked: {
                                            _pPlay.running = true
                                        }
                                    }
                                }
                                CFVI {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 13
                                    icon: "music/forward.svg"
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        onClicked: {
                                            _pNext.running = true
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: opacity > 0
                            opacity: root.playerGrowReady ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: root.animationDur*0.8; easing.type: Easing.OutCubic }
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                propagateComposedEvents: false
                                onPressed: function(e) { e.accepted = true }
                                onClicked: function(e) {
                                    e.accepted = true
                                    root.playerExpanded = false
                                }
                            }

                            Column {
                                id: expCol
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 16
                                spacing: 14

                                CFClippingRect {
                                    id: expArt
                                    width: parent.width
                                    height: width
                                    radius: 20
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
                                        font.pixelSize: 44
                                        gray: true
                                        visible: root.musicArt === ""
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 2
                                    CFText {
                                        width: parent.width
                                        text: root.musicTitle
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                    CFText {
                                        width: parent.width
                                        text: root.musicArtist
                                        font.pixelSize: 12
                                        gray: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    CFFlatSlider {
                                        id: expSlider
                                        width: parent.width
                                        value: root.musicLength > 0 ? root.musicPosition / root.musicLength : 0
                                        onMoved: function(value) {
                                            if (root.musicLength > 0) {
                                                var secs = value * root.musicLength
                                                root.musicPosition = secs
                                                _pSeek.command = ["sh", "-c", "playerctl position " + secs.toFixed(1)]
                                                _pSeek.running = true
                                            }
                                        }
                                    }

                                    Item {
                                        width: parent.width
                                        height: 14
                                        CFText {
                                            anchors.left: parent.left
                                            text: root.formatTime(root.musicPosition)
                                            font.pixelSize: 10
                                            gray: true
                                        }
                                        CFText {
                                            anchors.right: parent.right
                                            text: root.formatTime(root.musicLength)
                                            font.pixelSize: 10
                                            gray: true
                                        }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 44

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 42
                                        CFVI {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 30
                                            height: 26
                                            icon: "music/backward.svg"
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -10
                                                onClicked: {
                                                    _pPrev.running = true
                                                }
                                            }
                                        }
                                        CFVI {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 40
                                            height: 40
                                            icon: root.musicPlaying ? "music/pause.svg" : "music/play.svg"
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -10
                                                onClicked: {
                                                    _pPlay.running = true
                                                }
                                            }
                                        }
                                        CFVI {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 30
                                            height: 26
                                            icon: "music/forward.svg"
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -10
                                                onClicked: {
                                                    _pNext.running = true
                                                }
                                            }
                                        }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 24

                                    CFVI {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: "volume/audio-volume-1.svg"
                                        size: 12
                                    }
                                    CFFlatSlider {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 22
                                        anchors.rightMargin: 22
                                        value: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
                                        onMoved: function(value) {
                                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                                Pipewire.defaultAudioSink.audio.volume = value
                                            }
                                        }
                                    }
                                    CFVI {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: "volume/audio-volume-3.svg"
                                        size: 16
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: outputPill.height

                                    Rectangle {
                                        id: outputPill
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: pillRow.implicitWidth + 28
                                        height: 30
                                        radius: 15
                                        color: Qt.rgba(1,1,1,0.10)

                                        Row {
                                            id: pillRow
                                            anchors.centerIn: parent
                                            spacing: 6
                                            CFVI {
                                                anchors.verticalCenter: parent.verticalCenter
                                                icon: "bluetooth/bluetooth.svg"
                                                size: 12
                                            }
                                            CFText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.description) ? Pipewire.defaultAudioSink.description : "Sortie audio"
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                root.playerExpanded = false
                                                root.btOpened = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }


                    BoxButton {
                        id: focusWidget
                        widgetId: "focusWidget"
                        xPos: 0
                        yPos: 2
                        width: root.box*2+root.boxMargin
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        enabled: root.focusOn
                        light: focusWidget.enabled ? "transparent" : root.glassRimColor
                        rimStrength: focusWidget.enabled ? 0 : root.glassRimStrength
                        color: focusWidget.enabled ? "#fff" : root.glassColor
                        CFClippingRect {
                            id: focusCircle
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 38; radius: 19
                            color: "transparent"
                            CFVI {
                                anchors.centerIn: parent
                                icon: "dnd.svg"
                                size: 26
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
                            color: root.focusOn ? "#000" : "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusOn = !root.focusOn
                                NotifService.dndEnabled = root.focusOn
                            }
                            onPressed: focusWidget.isPressed = true
                            onReleased: focusWidget.isPressed = false
                            onCanceled: focusWidget.isPressed = false
                        }
                    }


                    BoxButton {
                        id: stageWidget
                        widgetId: "stageWidget"
                        xPos: 2
                        yPos: 2
                        width: root.box
                        height: root.box
                        radius: 22
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        CFVI {
                            anchors.centerIn: parent
                            width: 24
                            height: 20
                            icon: "screenshot/region.svg"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _screenshotCmd.running = true
                            }
                            onPressed: stageWidget.isPressed = true
                            onReleased: stageWidget.isPressed = false
                            onCanceled: stageWidget.isPressed = false
                        }
                    }


                    BoxButton {
                        id: shareWidget
                        widgetId: "shareWidget"
                        xPos: 3
                        yPos: 2
                        width: root.box
                        height: root.box
                        radius: 22
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
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
                                    _shOn.signal(2) // SIGINT, laisse wf-recorder finaliser le mp4 proprement
                                }
                            }
                            onPressed: shareWidget.isPressed = true
                            onReleased: shareWidget.isPressed = false
                            onCanceled: shareWidget.isPressed = false
                        }
                    }


                    BoxButton {
                        id: displayWidget
                        widgetId: "displayWidget"
                        xPos: 0
                        yPos: 3
                        width: root.box*4+root.boxMargin*3
                        height: root.box
                        radius: 25
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing

                        CFSlider {
                            anchors.fill: parent
                            anchors.leftMargin: 40
                            anchors.rightMargin: 40
                            value: root.brtValue
                            onMoved: {
                                root.brtValue = value
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
                        widgetId: "volumeWidget"
                        xPos: 0
                        yPos: 4
                        width: root.box*4+root.boxMargin*3
                        height: root.box
                        radius: 25
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing

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
                        widgetId: "darkWidget"
                        xPos: root.packedX("darkWidget")
                        yPos: root.packedY("darkWidget")
                        width: root.box*2+root.boxMargin
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        enabled: root.darkOn
                        light: darkWidget.enabled ? "transparent" : root.glassRimColor
                        rimStrength: darkWidget.enabled ? 0 : root.glassRimStrength
                        color: darkWidget.enabled ? "#fff" : root.glassColor
                        CFClippingRect {
                            id: darkCircle
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 38; radius: 19
                            color: "transparent"
                            CFVI {
                                anchors.centerIn: parent
                                icon: root.darkOn ? "notch/moon.svg" : "weather/sun.svg"
                                size: 26
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
                            color: root.darkOn ? "#000" : "#fff"
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
                        widgetId: "calcWidget"
                        xPos: root.packedX("calcWidget")
                        yPos: root.packedY("calcWidget")
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        Item {
                            anchors.centerIn: parent
                            width: 22
                            height: 26
                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: "transparent"
                                border.color: "#fff"
                                border.width: 2
                            }
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 4
                                height: 6
                                radius: 1.5
                                color: "#fff"
                            }
                            Grid {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                anchors.bottomMargin: 4
                                columns: 3
                                rowSpacing: 2
                                columnSpacing: 2
                                Repeater {
                                    model: 6
                                    Rectangle {
                                        width: 3
                                        height: 3
                                        radius: 1
                                        color: "#fff"
                                    }
                                }
                            }
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
                        id: gameModeWidget
                        widgetId: "gameModeWidget"
                        xPos: root.packedX("gameModeWidget")
                        yPos: root.packedY("gameModeWidget")
                        width: root.box
                        height: root.box
                        radius: 40
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                        enabled: GameMode.enabled
                        light: gameModeWidget.enabled ? "transparent" : root.glassRimColor
                        rimStrength: gameModeWidget.enabled ? 0 : root.glassRimStrength
                        color: gameModeWidget.enabled ? "#fff" : root.glassColor
                        Item {
                            anchors.centerIn: parent
                            width: 30
                            height: 20
                            Rectangle {
                                anchors.fill: parent
                                radius: height/2
                                color: "transparent"
                                border.color: GameMode.enabled ? "#1C7AFF" : "#fff"
                                border.width: 2
                            }
                            Rectangle {
                                width: 8
                                height: 2
                                radius: 1
                                color: GameMode.enabled ? "#1C7AFF" : "#fff"
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                width: 2
                                height: 8
                                radius: 1
                                color: GameMode.enabled ? "#1C7AFF" : "#fff"
                                anchors.left: parent.left
                                anchors.leftMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: GameMode.enabled ? "#1C7AFF" : "#fff"
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                anchors.top: parent.top
                                anchors.topMargin: 5
                            }
                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: GameMode.enabled ? "#1C7AFF" : "#fff"
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                GameMode.toggle()
                            }
                            onPressed: if (!root.subOpened) gameModeWidget.isPressed = true
                            onReleased: gameModeWidget.isPressed = false
                            onCanceled: gameModeWidget.isPressed = false
                        }
                    }

                    BoxButton {
                        id: timerWidget
                        widgetId: "timerWidget"
                        xPos: root.packedX("timerWidget")
                        yPos: root.packedY("timerWidget")
                        width: root.timerGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                        height: root.timerGrowReady ? (root.box*2+root.boxMargin) : root.box
                        radius: root.timerGrowReady ? 30 : 40
                        z: root.timerOpened || root.timerClosing ? 5 : 0
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.alarmOpened || root.alarmClosing || root.stopwatchOpened || root.stopwatchClosing
                        enabled: TimerState.running || TimerState.firing

                        CFVI {
                            visible: !root.timerOpened && !root.timerClosing
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            icon: "notch/clock.svg"
                            color: (TimerState.running || TimerState.firing) ? "#1C7AFF" : "#fff"
                        }
                        Rectangle {
                            visible: !root.timerOpened && !root.timerClosing && (TimerState.running || TimerState.firing)
                            width: 8
                            height: 8
                            radius: 4
                            color: TimerState.firing ? "#ff453a" : "#1C7AFF"
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 10
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 14
                            visible: root.timerGrowReady

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                CFText {
                                    text: "Minuteur"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#fff"
                                }

                                CFText {
                                    visible: TimerState.firing
                                    text: "Terminé"
                                    font.pixelSize: 30
                                    font.weight: Font.Bold
                                    color: "#ff453a"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                CFText {
                                    visible: !TimerState.firing && (TimerState.running || TimerState.remainingAtPauseMs > 0)
                                    text: TimerState.formatRemaining(TimerState.remainingMs)
                                    font.pixelSize: 30
                                    font.weight: Font.Bold
                                    color: "#fff"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    visible: !TimerState.firing && !TimerState.running && TimerState.remainingAtPauseMs <= 0
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Repeater {
                                        model: [1, 5, 10, 15, 30]

                                        Rectangle {
                                            id: _presetBtn
                                            required property int modelData
                                            width: 44
                                            height: 32
                                            radius: 8
                                            color: _presetMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                                            CFText {
                                                anchors.centerIn: parent
                                                text: _presetBtn.modelData + "m"
                                                font.pixelSize: 12
                                                color: "#fff"
                                            }
                                            MouseArea {
                                                id: _presetMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: TimerState.start(_presetBtn.modelData * 60 * 1000)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: TimerState.firing || TimerState.running || TimerState.remainingAtPauseMs > 0
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    Rectangle {
                                        visible: !TimerState.firing
                                        width: 90
                                        height: 32
                                        radius: 8
                                        color: _pauseMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                                        CFText {
                                            anchors.centerIn: parent
                                            text: TimerState.running ? "Pause" : "Reprendre"
                                            font.pixelSize: 12
                                            color: "#fff"
                                        }
                                        MouseArea {
                                            id: _pauseMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerState.running ? TimerState.pause() : TimerState.resume()
                                        }
                                    }

                                    Rectangle {
                                        width: 90
                                        height: 32
                                        radius: 8
                                        color: _cancelMouse.containsMouse ? "#40ff453a" : "#20ff453a"
                                        CFText {
                                            anchors.centerIn: parent
                                            text: TimerState.firing ? "OK" : "Annuler"
                                            font.pixelSize: 12
                                            color: "#ff453a"
                                        }
                                        MouseArea {
                                            id: _cancelMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TimerState.firing ? TimerState.dismissFiring() : TimerState.cancel()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.timerOpened && !root.timerClosing
                            onClicked: root.timerOpened = true
                            onPressed: timerWidget.isPressed = true
                            onReleased: timerWidget.isPressed = false
                            onCanceled: timerWidget.isPressed = false
                        }

                        Rectangle {
                            visible: root.timerGrowReady
                            width: 26
                            height: 26
                            radius: 13
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            color: _timerCloseMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                            CFVI {
                                anchors.centerIn: parent
                                width: 11
                                height: 11
                                icon: "notch/x.svg"
                            }
                            MouseArea {
                                id: _timerCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.timerOpened = false
                            }
                        }
                    }

                    BoxButton {
                        id: alarmWidget
                        widgetId: "alarmWidget"
                        xPos: root.packedX("alarmWidget")
                        yPos: root.packedY("alarmWidget")
                        width: root.alarmGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                        height: root.alarmGrowReady ? (root.box*2+root.boxMargin) : root.box
                        radius: root.alarmGrowReady ? 30 : 40
                        z: root.alarmOpened || root.alarmClosing ? 5 : 0
                        overwriteX: root.alarmGrowReady
                        overwriteXFromRight: root.alarmGrowReady
                        overwriteRightPos: root.gridImplicitWidth - root.boxMargin
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.timerOpened || root.timerClosing || root.stopwatchOpened || root.stopwatchClosing
                        enabled: AlarmState.alarms.filter(function(a) { return a.enabled }).length > 0

                        CFVI {
                            visible: !root.alarmOpened && !root.alarmClosing
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            icon: "notch/bell.svg"
                            color: alarmWidget.enabled ? "#1C7AFF" : "#fff"
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 14
                            visible: root.alarmGrowReady

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true

                                    CFText {
                                        text: "Alarmes"
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: "#fff"
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: _addAlarmMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                                        CFVI {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            icon: "notch/plus.svg"
                                        }
                                        MouseArea {
                                            id: _addAlarmMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var now = new Date()
                                                now.setMinutes(now.getMinutes() + 5)
                                                AlarmState.addAlarm(now.getHours(), now.getMinutes(), "", [])
                                            }
                                        }
                                    }
                                }

                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    ColumnLayout {
                                        width: parent.width
                                        spacing: 4

                                        Repeater {
                                            model: AlarmState.alarms

                                            RowLayout {
                                                id: _alarmRow
                                                required property var modelData
                                                Layout.fillWidth: true
                                                spacing: 8

                                                CFText {
                                                    text: (_alarmRow.modelData.hour < 10 ? "0" : "") + _alarmRow.modelData.hour + ":" + (_alarmRow.modelData.minute < 10 ? "0" : "") + _alarmRow.modelData.minute
                                                    font.pixelSize: 16
                                                    font.weight: Font.Bold
                                                    color: _alarmRow.modelData.enabled ? "#fff" : "#80ffffff"
                                                    Layout.fillWidth: true
                                                }

                                                Rectangle {
                                                    width: 40
                                                    height: 22
                                                    radius: 11
                                                    color: _alarmRow.modelData.enabled ? "#34c759" : "#40ffffff"
                                                    Rectangle {
                                                        width: 18
                                                        height: 18
                                                        radius: 9
                                                        color: "#fff"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        x: _alarmRow.modelData.enabled ? parent.width - width - 2 : 2
                                                        Behavior on x { NumberAnimation { duration: 150 } }
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: AlarmState.setAlarmEnabled(_alarmRow.modelData.id, !_alarmRow.modelData.enabled)
                                                    }
                                                }

                                                Rectangle {
                                                    width: 22
                                                    height: 22
                                                    radius: 11
                                                    color: _delAlarmMouse.containsMouse ? "#40ff453a" : "transparent"
                                                    CFVI {
                                                        anchors.centerIn: parent
                                                        width: 10
                                                        height: 10
                                                        icon: "notch/x.svg"
                                                    }
                                                    MouseArea {
                                                        id: _delAlarmMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: AlarmState.removeAlarm(_alarmRow.modelData.id)
                                                    }
                                                }
                                            }
                                        }

                                        CFText {
                                            visible: AlarmState.alarms.length === 0
                                            text: "Aucune alarme"
                                            font.pixelSize: 12
                                            gray: true
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.alarmOpened && !root.alarmClosing
                            onClicked: root.alarmOpened = true
                            onPressed: alarmWidget.isPressed = true
                            onReleased: alarmWidget.isPressed = false
                            onCanceled: alarmWidget.isPressed = false
                        }

                        Rectangle {
                            visible: root.alarmGrowReady
                            width: 26
                            height: 26
                            radius: 13
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            color: _alarmCloseMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                            CFVI {
                                anchors.centerIn: parent
                                width: 11
                                height: 11
                                icon: "notch/x.svg"
                            }
                            MouseArea {
                                id: _alarmCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.alarmOpened = false
                            }
                        }
                    }

                    BoxButton {
                        id: stopwatchWidget
                        widgetId: "stopwatchWidget"
                        xPos: root.packedX("stopwatchWidget")
                        yPos: root.packedY("stopwatchWidget")
                        width: root.stopwatchGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                        height: root.stopwatchGrowReady ? (root.box*2+root.boxMargin) : root.box
                        radius: root.stopwatchGrowReady ? 30 : 40
                        z: root.stopwatchOpened || root.stopwatchClosing ? 5 : 0
                        overwriteX: root.stopwatchGrowReady
                        overwriteXFromRight: root.stopwatchGrowReady
                        overwriteRightPos: root.gridImplicitWidth - root.boxMargin
                        hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.timerOpened || root.timerClosing || root.alarmOpened || root.alarmClosing
                        enabled: StopwatchState.running

                        CFVI {
                            visible: !root.stopwatchOpened && !root.stopwatchClosing
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            icon: "notch/watch.svg"
                            color: (StopwatchState.running || StopwatchState.accumulatedMs > 0) ? "#1C7AFF" : "#fff"
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 14
                            visible: root.stopwatchGrowReady

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                CFText {
                                    text: "Chronomètre"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#fff"
                                }

                                CFText {
                                    text: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
                                    font.pixelSize: 30
                                    font.weight: Font.Bold
                                    color: "#fff"
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    Rectangle {
                                        width: 90
                                        height: 32
                                        radius: 8
                                        color: _swToggleMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                                        CFText {
                                            anchors.centerIn: parent
                                            text: StopwatchState.running ? "Arrêter" : "Démarrer"
                                            font.pixelSize: 12
                                            color: "#fff"
                                        }
                                        MouseArea {
                                            id: _swToggleMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: StopwatchState.toggle()
                                        }
                                    }

                                    Rectangle {
                                        width: 90
                                        height: 32
                                        radius: 8
                                        color: _swResetMouse.containsMouse ? "#40ff453a" : "#20ff453a"
                                        CFText {
                                            anchors.centerIn: parent
                                            text: "Réinitialiser"
                                            font.pixelSize: 12
                                            color: "#ff453a"
                                        }
                                        MouseArea {
                                            id: _swResetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: StopwatchState.reset()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.stopwatchOpened && !root.stopwatchClosing
                            onClicked: root.stopwatchOpened = true
                            onPressed: stopwatchWidget.isPressed = true
                            onReleased: stopwatchWidget.isPressed = false
                            onCanceled: stopwatchWidget.isPressed = false
                        }

                        Rectangle {
                            visible: root.stopwatchGrowReady
                            width: 26
                            height: 26
                            radius: 13
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            color: _stopwatchCloseMouse.containsMouse ? "#28ffffff" : "#18ffffff"
                            CFVI {
                                anchors.centerIn: parent
                                width: 11
                                height: 11
                                icon: "notch/x.svg"
                            }
                            MouseArea {
                                id: _stopwatchCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.stopwatchOpened = false
                            }
                        }
                    }
                }
            }
        }
    }
}
