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
import qs.ui.widgets

Scope {
    id: root

    property bool opened: false
    signal closing()
    property bool wifiOpened: false
    property bool btOpened:   false
    property bool timerOpened: false
    property bool alarmOpened: false
    property bool stopwatchOpened: false
    property bool themeOpened: false
    property bool themeGrowReady: false
    property bool themeContentReady: false
    property bool themeClosing: false
    property bool subOpened:  wifiOpened || btOpened || timerOpened || alarmOpened || stopwatchOpened || themeOpened
    property bool playerExpanded: false

    property bool wifiGrowReady:   false
    property bool wifiContentReady: false
    property bool btGrowReady:     false
    property bool btContentReady: false
    property bool playerGrowReady: false
    property bool playerContentReady: false
    property bool timerGrowReady:  false
    property bool timerContentReady: false
    property bool alarmGrowReady:  false
    property bool alarmContentReady: false
    property bool stopwatchGrowReady: false
    property bool stopwatchContentReady: false
    property bool wifiClosing:   false
    property bool btClosing:     false
    property bool playerClosing: false
    property bool timerClosing:  false
    property bool alarmClosing:  false
    property bool stopwatchClosing: false

    Timer { id: _wifiContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.wifiContentReady = true }
    Timer { id: _wifiCloseTimer; interval: ShellMotion.spatial();  onTriggered: root.wifiClosing = false }
    Timer { id: _themeContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.themeContentReady = true }
    Timer { id: _themeCloseTimer;   interval: ShellMotion.spatial();  onTriggered: root.themeClosing = false }
    Timer { id: _btContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.btContentReady = true }
    Timer { id: _btCloseTimer;   interval: ShellMotion.spatial();  onTriggered: root.btClosing = false }
    Timer { id: _playerContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.playerContentReady = true }
    Timer { id: _playerCloseTimer; interval: ShellMotion.spatial();  onTriggered: root.playerClosing = false }
    Timer { id: _timerContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.timerContentReady = true }
    Timer { id: _timerCloseTimer;  interval: ShellMotion.spatial();  onTriggered: root.timerClosing = false }
    Timer { id: _alarmContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.alarmContentReady = true }
    Timer { id: _alarmCloseTimer;  interval: ShellMotion.spatial();  onTriggered: root.alarmClosing = false }
    Timer { id: _stopwatchContentTimer; interval: ShellMotion.spatial(0.45); onTriggered: root.stopwatchContentReady = true }
    Timer { id: _stopwatchCloseTimer; interval: ShellMotion.spatial();  onTriggered: root.stopwatchClosing = false }

    onWifiOpenedChanged: {
        if (wifiOpened) {
            _wifiCloseTimer.stop()
            wifiClosing = false
            wifiGrowReady = true
            _wifiContentTimer.restart()
        } else {
            _wifiContentTimer.stop()
            wifiContentReady = false
            wifiGrowReady = false
            wifiClosing = true
            _wifiCloseTimer.restart()
        }
    }
    onThemeOpenedChanged: {
        if (themeOpened) {
            _themeCloseTimer.stop()
            themeClosing = false
            themeGrowReady = true
            _themeContentTimer.restart()
        } else {
            _themeContentTimer.stop()
            themeContentReady = false
            themeGrowReady = false
            themeClosing = true
            _themeCloseTimer.restart()
        }
    }
    onBtOpenedChanged: {
        if (btOpened) {
            _btCloseTimer.stop()
            btClosing = false
            btGrowReady = true
            _btContentTimer.restart()
        } else {
            _btContentTimer.stop()
            btContentReady = false
            btGrowReady = false
            btClosing = true
            _btCloseTimer.restart()
        }
    }
    onPlayerExpandedChanged: {
        if (playerExpanded) {
            _playerCloseTimer.stop()
            playerClosing = false
            playerGrowReady = true
            _playerContentTimer.restart()
        } else {
            _playerContentTimer.stop()
            playerContentReady = false
            playerGrowReady = false
            playerClosing = true
            _playerCloseTimer.restart()
        }
    }
    onTimerOpenedChanged: {
        if (timerOpened) {
            _timerCloseTimer.stop()
            timerClosing = false
            timerGrowReady = true
            _timerContentTimer.restart()
        } else {
            _timerContentTimer.stop()
            timerContentReady = false
            timerGrowReady = false
            timerClosing = true
            _timerCloseTimer.restart()
        }
    }
    onAlarmOpenedChanged: {
        if (alarmOpened) {
            _alarmCloseTimer.stop()
            alarmClosing = false
            alarmGrowReady = true
            _alarmContentTimer.restart()
        } else {
            _alarmContentTimer.stop()
            alarmContentReady = false
            alarmGrowReady = false
            alarmClosing = true
            _alarmCloseTimer.restart()
        }
    }
    onStopwatchOpenedChanged: {
        if (stopwatchOpened) {
            _stopwatchCloseTimer.stop()
            stopwatchClosing = false
            stopwatchGrowReady = true
            _stopwatchContentTimer.restart()
        } else {
            _stopwatchContentTimer.stop()
            stopwatchContentReady = false
            stopwatchGrowReady = false
            stopwatchClosing = true
            _stopwatchCloseTimer.restart()
        }
    }

    readonly property int box:        ControlCatalog.box
    readonly property int boxMargin:  ControlCatalog.boxMargin
    readonly property int gridW:      ControlCatalog.gridW
    readonly property int gridH:      8
    readonly property int animationDur: ShellMotion.fade()

    readonly property int gridImplicitWidth:  ((box*gridW)+(boxMargin*gridW)+boxMargin)
    readonly property int gridImplicitHeight: ((box*gridH)+(boxMargin*gridH)+boxMargin)

    readonly property var _packedLayout: ControlCatalog.packedLayout

    property var _slotMemo: ({})

    function packedX(id) {
        var p = root._packedLayout[id]
        if (p) {
            root._slotMemo[id + "x"] = p.xPos
            return p.xPos
        }
        return root._slotMemo[id + "x"] !== undefined ? root._slotMemo[id + "x"] : 0
    }
    function packedY(id) {
        var p = root._packedLayout[id]
        if (p) {
            root._slotMemo[id + "y"] = p.yPos
            return p.yPos
        }
        return root._slotMemo[id + "y"] !== undefined ? root._slotMemo[id + "y"] : 0
    }

    readonly property int _lastVisibleRow: ControlCatalog.shownRows - 1

    readonly property int _visibleGridHeight: (box*(_lastVisibleRow+1)) + (boxMargin*(_lastVisibleRow+1)) + boxMargin

    readonly property color glassColor: "transparent"
    readonly property color textColor:  "#ffffff"
    readonly property color glassRimColor: "transparent"
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
                        root.themeOpened = false
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
        command: ["brightnessctl", "-e2", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split(",")
                if (f.length >= 5) {
                    var pct = parseFloat(f[3])
                    if (isFinite(pct)) {
                        var val = pct / 100
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
            _brtSet.command = ["brightnessctl", "-e2", "set", Math.round(root.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }

    readonly property bool focusOn: NotifService.dndEnabled
    property bool recording: false

    function openCalculator() {
        var list = Hyprland.toplevels.values
        for (var i = 0; i < list.length; i++) {
            var t = list[i]
            var ipc = t.lastIpcObject
            var title = (ipc && ipc.title) ? ipc.title : t.title
            if (title !== "calculator") continue
            var addr = String(t.address).toLowerCase()
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })')
            return
        }
        _calcCmd.running = true
    }

    Process {
        id: _calcCmd
        command: [
            "sh", "-c",
            "script=\"$1\"; lang=\"$2\"; " +
            "if pgrep -f 'tools/calculator/calc.py' | grep -vx \"$$\" >/dev/null 2>&1; then exit 0; fi; " +
            "if command -v python3 >/dev/null 2>&1; then run=\"python3 '$script' --lang '$lang'\"; " +
            "elif command -v qalc >/dev/null 2>&1; then run=\"qalc -i\"; " +
            "else echo \"python3 introuvable\" >&2; exit 1; fi; " +
            "if command -v foot >/dev/null 2>&1; then exec foot --title=calculator -e sh -c \"$run\"; " +
            "elif command -v kitty >/dev/null 2>&1; then exec kitty --title calculator sh -c \"$run\"; " +
            "elif command -v alacritty >/dev/null 2>&1; then exec alacritty --title calculator -e sh -c \"$run\"; " +
            "elif command -v ghostty >/dev/null 2>&1; then exec ghostty --title=calculator -e sh -c \"$run\"; " +
            "elif command -v wezterm >/dev/null 2>&1; then exec wezterm start -- sh -c \"$run\"; " +
            "elif command -v konsole >/dev/null 2>&1; then exec konsole -e sh -c \"$run\"; " +
            "elif command -v gnome-terminal >/dev/null 2>&1; then exec gnome-terminal --title=calculator -- sh -c \"$run\"; " +
            "elif command -v xterm >/dev/null 2>&1; then exec xterm -T calculator -e sh -c \"$run\"; " +
            "else echo \"aucun terminal trouve\" >&2; exit 1; fi",
            "sh",
            Quickshell.shellDir + "/tools/calculator/calc.py",
            I18n.lang
        ]
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
            ControlCatalog.galleryOpen = false
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

                mask: ControlCatalog.galleryOpen ? editMask : null

                Region {
                    id: editMask
                    item: ccContent
                    Region { item: editPill }
                }

                GlassBackdrop { id: ccBackdrop; element: "cc" }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.wifiOpened || root.btOpened || root.themeOpened || root.playerExpanded) {
                            root.wifiOpened = false
                            root.btOpened   = false
                            root.themeOpened = false
                            root.playerExpanded = false
                        } else if (!ControlCatalog.galleryOpen) {
                            root.closing()
                        }
                    }
                }

                WidgetContextMenu {
                    id: ccMenu

                    property string target: ""

                    onChosen: function(action) {
                        if (action === "remove") ControlCatalog.remove(ccMenu.target)
                    }
                }

                Item {
                    id: ccContent
                    width:  root.gridImplicitWidth
                    height: root._visibleGridHeight
                    Behavior on height {
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 30
                    anchors.rightMargin: 10
                    transformOrigin: Item.TopRight
                    scale: 0.95 + 0.05 * showProgress
                    opacity: showProgress

                    property real showProgress: 0
                    Behavior on showProgress {
                        NumberAnimation {
                            duration: root.animationDur
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: ShellMotion.effectsCurve
                        }
                    }
                    Component.onCompleted: showProgress = 1
                    Connections {
                        target: root
                        function onOpenedChanged() {
                            if (!root.opened) ccContent.showProgress = 0
                        }
                    }

                    Repeater {
                        model: ControlCatalog.maxRows * ControlCatalog.gridW

                        delegate: Rectangle {
                            id: slotCell
                            required property int index
                            readonly property int cx: slotCell.index % ControlCatalog.gridW
                            readonly property int cy: Math.floor(slotCell.index / ControlCatalog.gridW)
                            readonly property bool shown: ControlCatalog.galleryOpen
                                                          && slotCell.cy < ControlCatalog.shownRows
                                                          && !ControlCatalog.occupied[ControlCatalog.key(slotCell.cx, slotCell.cy)]
                            x: ccContent.gridX(slotCell.cx)
                            y: ccContent.gridY(slotCell.cy)
                            width: root.box
                            height: root.box
                            radius: root.box / 2
                            color: "#26ffffff"
                            border.width: 1
                            border.color: "#18ffffff"
                            opacity: slotCell.shown ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity {
                                NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                            }
                        }
                    }

                    Rectangle {
                        id: dropPreview
                        readonly property var target: ControlCatalog.preview
                        property var shape: null
                        property int cellX: 0
                        property int cellY: 0
                        onTargetChanged: {
                            if (!dropPreview.target) return
                            dropPreview.shape = ControlCatalog.infoOf(dropPreview.target.type)
                            dropPreview.cellX = dropPreview.target.x
                            dropPreview.cellY = dropPreview.target.y
                        }
                        x: ccContent.gridX(dropPreview.cellX)
                        y: ccContent.gridY(dropPreview.cellY)
                        width: dropPreview.shape ? dropPreview.shape.w * root.box + (dropPreview.shape.w - 1) * root.boxMargin : root.box
                        height: dropPreview.shape ? dropPreview.shape.h * root.box + (dropPreview.shape.h - 1) * root.boxMargin : root.box
                        radius: 32
                        color: "#40ffffff"
                        border.width: 2
                        border.color: "#80ffffff"
                        opacity: dropPreview.target ? 1 : 0
                        visible: opacity > 0
                        Behavior on x {
                            enabled: dropPreview.opacity > 0.5
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on y {
                            enabled: dropPreview.opacity > 0.5
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["text/plain"]
                        function controlId(drag) {
                            return drag.hasText && drag.text.indexOf("cc:") === 0 ? drag.text.substring(3) : ""
                        }
                        function track(drag) {
                            var info = ControlCatalog.infoOf(controlId(drag))
                            if (!info) return
                            var left = drag.x - (info.w * root.box + (info.w - 1) * root.boxMargin) / 2
                            var top = drag.y - (info.h * root.box + (info.h - 1) * root.boxMargin) / 2
                            ControlCatalog.setPreview("", info.id, (left - root.boxMargin) / ControlCatalog.cell, (top - root.boxMargin) / ControlCatalog.cell)
                        }
                        onEntered: function(drag) {
                            drag.accepted = ControlCatalog.galleryOpen && controlId(drag) !== ""
                            if (drag.accepted) track(drag)
                        }
                        onPositionChanged: function(drag) { track(drag) }
                        onExited: ControlCatalog.clearPreview()
                        onDropped: function(drop) {
                            drop.accept(Qt.CopyAction)
                            ControlCatalog.commitPreview()
                        }
                    }

                    Rectangle {
                        id: editPill
                        y: ccContent.height + 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: _editControlsLabel.implicitWidth + 28
                        height: 28
                        radius: 14
                        color: "#40000000"
                        border.width: 1
                        border.color: "#30ffffff"
                        opacity: ControlCatalog.galleryOpen ? 0 : 1
                        enabled: !ControlCatalog.galleryOpen
                        Behavior on opacity {
                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                        }

                        Text {
                            id: _editControlsLabel
                            anchors.centerIn: parent
                            text: I18n.tr("Edit Controls…")
                            color: Theme.ink(parent, false)
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCatalog.galleryOpen = true
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
                        radius: 32
                        backdrop: ccBackdrop
                        property bool enabled: false
                        property bool hideCause: false || root.themeOpened || root.themeClosing
                        property bool scaleCause: false
                        property bool forceTransparentRim: false
                        property bool isPressed: false
                        property bool growing: false
                        property bool hoverFx: true
                        property string widgetId: ""
                        readonly property bool hiddenByUser: boxbutton.widgetId !== "" && ControlCatalog.isLeaving(boxbutton.widgetId)
                        readonly property var info: ControlCatalog.infoOf(ControlCatalog.typeOfUid(boxbutton.widgetId))
                        property bool appeared: false
                        Component.onCompleted: boxbutton.appeared = true

                        opacity: (boxbutton.hideCause || boxbutton.hiddenByUser || !boxbutton.appeared) ? 0 : 1
                        visible: opacity > 0
                        scale: boxbutton.dragging ? 1.06 : (boxbutton.scaleCause ? 1.25 : (boxbutton.isPressed ? 0.97 : 1.0))
        z: boxbutton.dragging ? 100 : 0
        property bool dragging: false
        property real dragDX: 0
        property real dragDY: 0

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
                            leftMargin: (boxbutton.overwriteXFromRight
                                            ? (boxbutton.overwriteRightPos - boxbutton.width)
                                            : (boxbutton.overwriteX ? boxbutton.overwriteXPos : ccContent.gridX(boxbutton.xPos))) + boxbutton.dragDX
                            topMargin: (boxbutton.overwriteY ? boxbutton.overwriteYPos : ccContent.gridY(boxbutton.yPos)) + boxbutton.dragDY
                        }

                        Behavior on anchors.leftMargin {
                            enabled: !boxbutton.overwriteXFromRight && !boxbutton.dragging
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on anchors.topMargin {
                            enabled: !boxbutton.dragging
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: ShellMotion.fade(0.8); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: (boxbutton.dragging || boxbutton.scaleCause) ? ShellMotion.spatial() : 200
                                easing.type: (boxbutton.dragging || boxbutton.scaleCause) ? Easing.BezierSpline : Easing.OutBack
                                easing.overshoot: 2.4
                                easing.bezierCurve: ShellMotion.spatialCurve
                            }
                        }
                        Behavior on width {
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on height {
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }
                        Behavior on radius {
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }

                        readonly property bool editing: ControlCatalog.galleryOpen && boxbutton.widgetId !== ""

                        HoverHandler { id: tileHoverHandler }
                        Rectangle {
                            anchors.fill: parent
                            radius: boxbutton.radius
                            color: (boxbutton.hoverFx && !boxbutton.editing && tileHoverHandler.hovered) ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0)
                            Behavior on color { ColorAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            id: removeBadge
                            x: -6
                            y: -6
                            z: 60
                            width: 22
                            height: 22
                            radius: 11
                            color: Theme.popup("#e0303034")
                            border.width: 1
                            border.color: "#50ffffff"
                            visible: boxbutton.editing
                            scale: removeArea.pressed ? 0.9 : 1

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 2
                                radius: 1
                                color: Theme.ink(parent, false)
                            }

                            MouseArea {
                                id: removeArea
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ControlCatalog.remove(boxbutton.widgetId)
                            }
                        }

                        MouseArea {
                            id: editOverlay
                            anchors.fill: parent
                            z: 50
                            visible: boxbutton.editing
                            enabled: boxbutton.editing
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onPressed: function(mouse) {
                                if (mouse.button !== Qt.RightButton) return
                                ccMenu.target = boxbutton.widgetId
                                var p = mapToItem(ccMenu, mouse.x, mouse.y)
                                ccMenu.openAt(p.x, p.y, [{ label: I18n.tr("Remove"), action: "remove", danger: true }])
                            }

                            DragHandler {
                                target: null
                                acceptedButtons: Qt.LeftButton
                                onActiveChanged: {
                                    if (active) {
                                        boxbutton.dragging = true
                                        return
                                    }
                                    boxbutton.dragging = false
                                    boxbutton.dragDX = 0
                                    boxbutton.dragDY = 0
                                    ControlCatalog.commitPreview()
                                }
                                onCentroidChanged: {
                                    if (!active) return
                                    boxbutton.dragDX = centroid.scenePosition.x - centroid.scenePressPosition.x
                                    boxbutton.dragDY = centroid.scenePosition.y - centroid.scenePressPosition.y
                                    var left = ccContent.gridX(boxbutton.xPos) + boxbutton.dragDX
                                    var top = ccContent.gridY(boxbutton.yPos) + boxbutton.dragDY
                                    var cx = left + boxbutton.width / 2
                                    var cy = top + boxbutton.height / 2
                                    var outside = cx < -ControlCatalog.cell / 2 || cx > ccContent.width + ControlCatalog.cell / 2
                                                  || cy < -ControlCatalog.cell / 2 || cy > ccContent.height + ControlCatalog.cell / 2
                                    if (outside) ControlCatalog.clearPreview()
                                    else ControlCatalog.setPreview(boxbutton.widgetId, boxbutton.info.id, (left - root.boxMargin) / ControlCatalog.cell, (top - root.boxMargin) / ControlCatalog.cell)
                                }
                            }
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
                            color: Theme.ink(parent, false)
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

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("wifiWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: wifiWidget
                                widgetId: wifiWidget.modelData.uid
                                xPos: root.packedX(wifiWidget.widgetId)
                                yPos: root.packedY(wifiWidget.widgetId)
                                width: root.wifiGrowReady ? root.gridImplicitWidth : root.box*2+root.boxMargin
                                height: root.wifiGrowReady ? _wPanel.implicitHeight : root.box
                                radius: root.wifiGrowReady ? 12 : 32
                                hoverFx: !root.wifiOpened
                                enabled: root.wifiOn
                                hideCause: root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
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
                                        opacity: root.wifiContentReady ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                        }

                                        BoxGlass {
                                            backdrop: null
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
                                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                        }
                                        CFClippingRect {
                                            id: wifiCircle
                                            width: 38
                                            height: 38
                                            radius: 19
                                            anchors.left: parent.left
                                            anchors.leftMargin: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: root.wifiOn ? "#fff" : Qt.rgba(1,1,1,0.18)
                                            CFVI {
                                                anchors.centerIn: parent
                                                width: 26
                                                height: 26
                                                icon: "wifi/nm-signal-100-symbolic.svg"
                                                color: root.wifiOn ? Theme.accent : "#fff"
                                            }
                                        }
                                        Column {
                                            anchors.left: wifiCircle.right
                                            anchors.leftMargin: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1
                                            CFText {
                                                text: I18n.tr("Wi-Fi")
                                                font.family: "SF Pro Text"
                                                font.weight: Font.DemiBold
                                                font.pixelSize: 13
                                                color: Theme.ink(parent, false)
                                            }
                                            CFText {
                                                text: root.wifiSSID
                                                font.family: "SF Pro Text"
                                                font.weight: Font.DemiBold
                                                font.pixelSize: 12
                                                color: Qt.rgba(1,1,1,0.55)
                                                width: root.box * 2 + root.boxMargin - 11 - 38 - 9 - 14
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("btWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: btWidget
                                widgetId: btWidget.modelData.uid
                                xPos: root.packedX(btWidget.widgetId)
                                yPos: root.packedY(btWidget.widgetId)
                                width: root.btGrowReady ? root.gridImplicitWidth : root.box
                                height: root.btGrowReady ? _btPanel.implicitHeight : root.box
                                radius: root.btGrowReady ? 12 : 32
                                hoverFx: !root.btOpened
                                property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                                enabled: btOn
                                hideCause: root.wifiOpened || root.wifiClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
                                overwriteX: root.btGrowReady
                                overwriteY: root.btGrowReady
                                overwriteXPos: 0
                                overwriteYPos: root.boxMargin

                                z: (root.btOpened || root.btClosing) ? 100 : 0
                                forceTransparentRim: root.btOpened
                                light: btWidget.forceTransparentRim ? "transparent" : (btWidget.enabled ? "transparent" : root.glassRimColor)
                                rimStrength: btWidget.forceTransparentRim ? 0 : (btWidget.enabled ? 0 : root.glassRimStrength)
                                color: btWidget.forceTransparentRim ? "transparent" : (btWidget.enabled ? "#fff" : root.glassColor)
                                Behavior on color { ColorAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                Behavior on light { ColorAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                Behavior on rimStrength { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                                    CFClippingRect {
                                        anchors.fill: parent
                                        radius: 12
                                        visible: opacity > 0
                                        opacity: root.btContentReady ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                        }

                                        BoxGlass {
                                            backdrop: null
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
                                            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                        }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.min(32, width / 2)
                                        color: "#fff"
                                        opacity: btWidget.enabled ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                    }
                                    CFClippingRect {
                                        anchors.centerIn: parent
                                        width: 38; height: 38; radius: 19
                                        color: btWidget.enabled ? "#fff" : Qt.rgba(1,1,1,0.18)
                                        Behavior on color { ColorAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                        CFVI {
                                            anchors.centerIn: parent
                                            width: 30; height: 30
                                            icon: "bluetooth/bluetooth.svg"
                                            color: btWidget.enabled ? Theme.accent : "#fff"
                                            Behavior on color { ColorAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("adWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: adWidget
                                widgetId: adWidget.modelData.uid
                                xPos: root.packedX(adWidget.widgetId)
                                yPos: root.packedY(adWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
                                enabled: true
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    icon: "devices/smartphone.svg"
                                    color: Theme.accent
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("musicWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: musicWidget
                                widgetId: musicWidget.modelData.uid
                                xPos: root.packedX(musicWidget.widgetId)
                                yPos: root.packedY(musicWidget.widgetId)
                                width: root.playerGrowReady ? root.gridImplicitWidth : root.box*2+root.boxMargin
                                height: root.playerGrowReady ? expCol.implicitHeight + 32 : root.box*2+root.boxMargin
                                radius: root.playerGrowReady ? 24 : 32
                                hoverFx: false
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.themeOpened || root.themeClosing
                                overwriteY: root.playerGrowReady
                                overwriteXFromRight: root.playerExpanded || root.playerClosing
                                overwriteRightPos: ccContent.gridX(root.packedX(musicWidget.widgetId)) + (root.box*2+root.boxMargin)
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
                                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.playerExpanded = true
                                            _pPosition.running = true
                                            _pLength.running   = true
                                        }
                                    }

                                    PlayerArt {
                                        id: artRect
                                        x: 12
                                        y: 12
                                        width: 52
                                        height: 52
                                        r: 10
                                        source: root.musicArt
                                    }
                                    Column {
                                        x: 12
                                        y: 66
                                        width: parent.width - 24
                                        spacing: 1
                                        CFText {
                                            width: parent.width
                                            text: root.musicTitle
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        CFText {
                                            width: parent.width
                                            text: root.musicArtist
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            gray: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: parent.height - 38
                                        spacing: 2
                                        PlayerBtn {
                                            width: 32
                                            height: 30
                                            gw: 22
                                            gh: 20
                                            kind: "prev"
                                            col: Theme.ink(parent, false)
                                            onClicked: _pPrev.running = true
                                        }
                                        PlayerBtn {
                                            width: 32
                                            height: 30
                                            gw: 22
                                            gh: 22
                                            kind: root.musicPlaying ? "pause" : "play"
                                            col: Theme.ink(parent, false)
                                            onClicked: _pPlay.running = true
                                        }
                                        PlayerBtn {
                                            width: 32
                                            height: 30
                                            gw: 22
                                            gh: 20
                                            kind: "next"
                                            col: Theme.ink(parent, false)
                                            onClicked: _pNext.running = true
                                        }
                                    }
                                }

                                Item {
                                    anchors.fill: parent
                                    visible: opacity > 0
                                    opacity: root.playerContentReady ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
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
                                                        text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.description) ? Pipewire.defaultAudioSink.description : I18n.tr("Sortie audio")
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("focusWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: focusWidget
                                widgetId: focusWidget.modelData.uid
                                xPos: root.packedX(focusWidget.widgetId)
                                yPos: root.packedY(focusWidget.widgetId)
                                width: root.box*2+root.boxMargin
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
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
                                    anchors.right: parent.right
                                    anchors.rightMargin: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    text: I18n.tr("Focus")
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: root.focusOn ? "#000" : "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        NotifService.dndEnabled = !NotifService.dndEnabled
                                    }
                                    onPressed: focusWidget.isPressed = true
                                    onReleased: focusWidget.isPressed = false
                                    onCanceled: focusWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("stageWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: stageWidget
                                widgetId: stageWidget.modelData.uid
                                xPos: root.packedX(stageWidget.widgetId)
                                yPos: root.packedY(stageWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("shareWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: shareWidget
                                widgetId: shareWidget.modelData.uid
                                xPos: root.packedX(shareWidget.widgetId)
                                yPos: root.packedY(shareWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
                                enabled: root.recording
                                CFVI {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 20
                                    icon: "screenshare.svg"
                                    color: root.recording ? Theme.accent : "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.recording = !root.recording
                                        if (root.recording) {
                                            _shOn.running = true
                                        } else {
                                            _shOn.signal(2)
                                        }
                                    }
                                    onPressed: shareWidget.isPressed = true
                                    onReleased: shareWidget.isPressed = false
                                    onCanceled: shareWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("displayWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: displayWidget
                                widgetId: displayWidget.modelData.uid
                                xPos: root.packedX(displayWidget.widgetId)
                                yPos: root.packedY(displayWidget.widgetId)
                                width: root.box*4+root.boxMargin*3
                                height: root.box
                                radius: 26
                                hoverFx: false
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing

                                CFSlider {
                                    autoHideHandle: true
                                    glassBackdrop: ccBackdrop
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
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "sun-small.svg"
                                    size: 16
                                }
                                CFVI {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "sun-huge.svg"
                                    size: 16
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("volumeWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: volumeWidget
                                widgetId: volumeWidget.modelData.uid
                                xPos: root.packedX(volumeWidget.widgetId)
                                yPos: root.packedY(volumeWidget.widgetId)
                                width: root.box*4+root.boxMargin*3
                                height: root.box
                                radius: 26
                                hoverFx: false
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing

                                CFSlider {
                                    autoHideHandle: true
                                    glassBackdrop: ccBackdrop
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
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "volume/audio-volume-1.svg"
                                    size: 16
                                }
                                CFVI {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "volume/audio-volume-3.svg"
                                    size: 16
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("darkWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: themeWidget
                                widgetId: themeWidget.modelData.uid
                                xPos: root.packedX(themeWidget.widgetId)
                                yPos: root.packedY(themeWidget.widgetId)
                                width: root.themeGrowReady ? root.gridImplicitWidth : root.box*2+root.boxMargin
                                height: root.themeGrowReady ? _tPanel.implicitHeight : root.box
                                radius: root.themeGrowReady ? 12 : 32
                                hoverFx: !root.themeOpened
                                enabled: false
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing
                                overwriteX: root.themeGrowReady
                                overwriteY: root.themeGrowReady
                                overwriteXPos: 0
                                overwriteYPos: root.boxMargin

                                z: (root.themeOpened || root.themeClosing) ? 100 : 0
                                forceTransparentRim: root.themeOpened
                                light: themeWidget.forceTransparentRim ? "transparent" : root.glassRimColor
                                rimStrength: themeWidget.forceTransparentRim ? 0 : root.glassRimStrength
                                color: themeWidget.forceTransparentRim ? "transparent" : root.glassColor

                                CFClippingRect {
                                    anchors.fill: parent
                                    radius: 12
                                    visible: opacity > 0
                                    opacity: root.themeContentReady ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                    }

                                    BoxGlass {
                                        backdrop: null
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

                                        CCThemePanel {
                                            id: _tPanel
                                            width: root.gridImplicitWidth
                                            onCloseRequested: root.themeOpened = false
                                        }
                                    }
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    width: root.box*2+root.boxMargin
                                    height: root.box
                                    visible: opacity > 0
                                    opacity: (!root.themeOpened && !root.themeClosing) ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                                    CFClippingRect {
                                        id: themeCircle
                                        anchors.left: parent.left
                                        anchors.leftMargin: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 38; height: 38; radius: 19
                                        color: Qt.rgba(1, 1, 1, 0.18)
                                        CFVI {
                                            anchors.centerIn: parent
                                            icon: Theme.isDark ? "notch/moon.svg" : (Theme.isLight ? "weather/sun.svg" : "settings/appearance.svg")
                                            size: 26
                                            color: "#fff"
                                        }
                                    }

                                    Column {
                                        anchors.left: themeCircle.right
                                        anchors.leftMargin: 9
                                        anchors.right: parent.right
                                        anchors.rightMargin: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        CFText {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: I18n.tr("Theme")
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            color: "#fff"
                                        }
                                        CFText {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: Theme.isDark ? I18n.tr("Sombre") : (Theme.isLight ? I18n.tr("Clair") : "Liquid Glass")
                                            font.family: "SF Pro Text"
                                            font.pixelSize: 11
                                            color: Qt.rgba(1, 1, 1, 0.6)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.themeOpened
                                    onClicked: {
                                        root.wifiOpened = false
                                        root.btOpened = false
                                        root.playerExpanded = false
                                        root.themeOpened = true
                                    }
                                    onPressed: themeWidget.isPressed = true
                                    onReleased: themeWidget.isPressed = false
                                    onCanceled: themeWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("calcWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: calcWidget
                                widgetId: calcWidget.modelData.uid
                                xPos: root.packedX(calcWidget.widgetId)
                                yPos: root.packedY(calcWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
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
                                        color: Theme.ink(parent, false)
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
                                                color: Theme.ink(parent, false)
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.openCalculator()
                                    }
                                    onPressed: if (!root.subOpened) calcWidget.isPressed = true
                                    onReleased: calcWidget.isPressed = false
                                    onCanceled: calcWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("gameModeWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: gameModeWidget
                                widgetId: gameModeWidget.modelData.uid
                                xPos: root.packedX(gameModeWidget.widgetId)
                                yPos: root.packedY(gameModeWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
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
                                        border.color: GameMode.enabled ? Theme.accent : "#fff"
                                        border.width: 2
                                    }
                                    Rectangle {
                                        width: 8
                                        height: 2
                                        radius: 1
                                        color: GameMode.enabled ? Theme.accent : "#fff"
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 2
                                        height: 8
                                        radius: 1
                                        color: GameMode.enabled ? Theme.accent : "#fff"
                                        anchors.left: parent.left
                                        anchors.leftMargin: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: GameMode.enabled ? Theme.accent : "#fff"
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        anchors.top: parent.top
                                        anchors.topMargin: 5
                                    }
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: GameMode.enabled ? Theme.accent : "#fff"
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("keepAwakeWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: keepAwakeWidget
                                widgetId: keepAwakeWidget.modelData.uid
                                xPos: root.packedX(keepAwakeWidget.widgetId)
                                yPos: root.packedY(keepAwakeWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
                                enabled: KeepAwake.enabled
                                light: keepAwakeWidget.enabled ? "transparent" : root.glassRimColor
                                rimStrength: keepAwakeWidget.enabled ? 0 : root.glassRimStrength
                                color: keepAwakeWidget.enabled ? "#fff" : root.glassColor
                                CFVI {
                                    anchors.centerIn: parent
                                    size: 26
                                    icon: "notch/coffee.svg"
                                    color: KeepAwake.enabled ? Theme.accent : "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: KeepAwake.toggle()
                                    onPressed: if (!root.subOpened) keepAwakeWidget.isPressed = true
                                    onReleased: keepAwakeWidget.isPressed = false
                                    onCanceled: keepAwakeWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("nightShiftWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: nightShiftWidget
                                widgetId: nightShiftWidget.modelData.uid
                                xPos: root.packedX(nightShiftWidget.widgetId)
                                yPos: root.packedY(nightShiftWidget.widgetId)
                                width: root.box
                                height: root.box
                                radius: 32
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.themeOpened || root.themeClosing
                                enabled: NightShift.enabled
                                light: nightShiftWidget.enabled ? "transparent" : root.glassRimColor
                                rimStrength: nightShiftWidget.enabled ? 0 : root.glassRimStrength
                                color: nightShiftWidget.enabled ? "#fff" : root.glassColor
                                opacity: NightShift.available ? 1 : 0.45
                                CFVI {
                                    anchors.centerIn: parent
                                    size: 26
                                    icon: "notch/sunset.svg"
                                    color: NightShift.enabled ? Theme.accent : "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: NightShift.toggle()
                                    onPressed: if (!root.subOpened) nightShiftWidget.isPressed = true
                                    onReleased: nightShiftWidget.isPressed = false
                                    onCanceled: nightShiftWidget.isPressed = false
                                }
                            }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("timerWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: timerWidget
                                widgetId: timerWidget.modelData.uid
                                xPos: root.packedX(timerWidget.widgetId)
                                yPos: root.packedY(timerWidget.widgetId)
                                width: root.timerGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                                height: root.timerGrowReady ? (root.box*2+root.boxMargin) : root.box
                                radius: root.timerGrowReady ? 30 : 32
                                z: root.timerOpened || root.timerClosing ? 5 : 0
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.alarmOpened || root.alarmClosing || root.stopwatchOpened || root.stopwatchClosing || root.themeOpened || root.themeClosing
                                enabled: TimerState.running || TimerState.firing

                                CFVI {
                                    opacity: (!root.timerOpened && !root.timerClosing) ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    icon: "notch/clock.svg"
                                    color: (TimerState.running || TimerState.firing) ? Theme.accent : "#fff"
                                }
                                Rectangle {
                                    opacity: (!root.timerOpened && !root.timerClosing && (TimerState.running || TimerState.firing)) ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: TimerState.firing ? "#ff453a" : Theme.accent
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    opacity: root.timerContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 10

                                        CFText {
                                            text: I18n.tr("Minuteur")
                                            font.pixelSize: 15
                                            font.weight: Font.Bold
                                            color: Theme.ink(parent, false)
                                        }

                                        CFText {
                                            visible: TimerState.firing
                                            text: I18n.tr("Terminé")
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
                                            color: Theme.ink(parent, false)
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
                                                        color: Theme.ink(parent, false)
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
                                                    text: TimerState.running ? I18n.tr("Pause") : I18n.tr("Reprendre")
                                                    font.pixelSize: 12
                                                    color: Theme.ink(parent, false)
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
                                                    text: TimerState.firing ? I18n.tr("OK") : I18n.tr("Annuler")
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
                                    opacity: root.timerContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("alarmWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: alarmWidget
                                widgetId: alarmWidget.modelData.uid
                                xPos: root.packedX(alarmWidget.widgetId)
                                yPos: root.packedY(alarmWidget.widgetId)
                                width: root.alarmGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                                height: root.alarmGrowReady ? (root.box*2+root.boxMargin) : root.box
                                radius: root.alarmGrowReady ? 30 : 32
                                z: root.alarmOpened || root.alarmClosing ? 5 : 0
                                overwriteX: root.alarmGrowReady
                                overwriteXFromRight: root.alarmGrowReady
                                overwriteRightPos: root.gridImplicitWidth - root.boxMargin
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.timerOpened || root.timerClosing || root.stopwatchOpened || root.stopwatchClosing || root.themeOpened || root.themeClosing
                                enabled: AlarmState.alarms.filter(function(a) { return a.enabled }).length > 0

                                CFVI {
                                    opacity: (!root.alarmOpened && !root.alarmClosing) ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    icon: "notch/bell.svg"
                                    color: alarmWidget.enabled ? Theme.accent : "#fff"
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    opacity: root.alarmContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true

                                            CFText {
                                                text: I18n.tr("Alarmes")
                                                font.pixelSize: 15
                                                font.weight: Font.Bold
                                                color: Theme.ink(parent, false)
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
                                                                color: Theme.ink(parent, false)
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
                                                    text: I18n.tr("Aucune alarme")
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
                                    opacity: root.alarmContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
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
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ControlCatalog.instancesOfType("stopwatchWidget")
                            objectProp: "uid"
                        }
                        delegate: BoxButton {
                                required property var modelData
                                id: stopwatchWidget
                                widgetId: stopwatchWidget.modelData.uid
                                xPos: root.packedX(stopwatchWidget.widgetId)
                                yPos: root.packedY(stopwatchWidget.widgetId)
                                width: root.stopwatchGrowReady ? (root.box*4+root.boxMargin*3) : root.box
                                height: root.stopwatchGrowReady ? (root.box*2+root.boxMargin) : root.box
                                radius: root.stopwatchGrowReady ? 30 : 32
                                z: root.stopwatchOpened || root.stopwatchClosing ? 5 : 0
                                overwriteX: root.stopwatchGrowReady
                                overwriteXFromRight: root.stopwatchGrowReady
                                overwriteRightPos: root.gridImplicitWidth - root.boxMargin
                                hideCause: root.wifiOpened || root.wifiClosing || root.btOpened || root.btClosing || root.playerExpanded || root.playerClosing || root.timerOpened || root.timerClosing || root.alarmOpened || root.alarmClosing || root.themeOpened || root.themeClosing
                                enabled: StopwatchState.running

                                CFVI {
                                    opacity: (!root.stopwatchOpened && !root.stopwatchClosing) ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    icon: "notch/watch.svg"
                                    color: (StopwatchState.running || StopwatchState.accumulatedMs > 0) ? Theme.accent : "#fff"
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    opacity: root.stopwatchContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 10

                                        CFText {
                                            text: I18n.tr("Chronomètre")
                                            font.pixelSize: 15
                                            font.weight: Font.Bold
                                            color: Theme.ink(parent, false)
                                        }

                                        CFText {
                                            text: StopwatchState.formatElapsed(StopwatchState.elapsedMs)
                                            font.pixelSize: 30
                                            font.weight: Font.Bold
                                            color: Theme.ink(parent, false)
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
                                                    text: StopwatchState.running ? I18n.tr("Arrêter") : I18n.tr("Démarrer")
                                                    font.pixelSize: 12
                                                    color: Theme.ink(parent, false)
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
                                                    width: Math.min(implicitWidth, parent.width - 16)
                                                    elide: Text.ElideRight
                                                    text: I18n.tr("Réinitialiser")
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
                                    opacity: root.stopwatchContentReady ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
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
}
