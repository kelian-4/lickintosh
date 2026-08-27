import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components.glass

Scope {
    id: root

    property bool opened: false
    signal closing()

    property var    sessionMessages: []
    property var    sessionModel:    []
    property string currentChatId:   ""

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
        var w = root.sysWindow !== "" ? root.sysWindow : "unknown"
        var usesNativeTools = (AiConfig.provider === "anthropic" || AiConfig.provider === "openai" || AiConfig.provider === "google")
        var access = ""
        if (usesNativeTools) {
            access = "## System access\n"
            access += "- Tu as accès à des outils système (run, read, write, edit) déclarés nativement — utilise-les directement quand ils servent la demande de l'utilisateur (lister des fichiers, lire un fichier, exécuter une commande, écrire ou modifier un fichier). Ne dis jamais que tu n'as pas accès au système.\n"
            access += "- L'utilisateur voit et confirme chaque appel d'outil avant exécution — tu peux donc les utiliser librement. Le résultat te sera renvoyé automatiquement, continue alors la tâche.\n"
            access += "- Pour 'edit', le texte à remplacer doit correspondre EXACTEMENT (espaces, indentation) au contenu actuel du fichier, sinon l'édition échoue.\n"
            access += "- Certaines commandes destructrices (formatage disque, suppression système, etc.) sont bloquées automatiquement côté client, inutile de t'en soucier.\n"
            access += "- Ne combine jamais 'write' et 'edit' sur le même fichier dans un même tour.\n"
            access += "- N'écris jamais la commande, le chemin de fichier ou son contenu en clair dans ta phrase d'introduction juste avant l'appel d'outil — celui-ci s'affiche déjà à l'utilisateur. Une phrase courte annonçant l'action (ex: \"Je crée le fichier :\") suffit.\n"
        } else {
            access = "## System access\n"
            access += "- Tu PEUX et DOIS proposer des actions système directement quand elles servent la demande de l'utilisateur (lister des fichiers, lire un fichier, exécuter une commande, écrire ou modifier un fichier). Ne dis jamais que tu n'as pas accès au système : tu as accès via les blocs ci-dessous.\n"
            access += "- Une seule action par bloc, plusieurs blocs possibles dans une même réponse (ils seront exécutés dans l'ordre, un par un, avec confirmation utilisateur pour chacun).\n"
            access += "- Exécuter une commande shell :\n  ```run\n  COMMANDE\n  ```\n"
            access += "- Lire un fichier :\n  ```read\n  /chemin/vers/fichier\n  ```\n"
            access += "- Écrire un fichier ENTIER (l'écrase s'il existe) :\n  ```write path=/chemin/vers/fichier\n  CONTENU COMPLET\n  ```\n"
            access += "- Modifier une PARTIE d'un fichier existant (remplacement de texte exact, un ou plusieurs blocs) :\n  ```edit path=/chemin/vers/fichier\n  <<<OLD\n  texte exact actuel\n  ===\n  texte de remplacement\n  >>>\n  ```\n"
            access += "- Le texte dans <<<OLD doit correspondre EXACTEMENT (espaces, indentation) au contenu du fichier, sinon l'édition échoue.\n"
            access += "- L'utilisateur voit et confirme chaque action avant exécution — tu peux donc proposer librement. Le résultat te sera renvoyé automatiquement, continue alors la tâche.\n"
            access += "- Certaines commandes destructrices (formatage disque, suppression système, etc.) sont bloquées automatiquement côté client, inutile de t'en soucier.\n"
            access += "- Ne combine jamais 'write' et 'edit' sur le même fichier dans une seule réponse.\n"
            access += "- N'écris jamais la commande, le chemin de fichier ou son contenu en clair dans ta phrase d'introduction juste avant le bloc — le bloc lui-même suffit, il s'affiche déjà à l'utilisateur. Une phrase courte annonçant l'action (ex: \"Je crée le fichier :\") suffit, sans répéter les détails techniques qui suivent.\n"
        }
        var customSection = AiConfig.systemPrompt.trim().length > 0
            ? "\n\n## Instructions personnalisées\n" + AiConfig.systemPrompt.trim()
            : ""
        return "## Style\n- Use casual tone, don't be formal!\n- Always be brief and to the point, unless asked otherwise\n- Don't repeat the user's question\n- Be approachable: avoid jargon, use analogies\n\n## Context (ignore when irrelevant)\n- You are a helpful sidebar assistant on a " + root.sysDistro + " Linux system\n- Desktop environment: " + root.sysDe + "\n- Current date & time: " + root.sysDatetime + "\n- Focused app: " + w + "\n\n" + access + "\n## Presentation\n- Use **bold** for keywords\n- Split long answers with h2 headers + emoji\n- Prefer bullet points\n- For comparisons: table first, then elaboration\n- Use $$ for LaTeX math" + customSection
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

                property bool loading:      false
                property int    streamingIndex: -1
                property bool   streamAborted: false
                property var    activeXhr: null
                property string streamBuffer:   ""

                readonly property var pendingItem:    tools.current
                readonly property bool pendingVisible: tools.current !== null
                readonly property int  pendingCount:   tools.queue.length
                readonly property bool toolsBusy:      tools.busy

                property bool   slashMenuOpen: false
                property bool   recentsOpen:   false
                property var    slashFiltered: []
                property int    slashSelected: 0

                AiTools {
                    id: tools
                    queueChangedCallback: {}
                    resultCallback: function(output) { win.injectToolResult(output) }
                    blockedCallback: function(cmd, reason) { win.blockedAction(cmd, reason) }
                }

                AiSpeech {
                    id: speech
                    resultCallback: function(text) {
                        inputArea.text = (inputArea.text.length > 0 ? inputArea.text + " " : "") + text
                        inputArea.cursorPosition = inputArea.text.length
                    }
                    errorCallback: function(msg) { win.appendError(msg) }
                }

                function approveCommand() { tools.approveCurrent() }
                function rejectCommand()  { tools.rejectCurrent() }

                function blockedAction(cmd, reason) {
                    var msg = "Commande bloquée : " + cmd + "\nRaison : " + reason
                    if (win.pendingToolCalls.length > 0) {
                        var call = win.pendingToolCalls.shift()
                        win.injectNativeToolResults([{ id: call.id, name: call.name, output: msg + "\n(Ne propose pas d'alternative dangereuse équivalente. Continue autrement si possible.)" }])
                        return
                    }
                    var entry = { role: "tool", content: msg }
                    conversationModel.append(entry)
                    root.sessionModel.push(entry)
                    root.sessionMessages.push({ role: "user", content: "[Action bloquée automatiquement par le système, pas par l'utilisateur]\nCommande refusée : " + cmd + "\nRaison : " + reason + "\nNe propose pas d'alternative dangereuse équivalente. Continue autrement si possible." })
                }

                property var pendingToolCalls: []
                property string pendingToolProvider: ""

                function dispatchCall(msgs) {
                    var p = AiConfig.provider
                    if (p === "ollama") { callOllama(msgs); return }
                    if (p === "anthropic") { callAnthropic(msgs); return }
                    if (p === "google") { callGemini(msgs); return }

                    var cp = win.currentProvider
                    if (cp && cp.format === "anthropic") { callAnthropic(msgs); return }
                    if (cp && cp.format === "gemini") { callGemini(msgs); return }
                    callOpenAICompat(msgs)
                }

                function finalizeStreamWithToolCalls(calls, providerFormat) {
                    win.loading = false
                    var finalContent = win.streamBuffer
                    if (win.streamingIndex === -1 && finalContent !== "") {
                        conversationModel.append({ role: "assistant", content: finalContent })
                    }
                    win.streamBuffer = ""
                    win.streamingIndex = -1
                    win.activeXhr = null

                    var parsedCalls = calls.map(function(c) {
                        var args = {}
                        try { args = c.jsonBuf !== undefined ? JSON.parse(c.jsonBuf || "{}") : (c.args || {}) } catch(e) {}
                        return { id: c.id || "", name: c.name, args: args }
                    })

                    var assistantMsg = { role: "assistant", content: finalContent, nativeToolCalls: parsedCalls, nativeProvider: providerFormat }
                    root.sessionMessages.push(assistantMsg)
                    root.sessionModel.push({ role: "assistant", content: finalContent })

                    win.pendingToolCalls = parsedCalls
                    win.pendingToolProvider = providerFormat

                    var accepted = 0
                    for (var i = 0; i < parsedCalls.length; i++) {
                        if (tools.enqueueFromToolCall(parsedCalls[i].name, parsedCalls[i].args)) accepted++
                    }
                    if (accepted === 0) {
                        win.injectNativeToolResults(parsedCalls.map(function(c) { return { id: c.id, name: c.name, output: "(action bloquée par le système)" } }))
                    }
                }

                function injectToolResult(output) {
                    if (win.pendingToolCalls.length > 0) {
                        var call = win.pendingToolCalls.shift()
                        win.injectNativeToolResults([{ id: call.id, name: call.name, output: output }])
                        return
                    }
                    var entry = { role: "tool", content: "```\n" + output + "\n```" }
                    conversationModel.append(entry)
                    root.sessionModel.push(entry)
                    root.sessionMessages.push({ role: "user", content: "[Tool output]\n" + output + "\n\nPlease continue based on this output." })
                    win.loading = true
                    win.dispatchCall(root.sessionMessages)
                }

                function injectNativeToolResults(results) {
                    var providerFormat = win.pendingToolProvider
                    for (var i = 0; i < results.length; i++) {
                        var entry = { role: "tool", content: "```\n" + results[i].output + "\n```" }
                        conversationModel.append(entry)
                        root.sessionModel.push(entry)
                    }

                    if (providerFormat === "anthropic") {
                        var content = results.map(function(r) {
                            return { type: "tool_result", tool_use_id: r.id, content: r.output }
                        })
                        root.sessionMessages.push({ role: "user", nativeToolResults: content })
                    } else if (providerFormat === "openai") {
                        for (var j = 0; j < results.length; j++) {
                            root.sessionMessages.push({ role: "tool", nativeToolCallId: results[j].id, content: results[j].output })
                        }
                    } else if (providerFormat === "gemini") {
                        var parts = results.map(function(r) {
                            return { functionResponse: { name: r.name, response: { result: r.output } } }
                        })
                        root.sessionMessages.push({ role: "user", nativeFunctionResponses: parts })
                    }

                    if (win.pendingToolCalls.length === 0) {
                        win.pendingToolProvider = ""
                        win.loading = true
                        win.dispatchCall(root.sessionMessages)
                    }
                }

                function parseAndShowActions(content) {
                    tools.parseActions(content)
                }

                function startStreaming() {
                    win.loading = true
                    win.streamBuffer = ""
                    win.streamingIndex = -1
                    win.streamAborted = false
                }

                function abortActiveStream() {
                    win.streamAborted = true
                    if (win.activeXhr) {
                        try { win.activeXhr.abort() } catch(e) {}
                        win.activeXhr = null
                    }
                    win.loading = false
                    win.streamBuffer = ""
                    win.streamingIndex = -1
                    win.pendingToolCalls = []
                    win.pendingToolProvider = ""
                    tools.clearQueue()
                }

                function appendStreamChunk(chunk) {
                    if (win.streamAborted) return
                    win.streamBuffer += chunk
                    if (win.streamingIndex === -1) {
                        conversationModel.append({ role: "assistant", content: win.streamBuffer })
                        win.streamingIndex = conversationModel.count - 1
                    } else if (win.streamingIndex >= 0 && win.streamingIndex < conversationModel.count) {
                        conversationModel.setProperty(win.streamingIndex, "content", win.streamBuffer)
                    } else {
                        win.streamingIndex = -1
                        conversationModel.append({ role: "assistant", content: win.streamBuffer })
                        win.streamingIndex = conversationModel.count - 1
                    }
                    Qt.callLater(function() { chatView.positionViewAtEnd() })
                }

                function finalizeStream() {
                    if (win.streamAborted) return
                    win.loading = false
                    var finalContent = win.streamBuffer
                    if (win.streamingIndex === -1 && finalContent !== "") {
                        conversationModel.append({ role: "assistant", content: finalContent })
                    }
                    root.sessionMessages.push({ role: "assistant", content: finalContent })
                    root.sessionModel.push({ role: "assistant", content: finalContent })
                    win.streamBuffer = ""
                    win.streamingIndex = -1
                    win.activeXhr = null
                    parseAndShowActions(finalContent)
                    win.maybeGenerateTitle()
                }

                function maybeGenerateTitle() {
                    if (root.currentChatId !== "") return
                    if (root.sessionMessages.length < 2) return
                    var firstUser = root.sessionMessages.find(function(m) { return m.role === "user" })
                    if (!firstUser) return

                    var newId = AiChats.saveChat(root.sessionMessages, AiConfig.cloudModel)
                    root.currentChatId = newId

                    win.generateChatTitle(firstUser.content, function(title) {
                        if (title) AiChats.updateChatTitle(newId, title)
                    })
                }

                Component.onCompleted: {
                    for (var i = 0; i < root.sessionModel.length; i++) {
                        conversationModel.append(root.sessionModel[i])
                    }
                    if (conversationModel.count > 0)
                        Qt.callLater(function() { chatView.positionViewAtEnd() })
                    Qt.callLater(function() { inputArea.forceActiveFocus() })
                }

                Component.onDestruction: {
                    if (root.sessionMessages.length > 0) {
                        root.currentChatId = AiChats.saveChat(root.sessionMessages, AiConfig.cloudModel, root.currentChatId || undefined)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closing()
                }

                Item {
                    id: panelViewport
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   37
                    anchors.rightMargin: 10
                    width: 320
                    height: Math.min(panelCol.implicitHeight, parent.height - anchors.topMargin - 10)
                    z: 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                        onPressed:  function(mouse) { mouse.accepted = true }
                    }

                    ScrollView {
                        id: panelScroll
                        anchors.fill: parent
                        contentWidth: panelCol.width
                        contentHeight: panelCol.height
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                        clip: true

                        Column {
                            id: panelCol
                            width:   320
                            spacing: 6

                            opacity: 0
                            Component.onCompleted: fadeIn.start()

                            NumberAnimation {
                                id: fadeIn
                                target:   panelCol
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
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
                                    width: 18
                                    height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/ai.svg")
                                    preferredRendererType: VectorImage.CurveRenderer

                                    SequentialAnimation on opacity {
                                        running: win.loading
                                        loops:   Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0;  duration: 500; easing.type: Easing.InOutSine }
                                    }
                                }

                                Text {
                                    text: "…"
                                    color: "#888"
                                    font.pixelSize: 18
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
                            readonly property bool isTool:     role === "tool"
                            readonly property bool isUser:     role === "user"

                            width:  chatView.width
                            height: bubble.height + 4

                            BoxGlass {
                                id: bubble
                                anchors.right: isUser ? parent.right : undefined
                                anchors.left:  isUser ? undefined : parent.left

                                width: isTool
                                ? parent.width
                                : Math.min(innerText.implicitWidth + 24, maxBubbleW)
                                height: innerText.implicitHeight + 16
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

                                TextEdit {
                                    id: innerText
                                    anchors {
                                        fill: parent
                                        topMargin: 8
                                        bottomMargin: 8
                                        leftMargin: 12
                                        rightMargin: 12
                                    }
                                    width:             maxBubbleW - 24
                                    text:              content
                                    color:             "#FFFFFF"
                                    font.pixelSize:    13
                                    renderType:        Text.NativeRendering
                                    wrapMode:          Text.WrapAtWordBoundaryOrAnywhere
                                    readOnly:          true
                                    selectByMouse:     true
                                    textFormat:        TextEdit.MarkdownText
                                    selectedTextColor: "#FFFFFF"
                                    selectionColor:    "#3B6FCC"
                                }
                            }
                        }
                    }

                    BoxGlass {
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
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: 10
                                leftMargin: 12
                                rightMargin: 12
                            }
                            spacing: 8

                            Row {
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: {
                                        if (!win.pendingItem) return ""
                                        var t = win.pendingItem.type
                                        if (t === "run")   return "Exécuter"
                                        if (t === "read")  return "Lire le fichier"
                                        if (t === "write") return "Écrire (remplace le fichier)"
                                        if (t === "edit")  return "Modifier le fichier"
                                        return t
                                    }
                                    color: "#FFAA44"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }

                                Item { width: parent.width - 140; height: 1 }

                                Text {
                                    visible: win.pendingCount > 1
                                    text: "+" + (win.pendingCount - 1) + " en attente"
                                    color: "#CC8844"
                                    font.pixelSize: 10
                                    renderType: Text.NativeRendering
                                }
                            }

                            Rectangle {
                                visible: win.pendingItem && (win.pendingItem.type === "run" || win.pendingItem.type === "read")
                                width: parent.width
                                height: cmdText.implicitHeight + 12
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.35)

                                Text {
                                    id: cmdText
                                    anchors { fill: parent; margins: 6 }
                                    text: win.pendingItem ? (win.pendingItem.cmd || "") : ""
                                    color: "#FFDD88"
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    renderType: Text.NativeRendering
                                    wrapMode: Text.Wrap
                                }
                            }

                            Column {
                                visible: win.pendingItem && win.pendingItem.type === "write"
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: win.pendingItem ? win.pendingItem.path : ""
                                    color: "#FFDD88"
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    renderType: Text.NativeRendering
                                }
                                Rectangle {
                                    width: parent.width
                                    height: Math.min(writeText.implicitHeight + 12, 200)
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                    clip: true
                                    Flickable {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        contentHeight: writeText.implicitHeight
                                        clip: true
                                        Text {
                                            id: writeText
                                            width: parent.width
                                            text: win.pendingItem ? win.pendingItem.newContent : ""
                                            color: "#88DD88"
                                            font.pixelSize: 11
                                            font.family: "monospace"
                                            renderType: Text.NativeRendering
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }
                            }

                            Column {
                                visible: win.pendingItem && win.pendingItem.type === "edit"
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: win.pendingItem ? win.pendingItem.path : ""
                                    color: "#FFDD88"
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    renderType: Text.NativeRendering
                                }
                                Repeater {
                                    model: win.pendingItem && win.pendingItem.type === "edit" ? win.pendingItem.edits : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: confirmCol.width
                                        height: diffCol.implicitHeight + 12
                                        radius: 8
                                        color: Qt.rgba(0, 0, 0, 0.35)
                                        Column {
                                            id: diffCol
                                            anchors { fill: parent; margins: 6 }
                                            spacing: 3
                                            Text {
                                                width: parent.width
                                                text: "- " + modelData.oldText
                                                color: "#FF8888"
                                                font.pixelSize: 11
                                                font.family: "monospace"
                                                renderType: Text.NativeRendering
                                                wrapMode: Text.Wrap
                                            }
                                            Text {
                                                width: parent.width
                                                text: "+ " + modelData.newText
                                                color: "#88DD88"
                                                font.pixelSize: 11
                                                font.family: "monospace"
                                                renderType: Text.NativeRendering
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 8
                                anchors.right: parent.right

                                Rectangle {
                                    width: 72
                                    height: 28
                                    radius: 14
                                    color: Qt.rgba(1, 1, 1, rejectMa.containsMouse ? 0.18 : 0.10)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "Rejeter"; color: "#CCCCCC"; font.pixelSize: 12; renderType: Text.NativeRendering }
                                    MouseArea { id: rejectMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.rejectCommand() }
                                }

                                Rectangle {
                                    width: 80
                                    height: 28
                                    radius: 14
                                    opacity: win.toolsBusy ? 0.5 : 1.0
                                    color: Qt.rgba(0.9, 0.5, 0.1, approveMa.containsMouse ? 0.75 : 0.55)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: win.toolsBusy ? "…" : "Approuver"
                                        color: "#FFFFFF"; font.pixelSize: 12; font.weight: Font.Medium; renderType: Text.NativeRendering
                                    }
                                    MouseArea {
                                        id: approveMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !win.toolsBusy
                                        onClicked: win.approveCommand()
                                    }
                                }
                            }

                            Item { width: 1; height: 2 }
                        }
                    }

                    SlashMenu {
                        id: slashMenu
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        items: win.slashFiltered
                        selectedIndex: win.slashSelected
                        active: win.slashMenuOpen
                        onItemChosen: function(item) { win.applySlashChoice(item) }
                    }

                    BoxGlass {
                        width:  parent.width
                        height: Math.min(inputArea.implicitHeight + 0, 160)
                        radius: 26
                        color:  Qt.rgba(1, 1, 1, inputArea.activeFocus ? 0.12 : 0.07)
                        light:  Qt.rgba(1, 1, 1, inputArea.activeFocus ? 0.50 : 0.28)
                        lightDir: Qt.vector2d(0.0, -1.0)
                        rimStrength: 0.6

                        RowLayout {
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            spacing: 4

                            Item {
                                Layout.preferredWidth: 34
                                Layout.fillHeight: true

                                VectorImage {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/ai.svg")
                                    preferredRendererType: VectorImage.CurveRenderer
                                }
                            }

                            ScrollView {
                                id: inputScroll
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                                clip: true

                                TextArea {
                                    id: inputArea
                                    width:               inputScroll.width
                                    placeholderText:     win.loading ? "Thinking…" : (speech.recording ? "Écoute…" : "Ask AI… (/ pour les commandes)")
                                    placeholderTextColor: "#555"
                                    color:               "#FFF"
                                    background:          null
                                    font.pixelSize:      13
                                    renderType:          Text.NativeRendering
                                    enabled:             !win.loading
                                    focus:               true
                                    wrapMode:            TextArea.Wrap
                                    padding:             0
                                    topPadding:          16
                                    bottomPadding:       16

                                    onTextChanged: win.updateSlashMenu(text)

                                    Keys.onEscapePressed: {
                                        if (win.slashMenuOpen) { win.slashMenuOpen = false; return }
                                        root.closing()
                                    }
                                    Keys.onUpPressed: function(event) {
                                        if (win.slashMenuOpen) {
                                            win.slashSelected = Math.max(0, win.slashSelected - 1)
                                            event.accepted = true
                                        }
                                    }
                                    Keys.onDownPressed: function(event) {
                                        if (win.slashMenuOpen) {
                                            win.slashSelected = Math.min(win.slashFiltered.length - 1, win.slashSelected + 1)
                                            event.accepted = true
                                        }
                                    }
                                    Keys.onTabPressed: function(event) {
                                        if (win.slashMenuOpen && win.slashFiltered.length > 0) {
                                            win.applySlashChoice(win.slashFiltered[win.slashSelected])
                                            event.accepted = true
                                        }
                                    }
                                    Keys.onReturnPressed: function(event) {
                                        var txt0 = inputArea.text.trim()
                                        if (win.slashMenuOpen && win.slashFiltered.length > 0) {
                                            var sel = win.slashFiltered[win.slashSelected]
                                            if (sel.nonInsertable) { event.accepted = true; return }
                                            if (sel.freeform && AiCommands.isSlashCommand(txt0) && AiCommands.validate(txt0).ok) {
                                                inputArea.text = ""
                                                win.slashMenuOpen = false
                                                win.sendMessage(txt0)
                                                event.accepted = true
                                                return
                                            }
                                            win.applySlashChoice(sel)
                                            event.accepted = true
                                            return
                                        }
                                        if (event.modifiers & Qt.ShiftModifier) {
                                            inputArea.insert(inputArea.cursorPosition, "\n")
                                            event.accepted = true
                                        } else {
                                            if (txt0 === "" || win.loading) { event.accepted = true; return }
                                            if (AiCommands.isSlashCommand(txt0) && !AiCommands.validate(txt0).ok) {
                                                event.accepted = true
                                                return
                                            }
                                            inputArea.text = ""
                                            win.sendMessage(txt0)
                                            event.accepted = true
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 34
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 26; height: 26; radius: 13
                                    color: speech.recording ? Qt.rgba(0.9, 0.2, 0.2, 0.55)
                                         : speech.transcribing ? Qt.rgba(1,1,1, 0.14)
                                         : Qt.rgba(1,1,1, micMa.containsMouse ? 0.14 : 0.07)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    SequentialAnimation on scale {
                                        running: speech.recording
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1.15; duration: 500; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0;  duration: 500; easing.type: Easing.InOutSine }
                                    }
                                    Shape {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        visible: !speech.transcribing
                                        preferredRendererType: Shape.CurveRenderer
                                        ShapePath {
                                            fillColor: speech.recording ? "#FFFFFF" : "#888888"
                                            strokeWidth: -1
                                            PathSvg { path: "M8,0.5 C9.66,0.5 11,1.84 11,3.5 L11,7.5 C11,9.16 9.66,10.5 8,10.5 C6.34,10.5 5,9.16 5,7.5 L5,3.5 C5,1.84 6.34,0.5 8,0.5 Z M3,7 L4,7 C4,9.76 6.24,12 9,11.9 C11.6,11.8 13,9.5 13,7 L14,7 C14,10.14 11.64,12.73 8.6,13.08 L8.6,15 L11,15 L11,16 L5,16 L5,15 L7.4,15 L7.4,13.08 C4.36,12.72 2,10.08 2,7 L3,7 Z" }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: speech.transcribing
                                        text: "…"
                                        color: "#888"
                                        font.pixelSize: 13
                                        renderType: Text.NativeRendering
                                    }
                                    MouseArea {
                                        id: micMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !speech.transcribing
                                        onClicked: speech.recording ? speech.stop() : speech.start()
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        visible: conversationModel.count > 0

                        BoxGlass {
                            width: 68
                            height: 28
                            radius: 14
                            color: Qt.rgba(1, 1, 1, cMa.containsMouse ? 0.14 : 0.07)
                            light: Qt.rgba(1, 1, 1, 0.30)
                            lightDir: Qt.vector2d(0.0, -1.0)
                            rimStrength: 0.5

                            Text { anchors.centerIn: parent; text: "Clear"; color: "#FFFFFF"; font.pixelSize: 12; renderType: Text.NativeRendering }

                            MouseArea {
                                id: cMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.abortActiveStream()
                                    conversationModel.clear()
                                    root.sessionMessages = []
                                    root.sessionModel    = []
                                    root.currentChatId   = ""
                                }
                            }
                        }

                        BoxGlass {
                            width: 78
                            height: 28
                            radius: 14
                            color: Qt.rgba(1, 1, 1, win.recentsOpen ? 0.16 : (rMa.containsMouse ? 0.14 : 0.07))
                            light: Qt.rgba(1, 1, 1, 0.30)
                            lightDir: Qt.vector2d(0.0, -1.0)
                            rimStrength: 0.5

                            Text { anchors.centerIn: parent; text: "Récents"; color: "#FFFFFF"; font.pixelSize: 12; renderType: Text.NativeRendering }

                            MouseArea {
                                id: rMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.recentsOpen = !win.recentsOpen
                            }
                        }
                    }

                    BoxGlass {
                        width: parent.width
                        visible: win.recentsOpen
                        height: visible ? Math.min(recentsCol.implicitHeight + 20, 260) : 0
                        radius: 14
                        color: Qt.rgba(1, 1, 1, 0.05)
                        light: Qt.rgba(1, 1, 1, 0.20)
                        lightDir: Qt.vector2d(0.0, -1.0)
                        rimStrength: 0.5
                        clip: true
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 10
                            contentHeight: recentsCol.implicitHeight
                            clip: true

                            Column {
                                id: recentsCol
                                width: parent.width
                                spacing: 6

                                Text {
                                    visible: AiChats.chats.length === 0
                                    text: "Aucune conversation sauvegardée pour l'instant."
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                    renderType: Text.NativeRendering
                                }

                                Repeater {
                                    model: AiChats.chats
                                    delegate: BoxGlass {
                                        required property var modelData
                                        width: recentsCol.width
                                        height: 44
                                        radius: 12
                                        color: Qt.rgba(1, 1, 1, itemMa.containsMouse ? 0.12 : 0.05)
                                        light: Qt.rgba(1, 1, 1, 0.22)
                                        lightDir: Qt.vector2d(0.0, -1.0)
                                        rimStrength: 0.5

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    text: modelData.title
                                                    color: "#FFFFFF"
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                    renderType: Text.NativeRendering
                                                }
                                                Text {
                                                    text: new Date(modelData.updatedAt).toLocaleDateString() + " — " + modelData.messageCount + " messages"
                                                    color: "#AAAAAA"
                                                    font.pixelSize: 10
                                                    renderType: Text.NativeRendering
                                                }
                                            }

                                            Rectangle {
                                                width: 22; height: 22; radius: 11
                                                color: Qt.rgba(1,1,1, delMa.containsMouse ? 0.20 : 0.10)
                                                Text { anchors.centerIn: parent; text: "×"; color: "#FF8888"; font.pixelSize: 14; renderType: Text.NativeRendering }
                                                MouseArea {
                                                    id: delMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: AiChats.deleteChat(modelData.id)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: itemMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            z: -1
                                            onClicked: {
                                                win.recentsOpen = false
                                                win.handleSlashCommand("/chat load " + modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: conversationModel.count > 0 ? 6 : 0 }
                        }
                    }
                }

                readonly property var cloudProviders: [
                    { id: "anthropic", name: "Anthropic", endpoint: "https://api.anthropic.com/v1/messages",            format: "anthropic" },
                    { id: "openai",    name: "OpenAI",    endpoint: "https://api.openai.com/v1/chat/completions",       format: "openai-compat" },
                    { id: "google",    name: "Google",    endpoint: "https://generativelanguage.googleapis.com/v1beta", format: "gemini" }
                ].concat(AiConfig.customProviders.map(function(p) {
                    return { id: p.id, name: p.id, endpoint: p.endpoint, format: p.format }
                }))

                readonly property var currentProvider: {
                    var pid = AiConfig.provider
                    for (var i = 0; i < cloudProviders.length; i++) {
                        if (cloudProviders[i].id === pid) return cloudProviders[i]
                    }
                    return cloudProviders[0]
                }

                ListModel { id: conversationModel }

                function sendMessage(txt) {

                    if (AiCommands.isSlashCommand(txt)) {
                        win.handleSlashCommand(txt)
                        return
                    }

                    win.loading = true
                    var entry = { role: "user", content: txt }
                    conversationModel.append(entry)

                    root.sessionMessages.push({ role: "user", content: txt })
                    root.sessionModel.push(entry)
                    win.dispatchCall(root.sessionMessages.slice())
                }

                function updateSlashMenu(text) {
                    win.slashMenuOpen = AiCommands.isSlashCommand(text) || text === "/"
                    if (!win.slashMenuOpen) return
                    win.slashFiltered = AiCommands.suggest(text)
                    win.slashSelected = 0
                    Qt.callLater(function() {
                        panelScroll.ScrollBar.vertical.position = 1.0 - panelScroll.ScrollBar.vertical.size
                    })
                }

                function applySlashChoice(item) {
                    if (item.nonInsertable) return
                    if (item.submitNow) {
                        var txt = inputArea.text.trim()
                        inputArea.text = ""
                        win.slashMenuOpen = false
                        win.sendMessage(txt)
                        return
                    }
                    var text = inputArea.text
                    var endsWithSpace = /\s$/.test(text)
                    var lastSpace = text.lastIndexOf(" ")
                    var base = endsWithSpace ? text : text.substring(0, lastSpace + 1)
                    if (base === "") base = "/"

                    if (item.terminal) {
                        inputArea.text = ""
                        win.slashMenuOpen = false
                        win.sendMessage(base + item.value)
                        return
                    }

                    inputArea.text = base + item.value + (item.insertSuffix !== undefined ? item.insertSuffix : " ")
                    inputArea.cursorPosition = inputArea.text.length
                    win.updateSlashMenu(inputArea.text)
                }

                function promptKeyFor(providerId) {
                    inputArea.text = "/key set " + providerId + " "
                    inputArea.cursorPosition = inputArea.text.length
                    win.updateSlashMenu(inputArea.text)
                    inputArea.forceActiveFocus()
                }

                function handleSlashCommand(line) {
                    var v = AiCommands.validate(line)
                    if (!v.ok) {
                        var errEntry = { role: "tool", content: v.error }
                        conversationModel.append(errEntry)
                        root.sessionModel.push(errEntry)
                        return
                    }

                    var cmd = v.cmd
                    var rest = v.rest
                    var out = ""
                    var promptKeyForProvider = ""

                    if (cmd === "help") {
                        out = "Commandes disponibles :\n"
                        for (var i = 0; i < AiCommands.commands.length; i++) {
                            var c = AiCommands.commands[i]
                            out += "/" + c.name + " " + c.args + " — " + c.desc + "\n"
                        }
                    } else if (cmd === "model") {
                        var name = rest.slice(1).join(" ")
                        AiConfig.set("cloudModel", name)
                        out = "Modèle actif : " + AiConfig.cloudModel
                        if (AiCommands.needsKey(AiConfig.provider)) {
                            out += "\n\nAucune clé API pour " + AiConfig.provider + "."
                            promptKeyForProvider = AiConfig.provider
                        }
                    } else if (cmd === "provider") {
                        var pid = rest[1].toLowerCase()
                        AiConfig.set("provider", pid)
                        var models = AiCommands.modelsFor(pid)
                        if (models.length > 0) AiConfig.set("cloudModel", models[0])
                        out = "Provider actif : " + pid + (models.length ? " (modèle : " + AiConfig.cloudModel + ")" : "")

                        if (rest[2] === "key" && rest[3]) {
                            AiConfig.setKey(pid, rest.slice(3).join(" "))
                            out += "\nClé enregistrée."
                        } else if (AiCommands.needsKey(pid)) {
                            out += "\n\nAucune clé API pour " + pid + "."
                            promptKeyForProvider = pid
                        }
                    } else if (cmd === "key") {
                        if (rest[0] === "remove") {
                            AiConfig.removeKey(rest[1].toLowerCase())
                            out = "Clé supprimée pour " + rest[1]
                        } else {
                            AiConfig.setKey(rest[1].toLowerCase(), rest.slice(2).join(" "))
                            out = "Clé enregistrée pour " + rest[1]
                        }
                    } else if (cmd === "add") {
                        var newId       = rest[0]
                        var newEndpoint = rest[1]
                        var newFormat   = rest[2]
                        var newModel    = rest.slice(3).join(" ")
                        AiConfig.addCustomProvider(newId, newEndpoint, newFormat, newModel)
                        out = "Provider ajouté : " + newId + " (" + newFormat + ")\nModèle : " + newModel + "\n\nActive-le avec /provider set " + newId
                    } else if (cmd === "chat") {
                        var sub = rest[0]
                        if (sub === "list") {
                            if (AiChats.chats.length === 0) {
                                out = "Aucune conversation sauvegardée."
                            } else {
                                out = "Conversations sauvegardées :\n"
                                for (var ci = 0; ci < AiChats.chats.length; ci++) {
                                    var c = AiChats.chats[ci]
                                    out += "- " + c.title + "\n"
                                }
                                out += "\nUtilise /chat load pour en ouvrir une."
                            }
                        } else if (sub === "new") {
                            win.abortActiveStream()
                            if (root.sessionMessages.length > 0) {
                                AiChats.saveChat(root.sessionMessages, AiConfig.cloudModel, root.currentChatId || undefined)
                            }
                            conversationModel.clear()
                            root.sessionMessages = []
                            root.sessionModel    = []
                            root.currentChatId   = ""
                            return
                        } else if (sub === "load") {
                            var loadId = rest[1]
                            AiChats.loadChat(loadId, function(data) {
                                if (!data) {
                                    var errEntry2 = { role: "tool", content: "Impossible de charger cette conversation." }
                                    conversationModel.append(errEntry2)
                                    root.sessionModel.push(errEntry2)
                                    return
                                }
                                win.abortActiveStream()
                                conversationModel.clear()
                                root.sessionMessages = data.messages
                                root.sessionModel    = data.messages
                                root.currentChatId   = loadId
                                for (var mi = 0; mi < data.messages.length; mi++) {
                                    conversationModel.append(data.messages[mi])
                                }
                                Qt.callLater(function() { chatView.positionViewAtEnd() })
                            })
                            return
                        } else if (sub === "delete") {
                            var delId = rest[1]
                            AiChats.deleteChat(delId)
                            if (root.currentChatId === delId) root.currentChatId = ""
                            out = "Conversation supprimée."
                        } else if (sub === "clear") {
                            AiChats.clearAllChats()
                            root.currentChatId = ""
                            out = "Tout l'historique des conversations sauvegardées a été supprimé."
                        }
                    } else if (cmd === "clear") {
                        win.abortActiveStream()
                        conversationModel.clear()
                        root.sessionMessages = []
                        root.sessionModel    = []
                        root.currentChatId   = ""
                        return
                    }

                    var sysEntry = { role: "tool", content: out }
                    conversationModel.append(sysEntry)
                    root.sessionModel.push(sysEntry)

                    if (promptKeyForProvider !== "") {
                        Qt.callLater(function() { win.promptKeyFor(promptKeyForProvider) })
                    }
                }

                function appendReply(content) {
                    win.loading = false
                    var entry = { role: "assistant", content: content }
                    conversationModel.append(entry)
                    root.sessionMessages.push({ role: "assistant", content: content })
                    root.sessionModel.push(entry)
                    parseAndShowActions(content)
                }

                function appendError(msg) {
                    win.loading = false
                    var entry = { role: "tool", content: msg }
                    conversationModel.append(entry)
                    root.sessionModel.push(entry)
                }

                function driveSSE(xhr, state, onLine, onDone) {
                    if (xhr.readyState < 3) return
                    var raw = state.carry + xhr.responseText.substring(state.processed)
                    state.processed = xhr.responseText.length
                    var lines = raw.split("\n")
                    state.carry = (xhr.readyState === XMLHttpRequest.DONE) ? "" : lines.pop()
                    for (var i = 0; i < lines.length; i++) {
                        onLine(lines[i].trim())
                    }
                    if (xhr.readyState === XMLHttpRequest.DONE) onDone()
                }

                function friendlyHttpError(providerLabel, status, bodyText) {
                    var reason = ""
                    if (status === 401 || status === 403) reason = "clé API invalide ou refusée"
                    else if (status === 404) reason = "modèle ou endpoint introuvable — vérifie /model set"
                    else if (status === 429) reason = "trop de requêtes envoyées d'un coup, attends un peu avant de réessayer"
                    else if (status === 400) reason = "requête mal formée (souvent : modèle incompatible avec ce provider)"
                    else if (status >= 500) reason = "le serveur de " + providerLabel + " a un problème de son côté, réessaie plus tard"
                    else if (status === 0) reason = "impossible de joindre le serveur (réseau coupé ou domaine bloqué)"
                    else reason = "erreur inattendue"

                    var detail = ""
                    try {
                        var parsed = JSON.parse(bodyText)
                        var msg = (parsed.error && (parsed.error.message || parsed.error)) || parsed.message
                        if (msg && typeof msg === "string") detail = " — " + msg
                    } catch(e) {}

                    return providerLabel + " : " + reason + detail
                }

                function generateChatTitle(firstUserMessage, callback) {
                    var pid = AiConfig.provider
                    var key = AiConfig.getKey(pid)
                    var prompt = "Résume ce message en un titre très court de 3 à 5 mots maximum, sans ponctuation finale, sans guillemets. Réponds uniquement avec le titre, rien d'autre.\n\nMessage : " + firstUserMessage.substring(0, 500)

                    if (key === "" && pid !== "ollama") { callback(null); return }

                    var xhr = new XMLHttpRequest()
                    var cp = win.currentProvider
                    var format = pid === "anthropic" ? "anthropic" : pid === "google" ? "gemini" : pid === "ollama" ? "ollama" : (cp ? cp.format : "openai-compat")

                    if (format === "anthropic") {
                        xhr.open("POST", cp ? cp.endpoint : "https://api.anthropic.com/v1/messages")
                        xhr.setRequestHeader("Content-Type", "application/json")
                        xhr.setRequestHeader("x-api-key", key)
                        xhr.setRequestHeader("anthropic-version", "2023-06-01")
                        xhr.send(JSON.stringify({ model: AiConfig.cloudModel, max_tokens: 20, messages: [{ role: "user", content: prompt }] }))
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState !== XMLHttpRequest.DONE) return
                            try {
                                var obj = JSON.parse(xhr.responseText)
                                var t = obj.content && obj.content[0] && obj.content[0].text
                                callback(t ? t.trim() : null)
                            } catch(e) { callback(null) }
                        }
                    } else if (format === "gemini") {
                        var base = cp ? cp.endpoint : "https://generativelanguage.googleapis.com/v1beta"
                        xhr.open("POST", base + "/models/" + AiConfig.cloudModel + ":generateContent?key=" + key)
                        xhr.setRequestHeader("Content-Type", "application/json")
                        xhr.send(JSON.stringify({ contents: [{ role: "user", parts: [{ text: prompt }] }] }))
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState !== XMLHttpRequest.DONE) return
                            try {
                                var obj = JSON.parse(xhr.responseText)
                                var t = obj.candidates && obj.candidates[0] && obj.candidates[0].content && obj.candidates[0].content.parts && obj.candidates[0].content.parts[0] && obj.candidates[0].content.parts[0].text
                                callback(t ? t.trim() : null)
                            } catch(e) { callback(null) }
                        }
                    } else if (format === "ollama") {
                        xhr.open("POST", AiConfig.ollamaHost + "/api/chat")
                        xhr.setRequestHeader("Content-Type", "application/json")
                        xhr.send(JSON.stringify({ model: AiConfig.ollamaModel, messages: [{ role: "user", content: prompt }], stream: false }))
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState !== XMLHttpRequest.DONE) return
                            try {
                                var obj = JSON.parse(xhr.responseText)
                                var t = obj.message && obj.message.content
                                callback(t ? t.trim() : null)
                            } catch(e) { callback(null) }
                        }
                    } else {
                        xhr.open("POST", cp ? cp.endpoint : "https://api.openai.com/v1/chat/completions")
                        xhr.setRequestHeader("Content-Type", "application/json")
                        xhr.setRequestHeader("Authorization", "Bearer " + key)
                        xhr.send(JSON.stringify({ model: AiConfig.cloudModel, messages: [{ role: "user", content: prompt }], max_tokens: 20 }))
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState !== XMLHttpRequest.DONE) return
                            try {
                                var obj = JSON.parse(xhr.responseText)
                                var t = obj.choices && obj.choices[0] && obj.choices[0].message && obj.choices[0].message.content
                                callback(t ? t.trim() : null)
                            } catch(e) { callback(null) }
                        }
                    }
                }

                function _translateMsgsForAnthropic(msgs) {
                    return msgs.map(function(m) {
                        if (m.nativeToolCalls) {
                            var blocks = []
                            if (m.content) blocks.push({ type: "text", text: m.content })
                            for (var i = 0; i < m.nativeToolCalls.length; i++) {
                                var c = m.nativeToolCalls[i]
                                blocks.push({ type: "tool_use", id: c.id, name: c.name, input: c.args })
                            }
                            return { role: "assistant", content: blocks }
                        }
                        if (m.nativeToolResults) {
                            return { role: "user", content: m.nativeToolResults }
                        }
                        return { role: m.role, content: m.content }
                    })
                }

                function callAnthropic(msgs) {
                    var pid = AiConfig.provider
                    var key = AiConfig.getKey(pid)
                    if (key === "") { appendError("Clé API " + pid + " manquante — /key set " + pid + " <ta clé>"); return }
                    var endpoint = win.currentProvider ? win.currentProvider.endpoint : "https://api.anthropic.com/v1/messages"
                    startStreaming()
                    var xhr = new XMLHttpRequest()
                    win.activeXhr = xhr
                    xhr.open("POST", endpoint)
                    xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.setRequestHeader("x-api-key", key)
                    xhr.setRequestHeader("anthropic-version", "2023-06-01")

                    xhr.send(JSON.stringify({ model: AiConfig.cloudModel, max_tokens: 4096, stream: true, system: root.systemPrompt, messages: win._translateMsgsForAnthropic(msgs), tools: AiToolSchema.forAnthropic() }))
                    var state = { processed: 0, carry: "" }
                    var toolBlocks = {}
                    var stopReason = ""
                    xhr.onreadystatechange = function() {
                        driveSSE(xhr, state, function(line) {
                            if (!line.startsWith("data: ")) return
                            var data = line.substring(6)
                            if (data === "[DONE]") return
                            try {
                                var obj = JSON.parse(data)
                                if (obj.type === "content_block_start" && obj.content_block && obj.content_block.type === "tool_use") {
                                    toolBlocks[obj.index] = { id: obj.content_block.id, name: obj.content_block.name, jsonBuf: "" }
                                }
                                if (obj.type === "content_block_delta" && obj.delta) {
                                    if (obj.delta.type === "text_delta" && obj.delta.text)
                                        appendStreamChunk(obj.delta.text)
                                    if (obj.delta.type === "input_json_delta" && toolBlocks[obj.index])
                                        toolBlocks[obj.index].jsonBuf += obj.delta.partial_json || ""
                                }
                                if (obj.type === "message_delta" && obj.delta && obj.delta.stop_reason)
                                    stopReason = obj.delta.stop_reason
                                if (obj.type === "error" && obj.error)
                                    appendError("Anthropic : " + (obj.error.message || "erreur pendant la génération"))
                            } catch(e) {}
                        }, function() {
                            win.activeXhr = null
                            if (xhr.status !== 200) { appendError(friendlyHttpError(pid, xhr.status, xhr.responseText)); return }
                            var calls = Object.keys(toolBlocks).map(function(k) { return toolBlocks[k] })
                            if (stopReason === "tool_use" && calls.length > 0) {
                                finalizeStreamWithToolCalls(calls, "anthropic")
                            } else {
                                finalizeStream()
                            }
                        })
                    }
                }

                function _translateMsgsForOpenAI(msgs) {
                    return msgs.map(function(m) {
                        if (m.nativeToolCalls) {
                            return {
                                role: "assistant",
                                content: m.content || null,
                                tool_calls: m.nativeToolCalls.map(function(c) {
                                    return { id: c.id, type: "function", function: { name: c.name, arguments: JSON.stringify(c.args) } }
                                })
                            }
                        }
                        if (m.nativeToolCallId !== undefined) {
                            return { role: "tool", tool_call_id: m.nativeToolCallId, content: m.content }
                        }
                        return { role: m.role, content: m.content }
                    })
                }

                function callOpenAICompat(msgs) {
                    var p = AiConfig.provider
                    var key = AiConfig.getKey(p)
                    if (key === "") { appendError("Clé API " + p + " manquante — /key set " + p + " <ta clé>"); return }
                    var endpoint = ""
                    for (var i = 0; i < win.cloudProviders.length; i++) {
                        if (win.cloudProviders[i].id === p) { endpoint = win.cloudProviders[i].endpoint; break }
                    }
                    var useNativeTools = (p === "openai")
                    startStreaming()
                    var xhr = new XMLHttpRequest()
                    win.activeXhr = xhr
                    xhr.open("POST", endpoint)
                    xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.setRequestHeader("Authorization", "Bearer " + key)
                    var translatedMsgs = useNativeTools ? win._translateMsgsForOpenAI(msgs) : msgs
                    var fullMsgs = [{ role: "system", content: root.systemPrompt }].concat(translatedMsgs)
                    var payload = { model: AiConfig.cloudModel, messages: fullMsgs, stream: true }
                    if (useNativeTools) payload.tools = AiToolSchema.forOpenAI()
                    xhr.send(JSON.stringify(payload))
                    var state = { processed: 0, carry: "" }
                    var toolCalls = {}
                    var finishReason = ""
                    xhr.onreadystatechange = function() {
                        driveSSE(xhr, state, function(line) {
                            if (!line.startsWith("data: ")) return
                            var data = line.substring(6)
                            if (data === "[DONE]") return
                            try {
                                var obj = JSON.parse(data)
                                var choice = obj.choices && obj.choices[0]
                                var delta = choice && choice.delta
                                if (delta && delta.content)
                                    appendStreamChunk(delta.content)
                                if (delta && delta.tool_calls) {
                                    for (var ti = 0; ti < delta.tool_calls.length; ti++) {
                                        var tc = delta.tool_calls[ti]
                                        var idx = tc.index
                                        if (!toolCalls[idx]) toolCalls[idx] = { id: "", name: "", jsonBuf: "" }
                                        if (tc.id) toolCalls[idx].id = tc.id
                                        if (tc.function && tc.function.name) toolCalls[idx].name += tc.function.name
                                        if (tc.function && tc.function.arguments) toolCalls[idx].jsonBuf += tc.function.arguments
                                    }
                                }
                                if (choice && choice.finish_reason) finishReason = choice.finish_reason
                            } catch(e) {}
                        }, function() {
                            win.activeXhr = null
                            if (xhr.status !== 200) { appendError(friendlyHttpError(p, xhr.status, xhr.responseText)); return }
                            var calls = Object.keys(toolCalls).map(function(k) { return toolCalls[k] })
                            if (useNativeTools && finishReason === "tool_calls" && calls.length > 0) {
                                finalizeStreamWithToolCalls(calls, "openai")
                            } else {
                                finalizeStream()
                            }
                        })
                    }
                }

                function _translateMsgsForGemini(msgs) {
                    return msgs.map(function(m) {
                        if (m.nativeToolCalls) {
                            var parts = []
                            if (m.content) parts.push({ text: m.content })
                            for (var i = 0; i < m.nativeToolCalls.length; i++) {
                                var c = m.nativeToolCalls[i]
                                parts.push({ functionCall: { name: c.name, args: c.args } })
                            }
                            return { role: "model", parts: parts }
                        }
                        if (m.nativeFunctionResponses) {
                            return { role: "user", parts: m.nativeFunctionResponses }
                        }
                        return { role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] }
                    })
                }

                function callGemini(msgs) {
                    var pid = AiConfig.provider
                    var key = AiConfig.getKey(pid)
                    if (key === "") { appendError("Clé API " + pid + " manquante — /key set " + pid + " <ta clé>"); return }
                    var base = win.currentProvider ? win.currentProvider.endpoint : "https://generativelanguage.googleapis.com/v1beta"
                    var url = base + "/models/" + AiConfig.cloudModel + ":streamGenerateContent?alt=sse&key=" + key
                    var contents = win._translateMsgsForGemini(msgs)
                    startStreaming()
                    var xhr = new XMLHttpRequest()
                    win.activeXhr = xhr
                    xhr.open("POST", url)
                    xhr.setRequestHeader("Content-Type", "application/json")
                    xhr.send(JSON.stringify({
                        contents: contents,
                        systemInstruction: { parts: [{ text: root.systemPrompt }] },
                        tools: AiToolSchema.forGemini()
                    }))
                    var state = { processed: 0, carry: "" }
                    var pendingCalls = []
                    xhr.onreadystatechange = function() {
                        driveSSE(xhr, state, function(line) {
                            if (!line.startsWith("data: ")) return
                            try {
                                var obj = JSON.parse(line.substring(6))
                                var parts = obj.candidates && obj.candidates[0] && obj.candidates[0].content && obj.candidates[0].content.parts
                                if (!parts) return
                                for (var pi = 0; pi < parts.length; pi++) {
                                    if (parts[pi].text) appendStreamChunk(parts[pi].text)
                                    if (parts[pi].functionCall) pendingCalls.push({ name: parts[pi].functionCall.name, args: parts[pi].functionCall.args || {} })
                                }
                            } catch(e) {}
                        }, function() {
                            win.activeXhr = null
                            if (xhr.status !== 200) { appendError(friendlyHttpError(pid, xhr.status, xhr.responseText)); return }
                            if (pendingCalls.length > 0) {
                                finalizeStreamWithToolCalls(pendingCalls, "gemini")
                            } else {
                                finalizeStream()
                            }
                        })
                    }
                }

                function callOllama(msgs) {
                    startStreaming()
                    var xhr = new XMLHttpRequest()
                    win.activeXhr = xhr
                    xhr.open("POST", AiConfig.ollamaHost + "/api/chat")
                    xhr.setRequestHeader("Content-Type", "application/json")
                    var fullMsgs = [{ role: "system", content: root.systemPrompt }].concat(msgs)
                    xhr.send(JSON.stringify({ model: AiConfig.ollamaModel, messages: fullMsgs, stream: true }))
                    var state = { processed: 0, carry: "" }
                    xhr.onreadystatechange = function() {
                        driveSSE(xhr, state, function(line) {
                            if (line === "") return
                            try {
                                var obj = JSON.parse(line)
                                if (obj.message && obj.message.content)
                                    appendStreamChunk(obj.message.content)
                            } catch(e) {}
                        }, function() {
                            win.activeXhr = null
                            if (xhr.status !== 200) appendError("Ollama : impossible de contacter " + AiConfig.ollamaHost + " — vérifie qu'ollama tourne (`ollama serve`)")
                            else finalizeStream()
                        })
                    }
                }
            }
        }
    }
}
