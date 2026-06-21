import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.ui.glass

Scope {
    id: root

    property bool opened: false
    signal closing()

    property var sessionMessages: []
    property var sessionModel:    []

    // ── Contexte système ──────────────────────────────────────
    property string sysDistro:   "NixOS"
    property string sysDe:       "Hyprland"
    property string sysDatetime: ""
    property string sysWindow:   ""

    Process {
        command: ["sh", "-c", "date '+%A %d %B %Y, %H:%M'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.sysDatetime = text.trim() }
    }
    Process {
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | grep -o '\"class\":\"[^\"]*\"' | cut -d'\"' -f4 || echo ''"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.sysWindow = text.trim() }
    }

    readonly property string systemPrompt: {
        var win = root.sysWindow !== "" ? root.sysWindow : "unknown"
        return "## Style\n" +
        "- Use casual tone, don't be formal!\n" +
        "- Always be brief and to the point, unless asked otherwise\n" +
        "- Don't repeat the user's question\n" +
        "- Be approachable: avoid domain-specific jargon, use analogies when explaining concepts\n\n" +
        "## Context (ignore when irrelevant)\n" +
        "- You are a helpful sidebar assistant on a " + root.sysDistro + " Linux system\n" +
        "- Desktop environment: " + root.sysDe + "\n" +
        "- Current date & time: " + root.sysDatetime + "\n" +
        "- Focused app: " + win + "\n\n" +
        "## System access\n" +
        "- You CAN suggest shell commands or file reads to help the user\n" +
        "- When you want to run a command, wrap it in a special block EXACTLY like this (one per block):\n" +
        "  ```run\n" +
        "  COMMAND_HERE\n" +
        "  ```\n" +
        "- When you want to read a file, use:\n" +
        "  ```read\n" +
        "  /path/to/file\n" +
        "  ```\n" +
        "- The user will see a confirmation dialog before anything runs\n" +
        "- After approval, the output will be sent back to you automatically\n\n" +
        "## Presentation\n" +
        "- Use **bold** to highlight keywords\n" +
        "- Split long answers into sections with h2 headers + emoji\n" +
        "- Prefer bullet points over paragraphs\n" +
        "- For comparisons: table first, then elaboration\n" +
        "- Use $$ delimiters for LaTeX math"
    }

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: win

                anchors.top:    true
                anchors.right:  true
                anchors.bottom: true
                anchors.left:   true

                WlrLayershell.namespace:     "quickshell:ai"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer:         WlrLayer.Overlay

                color:         "transparent"
                exclusiveZone: -1

                property bool loading:     false
                property bool showConfig:  false
                property var  ollamaModels: []

                // ── Accès système ─────────────────────────────
                // Commande en attente de confirmation
                property string pendingCmd:  ""
                property string pendingType: "" // "run" | "read"
                property bool   pendingVisible: pendingCmd !== ""

                Process {
                    id: execProc
                    command: []
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var out = text.trim()
                            if (out === "") out = "(no output)"
                                win.injectToolResult(out)
                        }
                    }
                    stderr: StdioCollector {
                        onStreamFinished: {
                            if (text.trim() !== "")
                                win.injectToolResult("stderr: " + text.trim())
                        }
                    }
                }

                function approveCommand() {
                    var cmd = win.pendingCmd
                    var type = win.pendingType
                    win.pendingCmd  = ""
                    win.pendingType = ""
                    if (type === "run") {
                        execProc.command = ["sh", "-c", cmd]
                        execProc.running = true
                    } else if (type === "read") {
                        execProc.command = ["sh", "-c", "cat " + cmd.trim() + " 2>&1 | head -200"]
                        execProc.running = true
                    }
                }

                function rejectCommand() {
                    var cmd = win.pendingCmd
                    win.pendingCmd  = ""
                    win.pendingType = ""
                    injectToolResult("(user rejected: " + cmd + ")")
                }

                function injectToolResult(output) {
                    var entry = { role: "tool", content: "```\n" + output + "\n```" }
                    conversationModel.append(entry)
                    root.sessionModel.push(entry)
                    root.sessionMessages.push({ role: "user", content: "[Tool output]\n" + output + "\n\nPlease continue based on this output." })
                    win.loading = true
                    var p = AiConfig.provider
                    if      (p === "ollama")    callOllama(root.sessionMessages)
                        else if (p === "anthropic") callAnthropic(root.sessionMessages)
                            else if (p === "gemini")    callGemini(root.sessionMessages)
                                else                        callOpenAICompat(root.sessionMessages)
                }

                function parseAndShowActions(content) {
                    var runRe  = /```run\s*\n([\s\S]*?)```/
                    var readRe = /```read\s*\n([\s\S]*?)```/
                    var mRun  = runRe.exec(content)
                    var mRead = readRe.exec(content)
                    if (mRun) {
                        win.pendingCmd  = mRun[1].trim()
                        win.pendingType = "run"
                    } else if (mRead) {
                        win.pendingCmd  = mRead[1].trim()
                        win.pendingType = "read"
                    }
                }

                Component.onCompleted: {
                    for (var i = 0; i < root.sessionModel.length; i++) {
                        conversationModel.append(root.sessionModel[i])
                    }
                    if (conversationModel.count > 0)
                        Qt.callLater(function() { chatView.positionViewAtEnd() })
                }

                Process {
                    id: _ollamaList
                    command: ["sh", "-c", "ollama list 2>/dev/null | tail -n +2 | awk '{print $1}'"]
                    running: false
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var lines = text.trim().split("\n").filter(function(l) { return l !== "" })
                            win.ollamaModels = lines
                            if (lines.length > 0 && AiConfig.ollamaModel === "")
                                AiConfig.set("ollamaModel", lines[0])
                        }
                    }
                }
                Timer { interval: 120; running: true; repeat: false; onTriggered: _ollamaList.running = true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closing()
                }

                Column {
                    id: panelCol
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   37
                    anchors.rightMargin: 10
                    width:   320
                    spacing: 6
                    z: 1

                    opacity: 0
                    Component.onCompleted: fadeIn.start()
                    NumberAnimation {
                        id: fadeIn; target: panelCol; property: "opacity"
                        from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic
                    }

                    ListView {
                        id: chatView
                        width:   parent.width
                        height:  contentHeight > 0 ? Math.min(contentHeight, 420) : 0
                        visible: height > 0
                        model:   conversationModel
                        spacing: 6
                        clip:    true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        footer: Item {
                            width:  chatView.width
                            height: win.loading ? 40 : 0
                            visible: win.loading

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                VectorImage {
                                    width: 18; height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/ai.svg")
                                    preferredRendererType: VectorImage.CurveRenderer
                                    SequentialAnimation on opacity {
                                        running: win.loading; loops: Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0;  duration: 500; easing.type: Easing.InOutSine }
                                    }
                                }
                                Text {
                                    text: "…"; color: "#888"; font.pixelSize: 18
                                    renderType: Text.NativeRendering
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        onCountChanged: Qt.callLater(function() { chatView.positionViewAtEnd() })

                        delegate: Item {
                            required property string role
                            required property string content

                            readonly property int  maxBubbleW: Math.floor(chatView.width * 0.80)
                            readonly property bool isTool:  role === "tool"
                            readonly property bool isUser:  role === "user"

                            width:  chatView.width
                            height: bubble.height + 4

                            BoxGlass {
                                id: bubble
                                anchors.right: isUser ? parent.right : undefined
                                anchors.left:  isUser ? undefined    : parent.left

                                width:  isTool
                                ? parent.width
                                : Math.min(innerText.implicitWidth + 24, maxBubbleW)
                                height: Math.min(innerText.implicitHeight + 16, 300)
                                radius: 14

                                color: isUser
                                ? Qt.rgba(0.15, 0.38, 0.90, 0.45)
                                : isTool
                                ? Qt.rgba(1, 1, 1, 0.03)
                                : Qt.rgba(1, 1, 1, 0.07)
                                light: isUser
                                ? Qt.rgba(0.5, 0.75, 1.0, 0.55)
                                : Qt.rgba(1, 1, 1, 0.25)
                                lightDir: isUser
                                ? Qt.vector2d(-1.0, -1.0)
                                : Qt.vector2d(1.0, -1.0)
                                rimStrength: 0.7

                                ScrollView {
                                    anchors { fill: parent; topMargin: 8; bottomMargin: 8; leftMargin: 12; rightMargin: 12 }
                                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                    ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                                    clip: true

                                    TextEdit {
                                        id: innerText
                                        width:       maxBubbleW - 24
                                        height:      implicitHeight
                                        text:        content
                                        color:       isTool ? "#888888" : "#FFFFFF"
                                        font.pixelSize:  13
                                        renderType:      Text.NativeRendering
                                        wrapMode:        Text.Wrap
                                        readOnly:        true
                                        selectByMouse:   true
                                        textFormat:      TextEdit.MarkdownText
                                        selectedTextColor: "#FFFFFF"
                                        selectionColor:    "#3B6FCC"
                                    }
                                }
                            }
                        }
                    }

                    // ── Confirmation accès système ─────────────
                    BoxGlass {
                        id: confirmBox
                        width:   parent.width
                        height:  win.pendingVisible ? confirmCol.implicitHeight + 20 : 0
                        visible: win.pendingVisible
                        radius:  14
                        color:   Qt.rgba(0.8, 0.4, 0.1, 0.18)
                        light:   Qt.rgba(1.0, 0.7, 0.3, 0.45)
                        lightDir: Qt.vector2d(0.0, -1.0)
                        rimStrength: 0.7
                        clip: true
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Column {
                            id: confirmCol
                            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 12; rightMargin: 12 }
                            spacing: 8

                            Row {
                                spacing: 6
                                Text {
                                    text: win.pendingType === "run" ? "⚡ Exécuter" : "📄 Lire le fichier"
                                    color: "#FFAA44"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: cmdText.implicitHeight + 12
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.35)

                                Text {
                                    id: cmdText
                                    anchors { fill: parent; margins: 6 }
                                    text: win.pendingCmd
                                    color: "#FFDD88"
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    renderType: Text.NativeRendering
                                    wrapMode: Text.Wrap
                                }
                            }

                            Row {
                                spacing: 8
                                anchors.right: parent.right

                                // Rejeter
                                Rectangle {
                                    width: 72; height: 28; radius: 14
                                    color: Qt.rgba(1, 1, 1, rejectMa.containsMouse ? 0.18 : 0.10)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "Rejeter"; color: "#CCCCCC"; font.pixelSize: 12; renderType: Text.NativeRendering }
                                    MouseArea { id: rejectMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.rejectCommand() }
                                }

                                // Approuver
                                Rectangle {
                                    width: 80; height: 28; radius: 14
                                    color: Qt.rgba(0.9, 0.5, 0.1, approveMa.containsMouse ? 0.75 : 0.55)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "Approuver"; color: "#FFFFFF"; font.pixelSize: 12; font.weight: Font.Medium; renderType: Text.NativeRendering }
                                    MouseArea { id: approveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.approveCommand() }
                                }
                            }

                            Item { width: 1; height: 2 }
                        }
                    }

                    // ── Config panel ──────────────────────────
                    BoxGlass {
                        width:   parent.width
                        height:  win.showConfig ? Math.min(cfgInner.implicitHeight + 24, 480) : 0
                        radius:  14
                        color:   Qt.rgba(1, 1, 1, 0.07)
                        light:   Qt.rgba(1, 1, 1, 0.28)
                        lightDir: Qt.vector2d(0.5, -1.0)
                        rimStrength: 0.5
                        clip:    true
                        visible: win.showConfig
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        ScrollView {
                            anchors.fill: parent
                            contentWidth: parent.width
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                            clip: true

                            Column {
                                id: cfgInner
                                width: 320
                                spacing: 10
                                topPadding: 12; bottomPadding: 12
                                leftPadding: 12; rightPadding: 12

                                Row {
                                    width: parent.width - 24; spacing: 6
                                    Repeater {
                                        model: ["Cloud", "Local"]
                                        delegate: Rectangle {
                                            required property string modelData
                                            required property int    index
                                            readonly property bool active: index === 0 ? AiConfig.provider !== "ollama" : AiConfig.provider === "ollama"
                                            width: (parent.width - 6) / 2; height: 28; radius: 9
                                            color: active ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,mTa.containsMouse ? 0.09 : 0.05)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text { anchors.centerIn: parent; text: parent.modelData; color: parent.active ? "#FFF" : "#888"; font.pixelSize: 12; font.weight: parent.active ? Font.Medium : Font.Normal; renderType: Text.NativeRendering }
                                            MouseArea {
                                                id: mTa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (index === 0) { AiConfig.set("provider", "anthropic"); AiConfig.set("cloudModel", "claude-sonnet-4-6") }
                                                    else             { AiConfig.set("provider", "ollama") }
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width - 24; spacing: 8
                                    visible: AiConfig.provider !== "ollama"

                                    Text { text: "Service"; color: "#666"; font.pixelSize: 10; renderType: Text.NativeRendering }
                                    Column {
                                        width: parent.width; spacing: 3
                                        Repeater {
                                            model: win.cloudProviders
                                            delegate: Rectangle {
                                                required property var  modelData
                                                required property int  index
                                                readonly property bool sel: AiConfig.provider === modelData.id
                                                width: parent.width; height: 30; radius: 8
                                                color: sel ? Qt.rgba(1,1,1,0.16) : Qt.rgba(1,1,1,pMa.containsMouse ? 0.08 : 0.04)
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData.name; color: parent.sel ? "#FFF" : "#AAA"; font.pixelSize: 12; renderType: Text.NativeRendering }
                                                Rectangle { visible: parent.sel; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } width: 6; height: 6; radius: 3; color: "#7DD3FC" }
                                                MouseArea {
                                                    id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { AiConfig.set("provider", modelData.id); if (modelData.models && modelData.models.length > 0) AiConfig.set("cloudModel", modelData.models[0].id) }
                                                }
                                            }
                                        }
                                    }

                                    Text { text: "API Key — " + (win.currentProvider ? win.currentProvider.name : ""); color: "#666"; font.pixelSize: 10; renderType: Text.NativeRendering }
                                    Rectangle {
                                        width: parent.width; height: 30; radius: 8; color: Qt.rgba(1,1,1,0.06)
                                        border.color: Qt.rgba(1,1,1, apiField.activeFocus ? 0.25 : 0.08); border.width: 1
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        TextField {
                                            id: apiField; anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            echoMode: TextInput.Password; text: AiConfig.getKey(AiConfig.provider); placeholderText: "clé API…"
                                            color: "#FFF"; placeholderTextColor: "#444"; background: null; font.pixelSize: 12; renderType: Text.NativeRendering
                                            onEditingFinished: AiConfig.setKey(AiConfig.provider, text)
                                        }
                                    }

                                    Text { text: "Modèle"; color: "#666"; font.pixelSize: 10; renderType: Text.NativeRendering }
                                    Column {
                                        width: parent.width; spacing: 3
                                        Repeater {
                                            model: win.currentProvider ? win.currentProvider.models : []
                                            delegate: Rectangle {
                                                required property var  modelData
                                                required property int  index
                                                readonly property bool sel: AiConfig.cloudModel === modelData.id
                                                width: parent.width; height: 30; radius: 8
                                                color: sel ? Qt.rgba(1,1,1,0.16) : Qt.rgba(1,1,1,mdMa.containsMouse ? 0.08 : 0.04)
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData.label; color: parent.sel ? "#FFF" : "#AAA"; font.pixelSize: 12; renderType: Text.NativeRendering; elide: Text.ElideRight; width: parent.width - 28 }
                                                Rectangle { visible: parent.sel; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } width: 6; height: 6; radius: 3; color: "#7DD3FC" }
                                                MouseArea { id: mdMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AiConfig.set("cloudModel", modelData.id) }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width - 24; spacing: 8
                                    visible: AiConfig.provider === "ollama"

                                    Text { text: "Host"; color: "#666"; font.pixelSize: 10; renderType: Text.NativeRendering }
                                    Rectangle {
                                        width: parent.width; height: 30; radius: 8; color: Qt.rgba(1,1,1,0.06)
                                        border.color: Qt.rgba(1,1,1, hField.activeFocus ? 0.25 : 0.08); border.width: 1
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        TextField {
                                            id: hField; anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            text: AiConfig.ollamaHost; color: "#FFF"; background: null; font.pixelSize: 12; renderType: Text.NativeRendering
                                            onEditingFinished: { AiConfig.set("ollamaHost", text); _ollamaList.running = true }
                                        }
                                    }

                                    Row {
                                        width: parent.width; spacing: 6
                                        Text { text: "Modèles détectés"; color: "#666"; font.pixelSize: 10; renderType: Text.NativeRendering; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: Qt.rgba(1,1,1, rMa.containsMouse ? 0.14 : 0.07); anchors.verticalCenter: parent.verticalCenter
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text { anchors.centerIn: parent; text: "↻"; color: "#888"; font.pixelSize: 11; renderType: Text.NativeRendering }
                                            MouseArea { id: rMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: _ollamaList.running = true }
                                        }
                                    }
                                    Column {
                                        width: parent.width; spacing: 3
                                        visible: win.ollamaModels.length > 0
                                        Repeater {
                                            model: win.ollamaModels
                                            delegate: Rectangle {
                                                required property string modelData
                                                readonly property bool sel: AiConfig.ollamaModel === modelData
                                                width: parent.width; height: 30; radius: 8
                                                color: sel ? Qt.rgba(1,1,1,0.16) : Qt.rgba(1,1,1,omMa.containsMouse ? 0.08 : 0.04)
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData; color: parent.sel ? "#FFF" : "#AAA"; font.pixelSize: 12; renderType: Text.NativeRendering; elide: Text.ElideRight; width: parent.width - 28 }
                                                Rectangle { visible: parent.sel; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } width: 6; height: 6; radius: 3; color: "#7DD3FC" }
                                                MouseArea { id: omMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AiConfig.set("ollamaModel", modelData) }
                                            }
                                        }
                                    }
                                    Text { visible: win.ollamaModels.length === 0; text: "Aucun modèle — ollama installé ?"; color: "#555"; font.pixelSize: 11; renderType: Text.NativeRendering }
                                }
                            }
                        }
                    }

                    // ── Input — ScrollView multilignes ────────
                    BoxGlass {
                        id: inputBox
                        width: parent.width
                        height: Math.min(inputArea.implicitHeight + 20, 160)
                        radius: 16
                        color: Qt.rgba(1, 1, 1, inputArea.activeFocus ? 0.12 : 0.07)
                        light: Qt.rgba(1, 1, 1, inputArea.activeFocus ? 0.50 : 0.28)
                        lightDir: Qt.vector2d(0.0, -1.0)
                        rimStrength: 0.6

                        Row {
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            spacing: 0

                            Item {
                                width: 34; height: parent.height
                                VectorImage {
                                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 11 }
                                    width: 22; height: 22
                                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/ai.svg")
                                    preferredRendererType: VectorImage.CurveRenderer
                                }
                            }

                            ScrollView {
                                width: parent.width - 34 - 34 - 4
                                height: parent.height
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                                clip: true

                                TextArea {
                                    id: inputArea
                                    width: parent.width
                                    placeholderText: win.loading ? "Thinking…" : "Ask AI…"
                                    placeholderTextColor: "#555"
                                    color: "#FFF"
                                    background: null
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                    enabled: !win.loading
                                    focus: true
                                    wrapMode: TextArea.Wrap
                                    padding: 10
                                    topPadding: 12

                                    Keys.onEscapePressed: root.closing()
                                    Keys.onReturnPressed: function(event) {
                                        if (event.modifiers & Qt.ShiftModifier) {
                                            // Shift+Enter = nouvelle ligne
                                            inputArea.insert(inputArea.cursorPosition, "\n")
                                            event.accepted = true
                                        } else {
                                            var txt = inputArea.text.trim()
                                            if (txt !== "" && !win.loading) {
                                                inputArea.text = ""
                                                win.sendMessage(txt)
                                            }
                                            event.accepted = true
                                        }
                                    }
                                }
                            }

                            Item {
                                width: 34; height: parent.height
                                Rectangle {
                                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 9 }
                                    width: 26; height: 26; radius: 13
                                    color: Qt.rgba(1,1,1, sMa.containsMouse ? 0.14 : 0.07)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "⚙"; color: win.showConfig ? "#FFF" : "#888"; font.pixelSize: 13; renderType: Text.NativeRendering }
                                    MouseArea { id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.showConfig = !win.showConfig }
                                }
                            }
                        }
                    }

                    // Hint Shift+Enter
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Shift+Enter pour nouvelle ligne"
                        color: "#444"; font.pixelSize: 10
                        renderType: Text.NativeRendering
                        visible: inputArea.text.length > 0
                    }

                    // ── Clear ─────────────────────────────────
                    BoxGlass {
                        width: 68; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Qt.rgba(1, 1, 1, cMa.containsMouse ? 0.14 : 0.07)
                        light: Qt.rgba(1, 1, 1, 0.30); lightDir: Qt.vector2d(0.0, -1.0); rimStrength: 0.5
                        visible: conversationModel.count > 0
                        Text { anchors.centerIn: parent; text: "Clear"; color: "#CCC"; font.pixelSize: 12; renderType: Text.NativeRendering }
                        MouseArea {
                            id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { conversationModel.clear(); root.sessionMessages = []; root.sessionModel = [] }
                        }
                    }

                    Item { width: 1; height: conversationModel.count > 0 ? 6 : 0 }
                }

                // ── Providers ─────────────────────────────────
                readonly property var cloudProviders: [
                    { id: "anthropic", name: "Anthropic", endpoint: "https://api.anthropic.com/v1/messages", format: "anthropic",
                        models: [ { id: "claude-opus-4-8", label: "Claude Opus 4.8" }, { id: "claude-opus-4-7", label: "Claude Opus 4.7" }, { id: "claude-sonnet-4-6", label: "Claude Sonnet 4.6" }, { id: "claude-haiku-4-5-20251001", label: "Claude Haiku 4.5" } ] },
                        { id: "openai", name: "OpenAI", endpoint: "https://api.openai.com/v1/chat/completions", format: "openai-compat",
                            models: [ { id: "gpt-4.1", label: "GPT-4.1" }, { id: "gpt-4o", label: "GPT-4o" }, { id: "gpt-4o-mini", label: "GPT-4o Mini" }, { id: "o3", label: "o3" }, { id: "o4-mini", label: "o4 Mini" } ] },
                            { id: "gemini", name: "Google Gemini", endpoint: "https://generativelanguage.googleapis.com/v1beta", format: "gemini",
                                models: [ { id: "gemini-2.5-pro", label: "Gemini 2.5 Pro" }, { id: "gemini-2.5-flash", label: "Gemini 2.5 Flash" }, { id: "gemini-2.0-flash", label: "Gemini 2.0 Flash" } ] },
                                { id: "groq", name: "Groq", endpoint: "https://api.groq.com/openai/v1/chat/completions", format: "openai-compat",
                                    models: [ { id: "llama-3.3-70b-versatile", label: "Llama 3.3 70B" }, { id: "llama4-scout-17b-16e-instruct", label: "Llama 4 Scout" }, { id: "llama4-maverick-17b-128e-instruct", label: "Llama 4 Maverick" }, { id: "deepseek-r1-distill-llama-70b", label: "DeepSeek R1 70B" } ] },
                                    { id: "mistral", name: "Mistral", endpoint: "https://api.mistral.ai/v1/chat/completions", format: "openai-compat",
                                        models: [ { id: "mistral-large-latest", label: "Mistral Large" }, { id: "mistral-small-latest", label: "Mistral Small" }, { id: "codestral-latest", label: "Codestral" } ] },
                                        { id: "deepseek", name: "DeepSeek", endpoint: "https://api.deepseek.com/v1/chat/completions", format: "openai-compat",
                                            models: [ { id: "deepseek-chat", label: "DeepSeek V4" }, { id: "deepseek-reasoner", label: "DeepSeek R1" } ] },
                                            { id: "openrouter", name: "OpenRouter", endpoint: "https://openrouter.ai/api/v1/chat/completions", format: "openai-compat",
                                                models: [ { id: "meta-llama/llama-3.3-70b-instruct:free", label: "Llama 3.3 70B (free)" }, { id: "deepseek/deepseek-r1:free", label: "DeepSeek R1 (free)" }, { id: "google/gemini-2.5-pro", label: "Gemini 2.5 Pro" }, { id: "anthropic/claude-sonnet-4-6", label: "Claude Sonnet 4.6" } ] }
                ]
                readonly property var currentProvider: {
                    var pid = AiConfig.provider
                    for (var i = 0; i < cloudProviders.length; i++) { if (cloudProviders[i].id === pid) return cloudProviders[i] }
                    return cloudProviders[0]
                }

                ListModel { id: conversationModel }

                function sendMessage(txt) {
                    win.loading = true
                    var entry = { role: "user", content: txt }
                    conversationModel.append(entry)
                    // Premier message : injecter le system prompt
                    var msgs
                    if (root.sessionMessages.length === 0) {
                        msgs = [{ role: "user", content: root.systemPrompt + "\n\n---\n\n" + txt }]
                    } else {
                        msgs = root.sessionMessages.concat([{ role: "user", content: txt }])
                    }
                    root.sessionMessages.push({ role: "user", content: txt })
                    root.sessionModel.push(entry)
                    var p = AiConfig.provider
                    if      (p === "ollama")    callOllama(msgs)
                        else if (p === "anthropic") callAnthropic(msgs)
                            else if (p === "gemini")    callGemini(msgs)
                                else                        callOpenAICompat(msgs)
                }

                function appendReply(content) {
                    win.loading = false
                    var entry = { role: "assistant", content: content }
                    conversationModel.append(entry)
                    root.sessionMessages.push({ role: "assistant", content: content })
                    root.sessionModel.push(entry)
                    // Détecter les blocs run/read dans la réponse
                    win.parseAndShowActions(content)
                }

                function appendError(msg) {
                    win.loading = false
                    var entry = { role: "tool", content: "⚠️ " + msg }
                    conversationModel.append(entry)
                    root.sessionModel.push(entry)
                }

                function callAnthropic(msgs) {
                    var key = AiConfig.getKey("anthropic")
                    if (key === "") { appendError("Clé API Anthropic manquante"); return }
                    var xhr = new XMLHttpRequest()
                    xhr.open("POST", "https://api.anthropic.com/v1/messages")
                    xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.setRequestHeader("x-api-key", key)
                    xhr.setRequestHeader("anthropic-version", "2023-06-01")
                    xhr.send(JSON.stringify({ model: AiConfig.cloudModel, max_tokens: 2048, messages: msgs }))
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState !== XMLHttpRequest.DONE) return
                            if (xhr.status === 200) { try { appendReply(JSON.parse(xhr.responseText).content[0].text) } catch(e) { appendError("Parse error") } }
                            else { appendError("Anthropic " + xhr.status + ": " + xhr.responseText.substring(0,120)) }
                    }
                }

                function callOpenAICompat(msgs) {
                    var p = AiConfig.provider; var key = AiConfig.getKey(p)
                    if (key === "") { appendError("Clé API " + p + " manquante"); return }
                    var endpoint = ""
                    for (var i = 0; i < win.cloudProviders.length; i++) { if (win.cloudProviders[i].id === p) { endpoint = win.cloudProviders[i].endpoint; break } }
                    var xhr = new XMLHttpRequest()
                    xhr.open("POST", endpoint); xhr.setRequestHeader("Content-Type", "application/json"); xhr.setRequestHeader("Authorization", "Bearer " + key)
                    xhr.send(JSON.stringify({ model: AiConfig.cloudModel, messages: msgs }))
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState !== XMLHttpRequest.DONE) return
                            if (xhr.status === 200) { try { appendReply(JSON.parse(xhr.responseText).choices[0].message.content) } catch(e) { appendError("Parse error") } }
                            else { appendError(p + " " + xhr.status + ": " + xhr.responseText.substring(0,120)) }
                    }
                }

                function callGemini(msgs) {
                    var key = AiConfig.getKey("gemini")
                    if (key === "") { appendError("Clé API Gemini manquante"); return }
                    var url = "https://generativelanguage.googleapis.com/v1beta/models/" + AiConfig.cloudModel + ":generateContent?key=" + key
                    var contents = msgs.map(function(m) { return { role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] } })
                    var xhr = new XMLHttpRequest()
                    xhr.open("POST", url); xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.send(JSON.stringify({ contents: contents }))
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState !== XMLHttpRequest.DONE) return
                            if (xhr.status === 200) { try { appendReply(JSON.parse(xhr.responseText).candidates[0].content.parts[0].text) } catch(e) { appendError("Parse error Gemini") } }
                            else { appendError("Gemini " + xhr.status + ": " + xhr.responseText.substring(0,120)) }
                    }
                }

                function callOllama(msgs) {
                    var xhr = new XMLHttpRequest()
                    xhr.open("POST", AiConfig.ollamaHost + "/api/chat"); xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.send(JSON.stringify({ model: AiConfig.ollamaModel, messages: msgs, stream: false }))
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState !== XMLHttpRequest.DONE) return
                            if (xhr.status === 200) { try { appendReply(JSON.parse(xhr.responseText).message.content) } catch(e) { appendError("Parse error Ollama") } }
                            else { appendError("Ollama inaccessible (" + AiConfig.ollamaHost + ")") }
                    }
                }
            }
        }
    }
}
