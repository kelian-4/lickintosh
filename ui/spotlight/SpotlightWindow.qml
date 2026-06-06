import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import "../components/glass"

Scope {
    id: root

    property bool opened: false
    signal closeRequested()

    readonly property color glassColor: "#c01e1e1e"
    readonly property color textColor:  "#dfdfdf"

    FontLoader {
        id: sfRounded
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf")
    }
    FontLoader {
        id: sfRoundedMedium
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/fonts/SFPR/SF-Pro-Rounded-Medium.otf")
    }

    readonly property var systemActions: [
        { title: "Lock",   description: "Verrouiller", icon: "system-lock-screen", cmd: "hyprlock"          },
        { title: "Sleep",  description: "Veille",      icon: "system-suspend",     cmd: "systemctl suspend" },
        { title: "Reboot", description: "Redémarrer",  icon: "system-reboot",      cmd: "systemctl reboot"  }
    ]

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: win

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

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.namespace:     "quickshell:spotlight"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; left: true; right: true; bottom: true }

                // ── État ─────────────────────────────────────────────────
                property bool   actionsShown:   false
                property string selectedAction: ""
                property string hoveredAction:  ""
                property string searchText:     ""
                property int    currentIdx:     0

                // ── Answers — bindings déclaratifs réactifs (pattern eqSh) ──
                // Se réévaluent automatiquement quand searchText ou selectedAction change

                property list<var> appAnswers: {
                    var q = win.searchText.toLowerCase()
                    if (q === "") return []
                    var apps = DesktopEntries.applications.values
                    var out  = []
                    for (var i = 0; i < apps.length; i++) {
                        var a = apps[i]
                        if (a.name.toLowerCase().indexOf(q) !== -1) {
                            out.push({
                                title:       a.name,
                                description: "Application",
                                icon:        Quickshell.iconPath(a.icon, true),
                                entry:       a
                            })
                        }
                    }
                    out.sort(function(x, y) {
                        var xi = x.title.toLowerCase().indexOf(q)
                        var yi = y.title.toLowerCase().indexOf(q)
                        return xi !== yi ? xi - yi : x.title.localeCompare(y.title)
                    })
                    return out.slice(0, 8)
                }

                property list<var> actionAnswers: {
                    var q   = win.searchText.toLowerCase().trim()
                    var out = []
                    for (var i = 0; i < root.systemActions.length; i++) {
                        var a = root.systemActions[i]
                        if (q === "" || a.title.toLowerCase().indexOf(q) !== -1)
                            out.push({ title: a.title, description: a.description, icon: "", cmd: a.cmd })
                    }
                    return out
                }

                // answers courants selon la catégorie
                property list<var> answers: {
                    if (selectedAction === "search" || selectedAction === "applications")
                        return appAnswers
                    if (selectedAction === "actions")
                        return actionAnswers
                    return []
                }

                function clickAction(action) {
                    hoveredAction  = ""
                    selectedAction = action
                    actionsShown   = false
                    currentIdx     = 0
                }

                function doClose() {
                    searchInput.text = ""
                    searchText       = ""
                    actionsShown     = false
                    hoveredAction    = ""
                    selectedAction   = ""
                    currentIdx       = 0
                    root.closeRequested()
                }

                function launchResult(d) {
                    if (!d) return
                    if (d.entry)    { d.entry.execute();                              hideAnim.start() }
                    else if (d.cmd) { Quickshell.execDetached(["sh", "-c", d.cmd]);  hideAnim.start() }
                    else if (d.path){ Quickshell.execDetached(["xdg-open", d.path]); hideAnim.start() }
                    else if (d.raw) { clipPaste.rawEntry = d.raw; clipPaste.running = true; hideAnim.start() }
                }

                // Fichiers via find
                property var fileAnswers: []
                property string pendingQuery: ""

                Process {
                    id: findProc
                    property string query: ""
                    command: ["sh", "-c",
                        "find $HOME -maxdepth 6 -not -path '*/.*' -iname '*" +
                        findProc.query.replace(/['"\\]/g, "") + "*' 2>/dev/null | head -15"
                    ]
                    stdout: StdioCollector { id: findOut }
                    onExited: {
                        var lines = findOut.text.trim().split("\n")
                        var out   = []
                        for (var i = 0; i < lines.length; i++) {
                            var p = lines[i]
                            if (!p || p === "") continue
                            var parts = p.split("/")
                            out.push({ title: parts[parts.length-1], description: p, icon: "", path: p })
                        }
                        win.fileAnswers = out
                    }
                }
                Timer {
                    id: findDebounce
                    interval: 350
                    repeat:   false
                    onTriggered: {
                        if (win.pendingQuery.length < 2) { win.fileAnswers = []; return }
                        findProc.query   = win.pendingQuery
                        findProc.running = true
                    }
                }

                // Clipboard
                property var clipAnswers: []
                Process {
                    id: clipProc
                    command: ["sh", "-c", "cliphist list 2>/dev/null | head -30"]
                    stdout: StdioCollector { id: clipOut }
                    onExited: {
                        var lines = clipOut.text.trim().split("\n")
                        var out   = []
                        var q     = win.searchText.toLowerCase()
                        for (var i = 0; i < lines.length; i++) {
                            var l = lines[i]
                            if (!l || l === "") continue
                            var tabIdx = l.indexOf("\t")
                            var text   = tabIdx >= 0 ? l.substring(tabIdx+1) : l
                            if (text.trim() === "") continue
                            if (q !== "" && text.toLowerCase().indexOf(q) === -1) continue
                            out.push({ title: text.replace(/\n/g," ").substring(0,80),
                                       description: "Presse-papier", icon: "", raw: l })
                        }
                        win.clipAnswers = out
                    }
                }
                Timer { id: clipDebounce; interval: 200; repeat: false; onTriggered: clipProc.running = true }

                Process {
                    id: clipPaste
                    property string rawEntry: ""
                    command: ["sh", "-c",
                        "printf '%s' '" + clipPaste.rawEntry.replace(/'/g,"") + "' | cliphist decode | wl-copy"
                    ]
                }

                // ── Animations ───────────────────────────────────────────
                Component.onCompleted: {
                    showAnim.start()
                    searchInput.forceActiveFocus()
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
                        PropertyAnimation { target: bgPanel; property: "opacity";  from: 1;   to: 0;   duration: 200 }
                        PropertyAnimation { target: bgPanel; property: "bgScaleX"; from: 1.0; to: 1.1; duration: 130 }
                    }
                    ScriptAction { script: win.doClose() }
                }

                // ── Click outside ────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent
                    onClicked:    hideAnim.start()
                }

                // ── Panel ─────────────────────────────────────────────────
                BoxGlass {
                    id: bgPanel
                    property real bgScaleX: 1.0

                    z:       1
                    opacity: 0
                    anchors.top:              parent.top
                    anchors.topMargin:        200
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: win.actionsShown ? 340 : 540
                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 }
                    }
                    implicitHeight: panelCol.implicitHeight + 8
                    radius:        30
                    color:         root.glassColor
                    rimStrength:   1.7
                    light:         "#20ffffff"
                    lightDir:      Qt.vector2d(1, 1)
                    layer.enabled: true
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

                            // ── Champ recherche ──────────────────────────
                            Item {
                                Layout.fillWidth:       true
                                Layout.preferredHeight: 56

                                VectorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     14
                                    width:  24; height: 24
                                    source: {
                                        var base = Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/")
                                        if (win.selectedAction === "applications") return base + "spotlight/applications.svg"
                                        if (win.selectedAction === "files")        return base + "spotlight/files.svg"
                                        if (win.selectedAction === "actions")      return base + "spotlight/actions.svg"
                                        if (win.selectedAction === "clipboard")    return base + "spotlight/clipboard.svg"
                                        return base + "search.svg"
                                    }
                                    preferredRendererType: VectorImage.CurveRenderer
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        colorization: 1
                                        colorizationColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
                                    }
                                }

                                // Placeholder
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:    parent.left
                                    anchors.leftMargin: 48
                                    anchors.right:   hintRow.left
                                    anchors.rightMargin: 8
                                    font.family:     sfRoundedMedium.name
                                    font.pixelSize:  26
                                    font.weight:     Font.Medium
                                    color:           root.textColor
                                    opacity:         0.5
                                    renderType:      Text.NativeRendering
                                    visible:         searchInput.text === ""
                                    elide:           Text.ElideRight
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

                                // Hint ⌃N
                                Row {
                                    id: hintRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right:          parent.right
                                    anchors.rightMargin:    14
                                    spacing: 4
                                    visible: win.hoveredAction !== "" && searchInput.text === ""

                                    Rectangle {
                                        width: 24; height: 24; radius: 8; color: "#20ffffff"
                                        Text { anchors.centerIn: parent; text: "⌃"; color: root.textColor; font.pixelSize: 14; font.weight: Font.Bold; renderType: Text.NativeRendering }
                                    }
                                    Rectangle {
                                        width: 24; height: 24; radius: 8; color: "#20ffffff"
                                        Text {
                                            anchors.centerIn: parent; color: root.textColor; font.pixelSize: 14; font.weight: Font.Bold; renderType: Text.NativeRendering
                                            text: { if (win.hoveredAction==="applications") return "1"; if (win.hoveredAction==="files") return "2"; if (win.hoveredAction==="actions") return "3"; if (win.hoveredAction==="clipboard") return "4"; return "" }
                                        }
                                    }
                                }

                                // TextField
                                TextField {
                                    id: searchInput
                                    anchors.fill:        parent
                                    anchors.leftMargin:  48
                                    anchors.rightMargin: 80
                                    font.family:         sfRoundedMedium.name
                                    font.pixelSize:      26
                                    color:               root.textColor
                                    renderType:          Text.NativeRendering
                                    background:          Item {}
                                    focus:               true

                                    // onTextEdited comme eqSh — pas onTextChanged
                                    onTextEdited: {
                                        var t = text

                                        // ">" → mode actions
                                        if (t.length >= 1 && t[0] === ">") {
                                            win.searchText = t.length > 1 ? t.substring(1).trim() : " "
                                            if (win.selectedAction !== "actions") win.clickAction("actions")
                                            return
                                        }

                                        win.searchText = t

                                        if (t === "") {
                                            win.clickAction("")
                                            win.fileAnswers = []
                                            win.clipAnswers = []
                                            return
                                        }

                                        if (win.selectedAction === "") win.clickAction("search")

                                        if (win.selectedAction === "files") {
                                            win.pendingQuery = t; findDebounce.restart()
                                        }
                                        if (win.selectedAction === "clipboard") {
                                            clipDebounce.restart()
                                        }
                                    }

                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Escape) {
                                            hideAnim.start(); event.accepted = true; return
                                        }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_1) {
                                            win.clickAction("applications"); event.accepted = true; return
                                        }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_2) {
                                            win.clickAction("files"); win.pendingQuery = text; findDebounce.restart(); event.accepted = true; return
                                        }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_3) {
                                            win.clickAction("actions"); event.accepted = true; return
                                        }
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_4) {
                                            win.clickAction("clipboard"); clipProc.running = true; event.accepted = true; return
                                        }
                                        if (event.key === Qt.Key_Down) {
                                            win.currentIdx = Math.min(win.currentIdx + 1, win.answers.length - 1)
                                            event.accepted = true; return
                                        }
                                        if (event.key === Qt.Key_Up) {
                                            win.currentIdx = Math.max(win.currentIdx - 1, 0)
                                            event.accepted = true; return
                                        }
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            win.launchResult(win.answers[win.currentIdx])
                                            event.accepted = true; return
                                        }
                                    }
                                }
                            }

                            // Séparateur
                            Rectangle {
                                Layout.fillWidth:   true
                                Layout.leftMargin:  12
                                Layout.rightMargin: 12
                                height:  1; radius: 1
                                color:   "#40555555"
                                visible: win.selectedAction !== "" && resultsCol.implicitHeight > 0
                            }

                            // ── Liste résultats — ScriptModel sur answers (binding réactif) ──
                            Item {
                                Layout.fillWidth: true
                                height: win.selectedAction !== "" && resultsCol.implicitHeight > 0
                                        ? Math.min(360, resultsCol.implicitHeight + 12)
                                        : 0
                                clip: true
                                Behavior on height {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 }
                                }

                                Column {
                                    id:              resultsCol
                                    anchors.top:     parent.top
                                    anchors.left:    parent.left
                                    anchors.right:   parent.right
                                    anchors.margins: 4
                                    spacing:         2

                                    Repeater {
                                        model: ScriptModel {
                                            values: {
                                                var action = win.selectedAction
                                                var q      = win.searchText
                                                if (action === "search" || action === "applications") {
                                                    if (q === "") return []
                                                    var apps = DesktopEntries.applications.values
                                                    var out  = []
                                                    for (var i = 0; i < apps.length; i++) {
                                                        var a = apps[i]
                                                        if (a.name.toLowerCase().indexOf(q.toLowerCase()) !== -1) {
                                                            out.push({
                                                                title:       a.name,
                                                                description: "Application",
                                                                icon:        Quickshell.iconPath(a.icon, true),
                                                                entry:       a
                                                            })
                                                        }
                                                    }
                                                    out.sort(function(x, y) {
                                                        var xi = x.title.toLowerCase().indexOf(q.toLowerCase())
                                                        var yi = y.title.toLowerCase().indexOf(q.toLowerCase())
                                                        return xi !== yi ? xi - yi : x.title.localeCompare(y.title)
                                                    })
                                                    return out.slice(0, 8)
                                                }
                                                if (action === "actions") {
                                                    var sq  = q.toLowerCase().trim()
                                                    var aout = []
                                                    for (var j = 0; j < root.systemActions.length; j++) {
                                                        var sa = root.systemActions[j]
                                                        if (sq === "" || sa.title.toLowerCase().indexOf(sq) !== -1)
                                                            aout.push({ title: sa.title, description: sa.description, icon: "", cmd: sa.cmd })
                                                    }
                                                    return aout
                                                }
                                                return []
                                            }
                                        }
                                        delegate: ResultItem {
                                            required property var modelData
                                            required property int index
                                            width:         resultsCol.width - 8
                                            x:             4
                                            itemData:      modelData
                                            isHighlighted: win.currentIdx === index
                                            onItemClicked: function(d) { win.launchResult(d) }
                                        }
                                    }
                                }
                            }

                        } // ColumnLayout
                    } // MouseArea panel
                } // BoxGlass bgPanel

                // ── ActionButtons ─────────────────────────────────────────
                Item {
                    anchors.fill: parent

                    SpotlightActionBtn {
                        anchors.top: parent.top; anchors.topMargin: 203
                        position: 0; action: "applications"
                        iconSrc:      Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/spotlight/applications.svg")
                        actionsShown: win.actionsShown; isOpen: root.opened
                        screenW:      win.screen.width
                        glassColor:   root.glassColor; textColor: root.textColor
                        onHovered:    function(a) { win.hoveredAction = a }
                        onSelected:   function(a) { win.clickAction(a) }
                    }
                    SpotlightActionBtn {
                        anchors.top: parent.top; anchors.topMargin: 203
                        position: 1; action: "files"
                        iconSrc:      Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/spotlight/files.svg")
                        actionsShown: win.actionsShown; isOpen: root.opened
                        screenW:      win.screen.width
                        glassColor:   root.glassColor; textColor: root.textColor
                        onHovered:    function(a) { win.hoveredAction = a }
                        onSelected:   function(a) { win.clickAction(a); win.pendingQuery = win.searchText; findDebounce.restart() }
                    }
                    SpotlightActionBtn {
                        anchors.top: parent.top; anchors.topMargin: 203
                        position: 2; action: "actions"
                        iconSrc:      Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/spotlight/actions.svg")
                        actionsShown: win.actionsShown; isOpen: root.opened
                        screenW:      win.screen.width
                        glassColor:   root.glassColor; textColor: root.textColor
                        onHovered:    function(a) { win.hoveredAction = a }
                        onSelected:   function(a) { win.clickAction(a) }
                    }
                    SpotlightActionBtn {
                        anchors.top: parent.top; anchors.topMargin: 203
                        position: 3; action: "clipboard"; iconSize: 36
                        iconSrc:      Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/spotlight/clipboard.svg")
                        actionsShown: win.actionsShown; isOpen: root.opened
                        screenW:      win.screen.width
                        glassColor:   root.glassColor; textColor: root.textColor
                        onHovered:    function(a) { win.hoveredAction = a }
                        onSelected:   function(a) { win.clickAction(a); clipProc.running = true }
                    }
                }

            } // PanelWindow
        }
    } // Loader

    // ══════════════════════════════════════════════════════════════════════
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

        width:  58
        height: 58
        x: btn.screenW / 2 + 170 + 10 + (68 * btn.position)

        BoxGlass {
            anchors.fill:  parent
            radius:        30
            color:         btn.glassColor
            rimStrength:   0.2
            light:         "#20ffffff"
            lightDir:      Qt.vector2d(1, 1)
            layer.enabled: true
            scale:   btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            opacity: btn.actionsShown && btn.isOpen ? 1.0 : 0.0
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            VectorImage {
                anchors.centerIn:      parent
                width:                 btn.iconSize
                height:                btn.iconSize
                source:                btn.iconSrc
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled:         true
                layer.effect: MultiEffect { colorization: 1; colorizationColor: btn.textColor }
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onEntered:    btn.hovered(btn.actionsShown && btn.isOpen ? btn.action : "")
            onExited:     btn.hovered("")
            onClicked:    btn.selected(btn.action)
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    component ResultItem: Item {
        id: item
        required property var  itemData
        required property bool isHighlighted
        signal itemClicked(var data)

        height: 50
        property bool hovered: false

        Rectangle {
            anchors.fill: parent
            radius:       12
            color:        item.isHighlighted ? "#50ffffff" : (item.hovered ? "#20ffffff" : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // Fond icône (toujours visible, comme eqSh bgForIcon)
        Rectangle {
            id: iconBg
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     12
            width: 40; height: 40; radius: 10
            color: "#20ffffff"
        }

        Image {
            id: rIcon
            anchors.centerIn: iconBg
            width: 40; height: 40
            source:   item.itemData.icon ? item.itemData.icon : ""
            fillMode: Image.PreserveAspectFit
            smooth:   true
            mipmap:   true
        }

        Text {
            anchors.centerIn: iconBg
            visible:          rIcon.status !== Image.Ready || rIcon.source === ""
            text:             item.itemData.title ? item.itemData.title[0].toUpperCase() : "?"
            color:            "#ffffff"
            font.pixelSize:   18
            font.weight:      Font.Bold
            renderType:       Text.NativeRendering
        }

        Text {
            anchors.top:         parent.top
            anchors.topMargin:   8
            anchors.left:        iconBg.right
            anchors.leftMargin:  10
            anchors.right:       parent.right
            anchors.rightMargin: 12
            text:        item.itemData.title || ""
            color:       "#ffffff"
            font.family: sfRounded.name
            font.pixelSize: 15
            font.weight:    Font.Medium
            renderType:     Text.NativeRendering
            elide:          Text.ElideRight
        }

        Text {
            anchors.bottom:       parent.bottom
            anchors.bottomMargin: 8
            anchors.left:         iconBg.right
            anchors.leftMargin:   10
            anchors.right:        parent.right
            anchors.rightMargin:  12
            visible:     !!item.itemData.description
            text:        item.itemData.description || ""
            color:       "#80ffffff"
            font.family: sfRounded.name
            font.pixelSize: 12
            renderType:     Text.NativeRendering
            elide:          Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onEntered:    item.hovered = true
            onExited:     item.hovered = false
            onClicked:    item.itemClicked(item.itemData)
        }
    }

} // Scope
