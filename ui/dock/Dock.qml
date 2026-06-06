import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: dockRoot

    readonly property int  baseIconSize: 54
    readonly property int  dockPadH:     14
    readonly property int  dockPadV:     10
    readonly property int  dockHeight:   baseIconSize + dockPadV * 2 + 12
    readonly property int  dockRadius:   22
    readonly property int  iconSpacing:  8
    readonly property real magScale1:    1.50
    readonly property real magScale2:    1.25
    readonly property real magScale3:    1.08
    readonly property int  hoverRegionH: 4

    property bool pinned:      true
    property var  clientList:       []
    property bool fullscreenActive: false
    property var  cycleIndex: ({})

    property string tooltipText:    ""
    property real   tooltipCenterX: 0
    property bool   tooltipVisible: false

    readonly property var pinnedApps: [
        { name: "Finder",   cmd: "dolphin",   icon: "system-file-manager" },
        { name: "Terminal", cmd: "kitty",      icon: "kitty"               },
        { name: "Browser",  cmd: "brave",      icon: "brave-browser"       },
        { name: "Settings", cmd: "",           icon: "preferences-system"  }
    ]

    // ─────────────────────────────────────────────────────────────────────
    //  Résolution d'icône
    //  Ordre : heuristicLookup → startupWmClass match → iconPath direct
    // ─────────────────────────────────────────────────────────────────────
    function resolveIcon(appId) {
        if (!appId || appId === "") return ""

        var de = DesktopEntries.heuristicLookup(appId)
        if (de && de.icon) {
            var p = Quickshell.iconPath(de.icon, true)
            if (p !== "") return p
            if (de.icon.indexOf("/") === 0) return de.icon
        }

        var p2 = Quickshell.iconPath(appId.toLowerCase(), true)
        if (p2 !== "") return p2

        var de2 = DesktopEntries.byId(appId.toLowerCase())
        if (!de2) de2 = DesktopEntries.byId(appId)
        if (de2 && de2.icon) {
            var p3 = Quickshell.iconPath(de2.icon, true)
            if (p3 !== "") return p3
        }

        return ""
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Cache des .desktop : name_minuscule → { icon, desktopId }
    //  Construit au démarrage depuis /run/current-system/sw/share/applications/
    //  Utilisé pour les apps Electron dont class=initialClass="electron"
    //  et dont seul initialTitle ("Proton Pass", "Ente Photos"…) est fiable.
    //
    //  Données réelles observées sur ce système :
    //    electron | electron | Proton Pass  → proton-pass.desktop
    //    electron | electron | Ente Photos  → ente-desktop.desktop
    // ─────────────────────────────────────────────────────────────────────
    property var desktopByName: ({})

    Process {
        id: _desktopScan
        command: ["sh", "-c",
            "for f in /run/current-system/sw/share/applications/*.desktop; do" +
            "  id=$(basename \"$f\" .desktop);" +
            "  name=$(grep -m1 '^Name=' \"$f\" 2>/dev/null | cut -d= -f2-);" +
            "  icon=$(grep -m1 '^Icon=' \"$f\" 2>/dev/null | cut -d= -f2-);" +
            "  [ -n \"$name\" ] && echo \"${name}|${id}|${icon}\";" +
            "done"
        ]
        stdout: StdioCollector { id: _desktopOut }
        onExited: {
            var lines = _desktopOut.text.trim().split("\n")
            var cache = {}
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split("|")
                if (parts.length < 2 || parts[0].trim() === "") continue
                var name     = parts[0].trim()
                var desktopId = parts[1] || ""
                var icon     = parts[2] || ""
                var entry    = { desktopId: desktopId, icon: icon, name: name }
                // Indexer par Name complet ("Ente", "Proton Pass")
                cache[name.toLowerCase()] = entry
                // Indexer par desktopId ("ente-desktop", "proton-pass")
                if (desktopId) cache[desktopId.toLowerCase()] = entry
                // Indexer par desktopId sans suffixes communs
                var stripped = desktopId.replace(/-desktop$|-app$|-browser$/, "")
                if (stripped && stripped !== desktopId) cache[stripped.toLowerCase()] = entry
            }
            dockRoot.desktopByName = cache
            dockRoot._rebuildGroupedClients()
        }
    }

    function resolveAppId(c) {
        var cls    = c.cls          || ""
        var icls   = c.initialClass || ""
        var ititle = c.initialTitle || ""
        var clsLow = cls.toLowerCase()

        var electronLike = (clsLow === "electron" ||
                            icls.toLowerCase() === "electron" ||
                            clsLow.indexOf("electron") === 0)

        if (!electronLike)
            return icls !== "" ? icls : cls

        if (ititle && ititle !== "") {
            var entry = _lookupDesktopEntry(ititle)
            if (entry && entry.name)
                return entry.name
            var seg = ititle.split(/\s[—–-]\s/)[0].trim()
            if (seg.length > 1) return seg
        }

        return cls
    }

    function _lookupDesktopEntry(ititle) {
        var cache = dockRoot.desktopByName
        // 1. Titre complet exact
        var e = cache[ititle.toLowerCase()]
        if (e) return e
        // 2. Premier mot seulement ("Ente" depuis "Ente Photos")
        var firstWord = ititle.split(/\s/)[0].toLowerCase()
        e = cache[firstWord]
        if (e) return e
        // 3. Segment avant séparateur
        var seg = ititle.split(/\s[—–-]\s/)[0].trim().toLowerCase()
        e = cache[seg]
        if (e) return e
        // 4. Kebab-case complet ("ente-photos")
        var kebab = ititle.toLowerCase().replace(/\s+/g, "-")
        e = cache[kebab]
        if (e) return e
        // 5. Chercher si une clé du cache commence par le premier mot
        var keys = Object.keys(cache)
        for (var k = 0; k < keys.length; k++) {
            if (keys[k].indexOf(firstWord) === 0)
                return cache[keys[k]]
        }
        return null
    }

    function resolveIconForClient(c) {
        var clsLow = (c.cls || "").toLowerCase()
        var iclsLow = (c.initialClass || "").toLowerCase()
        var electronLike = (clsLow === "electron" || iclsLow === "electron" ||
                            clsLow.indexOf("electron") === 0)

        if (electronLike) {
            var ititle = (c.initialTitle || "").trim()
            if (ititle !== "") {
                var entry = _lookupDesktopEntry(ititle)
                if (entry && entry.icon) {
                    var p = Quickshell.iconPath(entry.icon, true)
                    if (p !== "") return p
                    if (entry.icon.indexOf("/") === 0) return entry.icon
                }
                if (entry && entry.desktopId) {
                    var p2 = Quickshell.iconPath(entry.desktopId, true)
                    if (p2 !== "") return p2
                }
            }
        }

        return resolveIcon(resolveAppId(c))
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Groupement des clients par appId résolu
    // ─────────────────────────────────────────────────────────────────────
    property var groupedClients: []

    function _rebuildGroupedClients() {
        var groups = {}
        var order  = []

        for (var i = 0; i < clientList.length; i++) {
            var c     = clientList[i]
            var appId = resolveAppId(c)
            var key   = appId.toLowerCase()

            if (!groups[key]) {
                groups[key] = {
                    key:         key,
                    displayName: appId,
                    iconPath:    resolveIconForClient(c),
                    instances:   []
                }
                order.push(key)
            }
            groups[key].instances.push({
                address: c.address,
                title:   c.title,
                pid:     c.pid,
                ws:      c.ws
            })
        }

        var result = []
        for (var j = 0; j < order.length; j++)
            result.push(groups[order[j]])

        dockRoot.groupedClients = result
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Hyprland polling
    // ─────────────────────────────────────────────────────────────────────
    Process {
        id: _hyprClients
        command: ["sh", "-c", "hyprctl clients -j 2>/dev/null"]
        stdout: StdioCollector { id: _clientsOut }
        onExited: dockRoot._parseClients(_clientsOut.text)
    }

    Process {
        id: _hyprActive
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null"]
        stdout: StdioCollector { id: _activeOut }
        onExited: dockRoot._parseActiveWindow(_activeOut.text)
    }

    Timer {
        id: _pollTimer
        interval: 1500
        running:  true
        repeat:   true
        onTriggered: {
            _hyprClients.running = true
            _hyprActive.running  = true
        }
    }

    Component.onCompleted: {
        _desktopScan.running = true
        _hyprClients.running = true
        _hyprActive.running  = true
    }

    function _parseClients(json) {
        try {
            var data   = JSON.parse(json)
            var result = []
            for (var i = 0; i < data.length; i++) {
                var c = data[i]
                if (!c.class || c.class === "") continue
                result.push({
                    cls:          c.class,
                    initialClass: c.initialClass || "",
                    title:        c.title        || "",
                    initialTitle: c.initialTitle || "",
                    address:      c.address,
                    pid:          c.pid,
                    ws:           c.workspace ? c.workspace.id : -1
                })
            }
            dockRoot.clientList = result
            dockRoot._rebuildGroupedClients()
        } catch (e) {}
    }

    function _parseActiveWindow(json) {
        try {
            var d = JSON.parse(json)
            dockRoot.fullscreenActive = (d.fullscreen === 1 || d.fullscreen === 2)
            if (!dockRoot.pinned && dockRoot.fullscreenActive)
                _hideTimer.restart()
        } catch (e) {
            dockRoot.fullscreenActive = false
        }
    }

    Process {
        id: _hyprFocus
        property string targetAddress: ""
        command: ["hyprctl", "dispatch", "focuswindow", "address:" + targetAddress]
        running: false
    }

    function activateWindow(address) {
        if (!address || address === "") return
        var needle = address.toLowerCase()
        if (needle.indexOf("0x") !== 0) needle = "0x" + needle

        var tops = Hyprland.toplevels
        if (tops) {
            for (var i = 0; i < tops.length; i++) {
                var t = tops[i]
                if (!t || !t.address) continue
                var ta = t.address.toLowerCase()
                if (ta.indexOf("0x") !== 0) ta = "0x" + ta
                if (ta === needle) {
                    t.activate()
                    return
                }
            }
        }

        _hyprFocus.targetAddress = needle
        _hyprFocus.running = true
    }

    function cycleWindow(groupKey, instances) {
        if (!instances || instances.length === 0) return
        var idx = (dockRoot.cycleIndex[groupKey] || 0) % instances.length
        activateWindow(instances[idx].address)
        var ci = dockRoot.cycleIndex
        ci[groupKey] = (idx + 1) % instances.length
        dockRoot.cycleIndex = ci
    }

    function launchDetached(cmd) {
        if (!cmd || cmd === "") return
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    function pinnedGroupInstances(entry) {
        var cmd    = entry.cmd.toLowerCase()
        var result = []
        for (var i = 0; i < clientList.length; i++) {
            var c     = clientList[i]
            var appId = resolveAppId(c).toLowerCase()
            if (cmd !== "" && (appId.indexOf(cmd) !== -1 || cmd.indexOf(appId) !== -1))
                result.push({ address: c.address, title: c.title, pid: c.pid, ws: c.ws })
        }
        return result
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Autohide
    // ─────────────────────────────────────────────────────────────────────
    property bool _dockReveal: true

    Timer {
        id: _hideTimer
        interval: 800
        repeat:   false
        onTriggered: {
            if (!dockRoot.pinned)
                dockRoot._dockReveal = false
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  PanelWindow
    // ─────────────────────────────────────────────────────────────────────
    Loader {
        active: true
        sourceComponent: Component {
            PanelWindow {
                id: dockWin

                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.namespace:     "quickshell:dock"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors { bottom: true; left: true; right: true }
                implicitHeight: dockRoot.dockHeight + 80
                exclusiveZone:  dockRoot.pinned ? (dockRoot.dockHeight + 8) : 0
                color:          "transparent"

                mask: Region { item: dockMouseArea }

                MouseArea {
                    id: dockMouseArea
                    height: parent.height
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top:              parent.top
                        topMargin: {
                            var revealed = dockRoot.pinned
                                           ? !dockRoot.fullscreenActive
                                           : dockRoot._dockReveal
                            return revealed ? 0
                                            : (dockWin.implicitHeight - dockRoot.hoverRegionH)
                        }
                    }
                    implicitWidth: dockContainer.width + 40
                    hoverEnabled: true

                    Behavior on anchors.topMargin {
                        NumberAnimation { duration: 380; easing.type: Easing.OutQuart }
                    }

                    onContainsMouseChanged: {
                        if (!dockRoot.pinned) {
                            if (containsMouse) {
                                _hideTimer.stop()
                                dockRoot._dockReveal = true
                            } else {
                                _hideTimer.restart()
                            }
                        }
                    }

                    Item {
                        id: dockContainer
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom:           parent.bottom
                            bottomMargin:     8
                        }
                        width:  dockRow.implicitWidth + dockRoot.dockPadH * 2
                        height: dockRoot.dockHeight

                        Rectangle {
                            anchors.fill: parent
                            radius:       dockRoot.dockRadius
                            color:        "#22ffffff"
                            border.color: "#38ffffff"
                            border.width: 1
                            Rectangle {
                                anchors {
                                    top: parent.top; left: parent.left; right: parent.right
                                    leftMargin: 28; rightMargin: 28; topMargin: 1
                                }
                                height: 1; radius: 1; color: "#55ffffff"
                            }
                        }

                        Row {
                            id: dockRow
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left:           parent.left
                                leftMargin:     dockRoot.dockPadH
                            }
                            spacing: dockRoot.iconSpacing

                            Repeater {
                                id: _pinnedRepeater
                                model: dockRoot.pinnedApps

                                delegate: DockIcon {
                                    required property var modelData
                                    required property int index

                                    property var    _inst:     dockRoot.pinnedGroupInstances(modelData)
                                    property string _groupKey: modelData.cmd.toLowerCase()

                                    appName:       modelData.name
                                    appCmd:        modelData.cmd
                                    appIconPath:   Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    instanceCount: _inst.length
                                    iconIndex:     index
                                    totalIcons:    _pinnedRepeater.count + 1 + _activeRepeater.count
                                    dockHovered:   _magArea.containsMouse
                                    mouseXInDock:  _magArea.mouseX
                                    tooltipTarget: dockContainer

                                    Connections {
                                        target: dockRoot
                                        function onClientListChanged() {
                                            parent._inst = dockRoot.pinnedGroupInstances(parent.modelData)
                                        }
                                    }

                                    onClicked: {
                                        if (_inst.length > 0)
                                            dockRoot.cycleWindow(_groupKey, _inst)
                                        else
                                            dockRoot.launchDetached(appCmd)
                                    }
                                }
                            }

                            Item {
                                width:  12
                                height: dockRoot.baseIconSize * 0.75
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 1; height: parent.height
                                    color: "#55ffffff"; radius: 1
                                }
                            }

                            Repeater {
                                id: _activeRepeater
                                model: {
                                    var pinned = dockRoot.pinnedApps.map(function(a) {
                                        return a.cmd.toLowerCase()
                                    })
                                    return dockRoot.groupedClients.filter(function(g) {
                                        for (var j = 0; j < pinned.length; j++) {
                                            if (pinned[j] !== "" &&
                                                (g.key.indexOf(pinned[j]) !== -1 ||
                                                 pinned[j].indexOf(g.key) !== -1))
                                                return false
                                        }
                                        return true
                                    })
                                }

                                delegate: DockIcon {
                                    required property var modelData
                                    required property int index

                                    appName:       modelData.displayName
                                    appCmd:        modelData.key
                                    appIconPath:   modelData.iconPath
                                    instanceCount: modelData.instances.length
                                    iconIndex:     _pinnedRepeater.count + 1 + index
                                    totalIcons:    _pinnedRepeater.count + 1 + _activeRepeater.count
                                    dockHovered:   _magArea.containsMouse
                                    mouseXInDock:  _magArea.mouseX
                                    tooltipTarget: dockContainer

                                    onClicked: dockRoot.cycleWindow(modelData.key, modelData.instances)
                                }
                            }

                            Item {
                                width:  38
                                height: dockRoot.baseIconSize

                                Rectangle {
                                    id: _pinBtn
                                    anchors.centerIn: parent
                                    width: 28; height: 28; radius: 14
                                    color:        dockRoot.pinned ? "#55ffffff" : "#22ffffff"
                                    border.color: "#44ffffff"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Canvas {
                                        id: _pinCanvas
                                        anchors.centerIn: parent
                                        width: 14; height: 14
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            ctx.strokeStyle = dockRoot.pinned ? "#ffffffff" : "#aaffffff"
                                            ctx.lineWidth = 1.5
                                            ctx.lineCap   = "round"
                                            ctx.beginPath(); ctx.arc(7, 4.5, 3.5, 0, Math.PI * 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(7, 8); ctx.lineTo(7, 13); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(4, 4.5); ctx.lineTo(10, 4.5); ctx.stroke()
                                        }
                                        Connections {
                                            target: dockRoot
                                            function onPinnedChanged() { _pinCanvas.requestPaint() }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            dockRoot.pinned = !dockRoot.pinned
                                            if (!dockRoot.pinned) {
                                                _hideTimer.stop()
                                                dockRoot._dockReveal = true
                                            }
                                        }
                                        onContainsMouseChanged: {
                                            _pinBtn.color = containsMouse
                                                ? (dockRoot.pinned ? "#77ffffff" : "#44ffffff")
                                                : (dockRoot.pinned ? "#55ffffff" : "#22ffffff")
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: _magArea
                            anchors.fill:    parent
                            hoverEnabled:    true
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }

                        Rectangle {
                            id: _globalTip
                            visible:      dockRoot.tooltipVisible
                            z:            9999
                            x:            Math.max(4, Math.min(
                                              dockRoot.tooltipCenterX - width / 2,
                                              parent.width - width - 4))
                            y:            -height - 10
                            width:        _globalTipText.implicitWidth + 20
                            height:       28
                            radius:       8
                            color:        "#E8111111"
                            border.color: "#55ffffff"
                            border.width: 1

                            Text {
                                id: _globalTipText
                                anchors.centerIn: parent
                                text:             dockRoot.tooltipText
                                color:            "#f2f2f2"
                                font.pixelSize:   12
                                font.weight:      Font.Medium
                                renderType:       Text.NativeRendering
                            }

                            Canvas {
                                anchors {
                                    top:              parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: 12; height: 7
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.fillStyle = "#E8111111"
                                    ctx.beginPath()
                                    ctx.moveTo(0, 0); ctx.lineTo(12, 0); ctx.lineTo(6, 7)
                                    ctx.closePath(); ctx.fill()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  DockIcon
    // ─────────────────────────────────────────────────────────────────────
    component DockIcon: Item {
        id: iconItem

        property string appName:       ""
        property string appCmd:        ""
        property string appIconPath:   ""
        property int    instanceCount: 0
        property int    iconIndex:     0
        property int    totalIcons:    1
        property bool   dockHovered:   false
        property real   mouseXInDock:  0
        property Item   tooltipTarget: null

        signal clicked()

        readonly property real iconCenterX: x + width / 2
        readonly property real slotWidth:   dockRoot.baseIconSize + dockRoot.iconSpacing
        readonly property real distSlots: {
            if (!dockHovered) return 999
            return Math.abs(mouseXInDock - iconCenterX) / slotWidth
        }
        readonly property real magFactor: {
            if (!dockHovered) return 1.0
            var d = distSlots
            if      (d < 0.6) return dockRoot.magScale1
            else if (d < 1.4) return dockRoot.magScale2
            else if (d < 2.2) return dockRoot.magScale3
            else              return 1.0
        }

        width:  dockRoot.baseIconSize
        height: dockRoot.baseIconSize + 14

        Item {
            id: _iconContainer
            anchors {
                bottom:           parent.bottom
                bottomMargin:     12
                horizontalCenter: parent.horizontalCenter
            }
            width:           dockRoot.baseIconSize
            height:          dockRoot.baseIconSize
            transformOrigin: Item.Bottom
            scale:           iconItem.magFactor

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Image {
                id: _iconImg
                anchors.fill:    parent
                anchors.margins: 2
                source:          iconItem.appIconPath
                fillMode:        Image.PreserveAspectFit
                smooth:          true
                antialiasing:    true
                visible:         status === Image.Ready && source !== ""
            }

            Rectangle {
                anchors.fill:    parent
                anchors.margins: 2
                radius:          14
                visible:         !_iconImg.visible
                color: {
                    var pal = ["#FF6B6B","#FF9F43","#FECA57","#48DBFB",
                               "#1DD1A1","#54A0FF","#5F27CD","#FF9FF3","#00D2D3","#C8D6E5"]
                    var idx = 0
                    for (var i = 0; i < iconItem.appName.length; i++)
                        idx = (idx + iconItem.appName.charCodeAt(i)) % pal.length
                    return pal[idx]
                }
                Text {
                    anchors.centerIn: parent
                    text:             iconItem.appName.length > 0
                                      ? iconItem.appName[0].toUpperCase() : "?"
                    color:            "white"
                    font.pixelSize:   22
                    font.weight:      Font.Bold
                    renderType:       Text.NativeRendering
                }
            }

            Rectangle {
                anchors.fill:    parent
                anchors.margins: 2
                radius:          14
                color:           "#28ffffff"
                visible:         _iconMa.containsMouse
            }

            MouseArea {
                id: _iconMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    iconItem.clicked()
                onContainsMouseChanged: {
                    if (containsMouse) {
                        _tipDelay.restart()
                    } else {
                        _tipDelay.stop()
                        dockRoot.tooltipVisible = false
                    }
                }
            }

            Timer {
                id: _tipDelay
                interval: 500
                repeat:   false
                onTriggered: {
                    if (iconItem.tooltipTarget) {
                        var pt = iconItem.mapToItem(iconItem.tooltipTarget,
                                                    iconItem.width / 2, 0)
                        dockRoot.tooltipCenterX = pt.x
                    }
                    dockRoot.tooltipText = iconItem.instanceCount > 1
                        ? iconItem.appName + "  (" + iconItem.instanceCount + ")"
                        : iconItem.appName
                    dockRoot.tooltipVisible = true
                }
            }
        }

        Row {
            anchors {
                bottom:           parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin:     1
            }
            spacing: 3
            visible: iconItem.instanceCount > 0
            Repeater {
                model: Math.min(iconItem.instanceCount, 4)
                delegate: Rectangle {
                    width: 5; height: 5; radius: 2.5
                    color: "#e8e8e8"; opacity: 0.88
                }
            }
        }
    }
}
