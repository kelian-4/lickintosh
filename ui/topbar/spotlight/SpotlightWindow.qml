import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import qs.ui.glass

Scope {
    id: root

    property bool opened: false
    signal closeRequested()

    readonly property color glassColor: "#c01e1e1e"
    readonly property color textColor:  "#dfdfdf"

    FontLoader { id: sfRounded;       source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf") }
    FontLoader { id: sfRoundedMedium; source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Medium.otf") }

    readonly property var systemActions: [
        { title: "Screenshot région",  description: "Prefix: > | Capture zone", cmd: "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png", icon: "screenshot/region.svg" },
        { title: "Screenshot écran",   description: "Prefix: > | Capture totale", cmd: "grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png", icon: "screenshot/monitor.svg" },
        { title: "Google Lens",        description: "Prefix: > | Recherche visuelle", cmd: "grim -g \"$(slurp)\" /tmp/lens.png && xdg-open \"https://www.google.com/searchbyimage?image_url=https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png&sbisrc=cr_1&image_content=$(base64 -w0 /tmp/lens.png)\"", icon: "search.svg" },
        { title: "Lock",               description: "Prefix: > | Verrouiller", cmd: "hyprlock", icon: "lock.svg" },
        { title: "Sleep",              description: "Prefix: > | Veille", cmd: "systemctl suspend", icon: "indicator.svg" },
        { title: "Reboot",             description: "Prefix: > | Redémarrer", cmd: "systemctl reboot", icon: "arrow-counterclockwise.svg" }
    ]

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: win

                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.namespace:     "quickshell:spotlight"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; left: true; right: true; bottom: true }

                property bool   actionsShown:   false
                property string selectedAction: ""
                property string hoveredAction:  ""
                property int    currentIdx:     0
                property var    fileAnswers:    []
                property var    wallAnswers:    []
                property string pendingQuery:   ""
                property var    clipAnswers:    []

                property list<var> answers: {
                    var t = searchField.text
                    var action = win.selectedAction

                    if (t.startsWith(">")) {
                        var sub = t.substring(1)
                        var out = []

                        if (sub.startsWith("=")) {
                            var expr = sub.substring(1).trim()
                            if (expr !== "") {
                                try {
                                    var res = eval(expr)
                                    out.push({ title: res.toString(), description: "Calculatrice (Entrée pour copier)", icon: "accessories-calculator", isCalc: true, value: res.toString() })
                                } catch(e) {}
                            }
                        }
                        else if (sub.startsWith("?")) {
                            var q = sub.substring(1).trim()
                            if (q !== "") {
                                out.push({ title: "Rechercher '" + q + "'", description: "Recherche Web", icon: "internet-web-browser", isWeb: true, query: q })
                            }
                        }
                        else if (sub.startsWith("/w")) {
                            var wq = sub.substring(2).trim().toLowerCase()
                            for (var i = 0; i < win.wallAnswers.length; i++) {
                                if (wq === "" || win.wallAnswers[i].title.toLowerCase().indexOf(wq) !== -1) {
                                    out.push(win.wallAnswers[i])
                                }
                            }
                        }
                        else {
                            var filter = sub.trim().toLowerCase()
                            if (filter === "") {
                                out.push({ title: "Calculatrice", description: "Prefix: >=", icon: "accessories-calculator", dummy: true, targetPrefix: ">=" })
                                out.push({ title: "Recherche Web", description: "Prefix: >?", icon: "internet-web-browser", dummy: true, targetPrefix: ">?" })
                                out.push({ title: "Fonds d'écran", description: "Prefix: >/w", icon: "image-x-generic", dummy: true, targetPrefix: ">/w" })
                            }
                            var sys = root.systemActions.filter(function(a) {
                                return filter === "" || a.title.toLowerCase().indexOf(filter) !== -1
                            })
                            for (var j = 0; j < sys.length; j++) out.push(sys[j])
                        }
                        return out
                    }

                    var classicOut = []
                    if (action === "search" || action === "applications") {
                        if (t === "") return []
                        var apps = DesktopEntries.applications.values
                            .filter(function(a) { return a.name.toLowerCase().indexOf(t.toLowerCase()) !== -1 })
                            .sort(function(a, b) {
                                var ai = a.name.toLowerCase().indexOf(t.toLowerCase())
                                var bi = b.name.toLowerCase().indexOf(t.toLowerCase())
                                return ai !== bi ? ai - bi : a.name.localeCompare(b.name)
                            })
                            .slice(0, 8)
                        
                        for (var k = 0; k < apps.length; k++) classicOut.push(apps[k])

                        if (t !== "") {
                            classicOut.push({
                                title: "Rechercher '" + t + "' sur le web",
                                description: "Ouvrir dans le navigateur",
                                icon: "internet-web-browser",
                                isWeb: true,
                                query: t
                            })
                        }
                    }

                    if (action === "files")     return win.fileAnswers
                    if (action === "clipboard") return win.clipAnswers
                    return classicOut
                }

                function clickAction(action) {
                    hoveredAction  = ""
                    selectedAction = action
                    actionsShown   = false
                    currentIdx     = 0
                    if (action === "clipboard") clipProc.running = true
                    if (action === "actions") {
                        if (!searchField.text.startsWith(">")) searchField.text = ">"
                    }
                    if (action === "wallpapers") {
                        searchField.text = ">/w"
                    }
                }

                function doClose() {
                    searchField.text = ""
                    actionsShown     = false
                    hoveredAction    = ""
                    selectedAction   = ""
                    currentIdx       = 0
                    fileAnswers      = []
                    wallAnswers      = []
                    clipAnswers      = []
                    root.closeRequested()
                }

                Process {
                    id: findProc
                    property string query: ""
                    command: ["sh", "-c", "find /home -maxdepth 7 -not -path '*/\.*' -iname '*" + findProc.query.replace(/['"]/g, "") + "*' 2>/dev/null | head -20"]
                    stdout: StdioCollector { id: findOut }
                    onExited: {
                        var lines = findOut.text.trim().split("\n")
                        var out = []
                        for (var i = 0; i < lines.length; i++) {
                            var p = lines[i]
                            if (!p || p === "") continue
                            var parts = p.split("/")
                            var name = parts[parts.length - 1]
                            var ext = name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
                            out.push({ name: name, title: name, description: p, icon: ext === "pdf" ? "application-pdf" : ext === "png" || ext === "jpg" || ext === "jpeg" ? "image-x-generic" : ext === "mp4" || ext === "mkv" ? "video-x-generic" : ext === "mp3" || ext === "flac" ? "audio-x-generic" : ext === "" ? "folder" : "text-x-generic", path: p })
                        }
                        win.fileAnswers = out
                    }
                }

                Process {
                    id: wallProc
                    running: root.opened
                    
                    command: ["sh", "-c", "find ~/Pictures/wallpaper -maxdepth 2 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null | head -40"]
                    stdout: StdioCollector { id: wallOut }
                    onExited: {
                        var lines = wallOut.text.trim().split("\n")
                        var out = []
                        for (var i = 0; i < lines.length; i++) {
                            var p = lines[i]
                            if (!p || p === "") continue
                            out.push({ title: p.split("/").pop(), description: "Prefix: >/w | Fond d'écran", path: p, isWallpaper: true })
                        }
                        win.wallAnswers = out
                    }
                }

                Timer {
                    id: findDebounce
                    interval: 300
                    repeat: false
                    onTriggered: {
                        if (win.selectedAction === "files") {
                            if (win.pendingQuery.length < 2) { win.fileAnswers = []; return }
                            findProc.query = win.pendingQuery
                            findProc.running = true
                        }
                    }
                }

                Process {
                    id: clipProc
                    command: ["sh", "-c", "cliphist list 2>/dev/null"]
                    stdout: StdioCollector { id: clipOut }
                    onExited: {
                        var lines = clipOut.text.trim().split("\n")
                        var q = searchField.text.toLowerCase()
                        var out = []
                        for (var i = 0; i < lines.length; i++) {
                            var l = lines[i]
                            if (!l || l === "") continue
                            var tabIdx = l.indexOf("    ")
                            var text = tabIdx >= 0 ? l.substring(tabIdx + 1) : l
                            if (text.trim() === "") continue
                            if (q !== "" && text.toLowerCase().indexOf(q) === -1) continue
                            out.push({ name: text.replace(/\n/g, " ").substring(0, 80), title: text.replace(/\n/g, " ").substring(0, 80), description: "Presse-papier", icon: "edit-paste", clipId: tabIdx >= 0 ? l.substring(0, tabIdx) : l, rawLine: l })
                        }
                        win.clipAnswers = out
                    }
                }

                Timer {
                    id: clipDebounce
                    interval: 150
                    repeat: false
                    onTriggered: clipProc.running = true
                }

                Component.onCompleted: {
                    showAnim.start()
                    searchField.forceActiveFocus()
                }

                SequentialAnimation {
                    id: showAnim
                    ParallelAnimation {
                        PropertyAnimation { target: bgPanel; property: "opacity";  from: 0;   to: 1;   duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 }
                        PropertyAnimation { target: bgPanel; property: "bgScaleX"; from: 1.3; to: 1.0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 }
                    }
                }
                SequentialAnimation {
                    id: hideAnim
                    ParallelAnimation {
                        PropertyAnimation { target: bgPanel; property: "opacity";  from: 1; to: 0;   duration: 200 }
                        PropertyAnimation { target: bgPanel; property: "bgScaleX"; from: 1; to: 1.1; duration: 130 }
                    }
                    ScriptAction { script: win.doClose() }
                }

                MouseArea { anchors.fill: parent; onClicked: hideAnim.start() }

                BoxGlass {
                    id: bgPanel
                    property real bgScaleX: 1.0
                    z: 1; opacity: 0
                    anchors.top:              parent.top
                    anchors.topMargin:        200
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: win.actionsShown ? 340 : 540
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                    implicitHeight: panelCol.implicitHeight + 8
                    radius: 30; color: root.glassColor; rimStrength: 1.7
                    light: "#20ffffff"; lightDir: Qt.vector2d(1, 1); layer.enabled: true
                    transform: Scale { xScale: bgPanel.bgScaleX; origin.x: bgPanel.width / 2 }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked:    mouse.accepted = true
                        onPositionChanged: {
                            if (win.selectedAction !== "") return
                            win.actionsShown  = true
                            win.hoveredAction = ""
                        }

                        ColumnLayout {
                            id:              panelCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 4
                            spacing:         0

                            Item {
                                Layout.fillWidth:       true
                                Layout.preferredHeight: 56

                                VectorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     14
                                    width: 24; height: 24
                                    source: {
                                        var b = Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/")
                                        var t = searchField.text
                                        if (t.startsWith(">")) return b + "spotlight/actions.svg"
                                        if (win.selectedAction === "applications") return b + "spotlight/applications.svg"
                                        if (win.selectedAction === "files")        return b + "spotlight/files.svg"
                                        if (win.selectedAction === "actions")      return b + "spotlight/actions.svg"
                                        if (win.selectedAction === "clipboard")    return b + "spotlight/clipboard.svg"
                                        return b + "search.svg"
                                    }
                                    preferredRendererType: VectorImage.CurveRenderer
                                    layer.enabled: true
                                    layer.effect: MultiEffect { colorization: 1; colorizationColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5) }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     48
                                    anchors.right:          parent.right
                                    anchors.rightMargin:    8
                                    font.family:    sfRoundedMedium.name
                                    font.pixelSize: 26
                                    font.weight:    Font.Medium
                                    color:          root.textColor
                                    opacity:        0.5
                                    renderType:     Text.NativeRendering
                                    visible:        searchField.text === ""
                                    elide:          Text.ElideRight
                                    text: {
                                        if (win.hoveredAction === "" && win.selectedAction === "") return "Spotlight Search"
                                        var act = win.hoveredAction !== "" ? win.hoveredAction : win.selectedAction
                                        if (act === "applications") return "Applications"
                                        if (act === "files")        return "Fichiers"
                                        if (act === "actions")      return "Actions"
                                        if (act === "clipboard")    return "Presse-papier"
                                        return "Spotlight Search"
                                    }
                                }

                                TextField {
                                    id: searchField
                                    anchors.fill:        parent
                                    anchors.leftMargin:  48
                                    anchors.rightMargin: 14
                                    font.family:         sfRoundedMedium.name
                                    font.pixelSize:      26
                                    color:               root.textColor
                                    renderType:          Text.NativeRendering
                                    background:          Item {}
                                    focus:               true

                                    function applyPrefix(p) {
                                        text = p
                                        cursorPosition = p.length
                                    }

                                    onTextChanged: {
                                        var t = text
                                        if (t.startsWith(">")) {
                                            if (win.selectedAction !== "actions") {
                                                win.hoveredAction = ""; win.selectedAction = "actions"; win.actionsShown = false; win.currentIdx = 0
                                            }
                                            return
                                        }
                                        if (t === "") { win.clickAction(""); win.fileAnswers = []; return }
                                        if (win.selectedAction === "" || win.selectedAction === "actions") {
                                            if (t.length > 0) win.clickAction("search")
                                        }
                                        if (win.selectedAction === "files") { win.pendingQuery = t; findDebounce.restart() }
                                        if (win.selectedAction === "clipboard") clipDebounce.restart()
                                    }

                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Escape) { hideAnim.start(); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_1) { win.clickAction("applications"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_2) { win.clickAction("files"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_3) { win.clickAction("actions"); event.accepted = true; return }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_4) { win.clickAction("clipboard"); event.accepted = true; return }
                                        if (event.key === Qt.Key_Down)   { win.currentIdx = Math.min(win.currentIdx+1, Math.max(0, win.answers.length - 1)); event.accepted = true; return }
                                        if (event.key === Qt.Key_Up)     { win.currentIdx = Math.max(win.currentIdx-1, 0); event.accepted = true; return }
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            var current = win.answers[win.currentIdx]
                                            if (current && current.dummy && current.targetPrefix) {
                                                searchField.applyPrefix(current.targetPrefix)
                                            } else {
                                                results.activateIndex(win.currentIdx)
                                            }
                                            event.accepted = true; return
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth:   true
                                Layout.leftMargin:  12
                                Layout.rightMargin: 12
                                height: 1; radius: 1; color: "#40555555"
                                visible: win.answers.length > 0
                            }

                            SpotlightResults {
                                id:               results
                                Layout.fillWidth: true
                                Layout.preferredHeight: win.answers.length > 0 ? Math.min(400, results.implicitHeight + 20) : 0
                                clip:             true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 } }
                                searchText:       searchField.text
                                answers:          win.answers
                                fontFamily:       sfRounded.name
                                fontFamilyMedium: sfRoundedMedium.name
                                currentIdx:       win.currentIdx
                                showWhenEmpty:    win.selectedAction === "clipboard"
                                onHoveredIdx:     function(idx) { win.currentIdx = idx }
                                onItemClicked:    hideAnim.start()
                            }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:0;action:"applications";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/applications.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:1;action:"files";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/files.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a);if(searchField.text.length>=2){win.pendingQuery=searchField.text;findDebounce.restart()}} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:2;action:"actions";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/actions.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a)} }
                    SpotlightActionBtn { anchors.top:parent.top;anchors.topMargin:203;position:3;iconSize:36;action:"clipboard";iconSrc:Qt.resolvedUrl(Quickshell.shellDir+"/assets/icons/spotlight/clipboard.svg");actionsShown:win.actionsShown;isOpen:root.opened;screenW:win.screen.width;glassColor:root.glassColor;textColor:root.textColor;onHovered:function(a){win.hoveredAction=a};onSelected:function(a){win.clickAction(a);clipProc.running=true} }
                }
            }
        }
    }

    component SpotlightActionBtn: Item {
        id: btn
        required property int    position
        required property string action
        required property url    iconSrc
        required property bool   actionsShown
        required property bool   isOpen
        required property color  glassColor
        required property color  textColor
        required property real   screenW
        property int iconSize: 30
        signal hovered(string action)
        signal selected(string action)
        width: 58; height: 58
        x: btn.screenW / 2 + 170 + 10 + (68 * btn.position)
        BoxGlass {
            anchors.fill:parent;radius:30;color:btn.glassColor;rimStrength:0.2
            light:"#20ffffff";lightDir:Qt.vector2d(1,1);layer.enabled:true
            scale:   btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            opacity: btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            VectorImage { anchors.centerIn:parent;width:btn.iconSize;height:btn.iconSize;source:btn.iconSrc;preferredRendererType:VectorImage.CurveRenderer;layer.enabled:true;layer.effect:MultiEffect{colorization:1;colorizationColor:btn.textColor} }
        }
        MouseArea { anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onEntered:btn.hovered(btn.actionsShown&&btn.isOpen?btn.action:"");onExited:btn.hovered("");onClicked:btn.selected(btn.action) }
    }
}
