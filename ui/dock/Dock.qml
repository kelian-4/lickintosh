import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.components.glass

Scope {
    id: dockRoot

    readonly property int  baseIconSize: ShellConfig.options.dockAppearance.iconSize
    readonly property int  dockPadH:     14
    readonly property int  dockPadV:     10
    readonly property int  dockHeight:   baseIconSize + dockPadV * 2 + 12
    readonly property int  dockRadius:   22
    readonly property int  iconSpacing:  8
    readonly property real magScale1:    ShellConfig.options.dockAppearance.magnificationEnabled ? ShellConfig.options.dockAppearance.magnification : 1.0
    readonly property real magScale2:    ShellConfig.options.dockAppearance.magnificationEnabled ? (1.0 + (ShellConfig.options.dockAppearance.magnification - 1.0) * 0.5) : 1.0
    readonly property real magScale3:    ShellConfig.options.dockAppearance.magnificationEnabled ? (1.0 + (ShellConfig.options.dockAppearance.magnification - 1.0) * 0.16) : 1.0
    readonly property int  hoverRegionH: 4

    property bool pinned:         !ShellConfig.options.dockAppearance.hoverToReveal
    property var  clientList:     []
    property bool fullscreenActive: false
    property var  cycleIndex:     ({})
    property string tooltipText:    ""
    property real   tooltipCenterX: 0
    property bool   tooltipVisible: false

    property bool   menuVisible:    false
    property string menuMode:       "app"
    property real   menuX:          0
    property real   menuY:          0
    property string menuAppName:    ""
    property string menuGroupKey:   ""
    property bool   menuIsPinned:   false
    property var    menuInstances:  []
    property string menuIconPath:   ""

    property bool   submenuVisible: false
    property string submenuKind:    ""
    property real   submenuX:       0
    property real   submenuY:       0

    property int  dragListId:       0
    property int  dragFromIndex:    -1
    property int  dragToIndex:      -1
    property bool reorderDragActive: false

    property var pinnedFiles: []

    property var pinnedApps: [
        { name: "Finder",   cmd: "dolphin",   icon: "system-file-manager", iconPath: "", autostart: false },
        { name: "Terminal", cmd: "kitty",      icon: "kitty",               iconPath: "", autostart: false },
        { name: "Browser",  cmd: "brave",      icon: "brave-browser",      iconPath: "", autostart: false },
        { name: "Settings", cmd: "__settings-app__", icon: "preferences-system", iconPath: "", autostart: false }
    ]

    readonly property string _stateDir:  "$HOME/.config/quickshell/dock"
    readonly property string _statePath: dockRoot._stateDir + "/dock-state.json"
    property bool _stateLoaded: false

    onPinnedAppsChanged: {
        if (!dockRoot._stateLoaded) return
        dockRoot.saveState()
        dockRoot._syncAutostartFile()
    }

    onPinnedFilesChanged: {
        if (!dockRoot._stateLoaded) return
        dockRoot.saveState()
    }

    function saveState() {
        var data    = JSON.stringify({ pinnedApps: dockRoot.pinnedApps, pinnedFiles: dockRoot.pinnedFiles })
        var escaped = data.replace(/'/g, "'\\''")
        _stateSave.command = ["sh", "-c",
            "mkdir -p " + dockRoot._stateDir + " && printf '%s' '" + escaped + "' > " + dockRoot._statePath]
        _stateSave.running = true
    }

    function resolveIcon(appId) {
        if (!appId || appId === "") return ""
        var de = DesktopEntries.heuristicLookup(appId)
        if (de && de.icon) {
            var p = Quickshell.iconPath(de.icon, true)
            if (p !== "") return p
        }
        return ""
    }

    function _findDesktopEntry(name) {
        var entries = DesktopEntries.applications.values
        var lower   = name.toLowerCase()
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].name && entries[i].name.toLowerCase() === lower) return entries[i]
        }
        var firstWord = lower.split(/\s/)[0]
        for (var j = 0; j < entries.length; j++) {
            if (entries[j].name && entries[j].name.toLowerCase() === firstWord) return entries[j]
        }
        var seg = lower.split(/\s[—–-]\s/)[0].trim()
        for (var k = 0; k < entries.length; k++) {
            if (entries[k].name && entries[k].name.toLowerCase() === seg) return entries[k]
        }
        for (var m = 0; m < entries.length; m++) {
            if (entries[m].name && entries[m].name.toLowerCase().indexOf(firstWord) === 0) return entries[m]
        }
        return null
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
            var entry = dockRoot._findDesktopEntry(ititle)
            if (entry && entry.name) return entry.name
            var seg = ititle.split(/\s[—–-]\s/)[0].trim()
            if (seg.length > 1) return seg
        }
        return cls
    }

    function resolveIconForClient(c) {
        var clsLow  = (c.cls          || "").toLowerCase()
        var iclsLow = (c.initialClass || "").toLowerCase()
        var electronLike = (clsLow === "electron" || iclsLow === "electron" ||
                            clsLow.indexOf("electron") === 0)
        if (electronLike) {
            var ititle = (c.initialTitle || "").trim()
            if (ititle !== "") {
                var entry = dockRoot._findDesktopEntry(ititle)
                if (entry && entry.icon) {
                    var p = Quickshell.iconPath(entry.icon, true)
                    if (p !== "") return p
                }
            }
        }
        return resolveIcon(resolveAppId(c))
    }

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
                ws:      c.ws,
                wsName:  c.wsName,
                w:       c.w,
                h:       c.h,
                pinned:  c.pinned
            })
        }
        var result = []
        for (var j = 0; j < order.length; j++)
            result.push(groups[order[j]])
        dockRoot.groupedClients = result
    }

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

    Process {
        id: _activeWsQuery
        property var pendingAddresses: []
        command: ["sh", "-c", "hyprctl activeworkspace -j 2>/dev/null"]
        stdout: StdioCollector { id: _activeWsOut }
        onExited: {
            try {
                var d    = JSON.parse(_activeWsOut.text)
                var wsId = d.id
                for (var i = 0; i < _activeWsQuery.pendingAddresses.length; i++) {
                    dockRoot.dispatchLua('hl.dsp.window.move({ workspace = ' + wsId + ', window = "address:' +
                                          _activeWsQuery.pendingAddresses[i] + '", follow = true })')
                }
            } catch (e) {}
        }
    }

    Process {
        id: _clipCopy
        command: ["wl-copy", ""]
    }

    Process {
        id: _autostartWrite
        command: ["true"]
    }

    Process {
        id: _stateSave
        command: ["true"]
    }

    Process {
        id: _stateLoad
        command: ["sh", "-c", "cat " + dockRoot._statePath + " 2>/dev/null"]
        stdout: StdioCollector { id: _stateLoadOut }
        onExited: {
            var text = _stateLoadOut.text.trim()
            if (text !== "") {
                try {
                    var data = JSON.parse(text)
                    if (data.pinnedApps && data.pinnedApps.length > 0) dockRoot.pinnedApps = data.pinnedApps
                    if (data.pinnedFiles) dockRoot.pinnedFiles = data.pinnedFiles
                } catch (e) {}
            }
            dockRoot._stateLoaded = true
            dockRoot._syncAutostartFile()
        }
    }

    Process {
        id: _dropStatCheck
        property string pendingPath: ""
        stdout: StdioCollector { id: _dropStatOut }
        onExited: {
            var isDir = _dropStatOut.text.trim() === "dir"
            dockRoot.pinFile(_dropStatCheck.pendingPath, isDir)
        }
    }

    Process {
        id: _trashEmpty
        command: ["sh", "-c", "gio trash --empty 2>/dev/null"]
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
        _hyprClients.running = true
        _hyprActive.running  = true
        _stateLoad.running   = true
        if (!dockRoot.pinned) _hideTimer.restart()
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
                    ws:           c.workspace ? c.workspace.id   : -1,
                    wsName:       c.workspace ? c.workspace.name : "",
                    w:            c.size ? c.size[0] : 0,
                    h:            c.size ? c.size[1] : 0,
                    pinned:       c.pinned === true
                })
            }
            dockRoot.clientList = result
            dockRoot._rebuildGroupedClients()
        } catch (e) {}
    }

    function _parseActiveWindow(json) {
        try {
            var d = JSON.parse(json)
            var wasFullscreen = dockRoot.fullscreenActive
            dockRoot.fullscreenActive = (d.fullscreen === 1 || d.fullscreen === 2)
            if (!wasFullscreen && dockRoot.fullscreenActive)
                dockRoot.closeContextMenu()
            if (!dockRoot.pinned && dockRoot.fullscreenActive)
                _hideTimer.restart()
        } catch (e) {
            dockRoot.fullscreenActive = false
        }
    }

    function dispatchLua(expr) {
        Hyprland.dispatch(expr)
    }

    function focusWindow(address) {
        if (!address || address === "") return
        var addr = address.toLowerCase()
        if (addr.indexOf("0x") !== 0) addr = "0x" + addr
        dockRoot.dispatchLua('hl.dsp.focus({ window = "address:' + addr + '" })')
    }

    function cycleWindow(groupKey, instances) {
        if (!instances || instances.length === 0) return
        var idx  = (dockRoot.cycleIndex[groupKey] || 0) % instances.length
        var inst = instances[idx]
        if (inst.wsName && inst.wsName.indexOf("special:") === 0) {
            _activeWsQuery.pendingAddresses = [inst.address]
            _activeWsQuery.running = true
        } else {
            dockRoot.dispatchLua('hl.dsp.focus({ window = "address:' + inst.address + '" })')
            if (inst.ws > 0)
                dockRoot.dispatchLua('hl.dsp.focus({ workspace = "' + inst.ws + '" })')
        }
        var ci = dockRoot.cycleIndex
        ci[groupKey] = (idx + 1) % instances.length
        dockRoot.cycleIndex = ci
    }

    function launchDetached(cmd) {
        if (!cmd || cmd === "") return
        dockRoot.dispatchLua('hl.dsp.exec_cmd("' + cmd.replace(/"/g, '\\"') + '")')
    }

    function launchSettingsApp() {
        console.log("[Settings launch] execDetached, shellDir=", Quickshell.shellDir)
        Quickshell.execDetached(["quickshell", "-p", Quickshell.shellDir + "/settings.qml"])
    }

    function pinnedGroupInstances(entry) {
        if (!entry) return []
        var cmd    = entry.cmd ? entry.cmd.toLowerCase() : ""
        var result = []
        for (var i = 0; i < clientList.length; i++) {
            var c     = clientList[i]
            var appId = resolveAppId(c).toLowerCase()
            if (cmd !== "" && (appId.indexOf(cmd) !== -1 || cmd.indexOf(appId) !== -1))
                result.push({ address: c.address, title: c.title, pid: c.pid, ws: c.ws, wsName: c.wsName, w: c.w, h: c.h, pinned: c.pinned })
        }
        return result
    }

    property bool _dockReveal: true
    property bool hoverActive: false

    onPinnedChanged: {
        if (!dockRoot.pinned && !dockRoot.hoverActive) {
            _hideTimer.restart()
        } else if (dockRoot.pinned) {
            _hideTimer.stop()
            dockRoot._dockReveal = true
        }
    }

    Timer {
        id: _hideTimer
        interval: 800
        repeat:   false
        onTriggered: {
            if (!dockRoot.pinned) {
                dockRoot._dockReveal = false
                dockRoot.closeContextMenu()
            }
        }
    }

    function openContextMenu(x, y, appName, groupKey, isPinned, instances, iconPath, mode) {
        dockRoot.menuAppName    = appName
        dockRoot.menuGroupKey   = groupKey
        dockRoot.menuIsPinned   = isPinned
        dockRoot.menuInstances  = instances
        dockRoot.menuIconPath   = iconPath
        dockRoot.menuMode       = mode ? mode : "app"
        dockRoot.menuX          = x
        dockRoot.menuY          = y
        dockRoot.menuVisible    = true
        dockRoot.submenuVisible = false
        if (!dockRoot.pinned) {
            _hideTimer.stop()
            dockRoot._dockReveal = true
        }
    }

    function closeContextMenu() {
        dockRoot.menuVisible    = false
        dockRoot.submenuVisible = false
        if (!dockRoot.pinned && !dockRoot.hoverActive)
            _hideTimer.restart()
    }

    function toggleKeepInDock() {
        var key  = dockRoot.menuGroupKey
        var list = dockRoot.pinnedApps.slice()
        var idx  = -1
        for (var i = 0; i < list.length; i++) {
            if (list[i].cmd.toLowerCase() === key) { idx = i; break }
        }
        if (idx >= 0) {
            list.splice(idx, 1)
        } else {
            list.push({ name: dockRoot.menuAppName, cmd: key, icon: "", iconPath: dockRoot.menuIconPath, autostart: false })
        }
        dockRoot.pinnedApps = list
    }

    function _syncAutostartFile() {
        var cmdLines = []
        for (var i = 0; i < dockRoot.pinnedApps.length; i++) {
            var e = dockRoot.pinnedApps[i]
            if (e.autostart && e.cmd)
                cmdLines.push('    hl.exec_cmd("' + e.cmd.replace(/"/g, '\\"') + '")')
        }
        var content = '-- Généré automatiquement par le Dock — ne pas éditer à la main\n' +
                      'hl.on("hyprland.start", function()\n' +
                      cmdLines.join("\n") + (cmdLines.length ? "\n" : "") +
                      'end)\n'
        var escaped = content.replace(/'/g, "'\\''")
        _autostartWrite.command = ["sh", "-c",
            "mkdir -p $HOME/.config/quickshell/dock-autostart && printf '%s' '" + escaped +
            "' > $HOME/.config/quickshell/dock-autostart/dock-autostart.lua"]
        _autostartWrite.running = true
    }

    function toggleAutostart() {
        var key  = dockRoot.menuGroupKey
        var list = dockRoot.pinnedApps.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].cmd.toLowerCase() === key) {
                var entry = list[i]
                list[i] = { name: entry.name, cmd: entry.cmd, icon: entry.icon, iconPath: entry.iconPath, autostart: !entry.autostart }
                dockRoot.pinnedApps = list
                return
            }
        }
    }

    function pinFile(path, isDir) {
        if (!path || path === "") return
        var list = dockRoot.pinnedFiles.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === path) return
        }
        list.push({ path: path, isDir: isDir })
        dockRoot.pinnedFiles = list
    }

    function unpinFile(path) {
        var list = dockRoot.pinnedFiles.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === path) { list.splice(i, 1); break }
        }
        dockRoot.pinnedFiles = list
    }

    function reorderPinnedApps(fromIndex, toIndex) {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0) return
        var list = dockRoot.pinnedApps.slice()
        if (fromIndex >= list.length || toIndex >= list.length) return
        var moved = list.splice(fromIndex, 1)[0]
        list.splice(toIndex, 0, moved)
        dockRoot.pinnedApps = list
    }

    function reorderPinnedFiles(fromIndex, toIndex) {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0) return
        var list = dockRoot.pinnedFiles.slice()
        if (fromIndex >= list.length || toIndex >= list.length) return
        var moved = list.splice(fromIndex, 1)[0]
        list.splice(toIndex, 0, moved)
        dockRoot.pinnedFiles = list
    }

    function pinDroppedPath(path) {
        if (!path || path === "") return
        _dropStatCheck.pendingPath = path
        _dropStatCheck.command = ["sh", "-c", 'test -d "$1" && echo dir || echo file', "_", path]
        _dropStatCheck.running = true
    }

    function fileIconPath(entry) {
        if (entry.isDir) return Quickshell.iconPath("folder", true)
        var name = entry.path.split("/").pop()
        var ext  = name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
        var iconName = "text-x-generic"
        if (ext === "pdf") iconName = "application-pdf"
        else if (ext === "png" || ext === "jpg" || ext === "jpeg" || ext === "webp") iconName = "image-x-generic"
        else if (ext === "mp4" || ext === "mkv") iconName = "video-x-generic"
        else if (ext === "mp3" || ext === "flac") iconName = "audio-x-generic"
        return Quickshell.iconPath(iconName, true)
    }

    function emptyTrash() {
        _trashEmpty.running = true
    }

    function copyCommand() {
        if (dockRoot.menuGroupKey === "") return
        _clipCopy.command = ["wl-copy", dockRoot.menuGroupKey]
        _clipCopy.running = true
    }

    function showAllWindows() {
        for (var i = 0; i < dockRoot.menuInstances.length; i++)
            dockRoot.dispatchLua('hl.dsp.focus({ window = "address:' + dockRoot.menuInstances[i].address + '" })')
        dockRoot.dispatchLua('hl.dsp.exec_raw("hyprexpo:expo toggle")')
    }

    function hiddenWorkspaceName(groupKey) {
        return "hidden_" + groupKey.replace(/[^a-z0-9]/gi, "")
    }

    function hideWindows() {
        var wsName = "special:" + dockRoot.hiddenWorkspaceName(dockRoot.menuGroupKey)
        for (var i = 0; i < dockRoot.menuInstances.length; i++)
            dockRoot.dispatchLua('hl.dsp.window.move({ workspace = "' + wsName + '", window = "address:' +
                                  dockRoot.menuInstances[i].address + '", follow = false })')
    }

    function unhideWindows() {
        var addrs = []
        for (var i = 0; i < dockRoot.menuInstances.length; i++)
            addrs.push(dockRoot.menuInstances[i].address)
        _activeWsQuery.pendingAddresses = addrs
        _activeWsQuery.running = true
    }

    function quitWindows() {
        for (var i = 0; i < dockRoot.menuInstances.length; i++)
            dockRoot.dispatchLua('hl.dsp.window.close({ window = "address:' + dockRoot.menuInstances[i].address + '" })')
    }

    function assignAllDesktops() {
        for (var i = 0; i < dockRoot.menuInstances.length; i++) {
            if (!dockRoot.menuInstances[i].pinned) {
                var inst = dockRoot.menuInstances[i]
                var addr = inst.address
                var side = Math.max(inst.w || 0, inst.h || 0, 320)
                dockRoot.dispatchLua('hl.dsp.window.float({ action = "set", window = "address:' + addr + '" })')
                dockRoot.dispatchLua('hl.dsp.exec_raw("resizewindowpixel exact ' + side + ' ' + side + ',address:' + addr + '")')
                dockRoot.dispatchLua('hl.dsp.window.pin({ window = "address:' + addr + '" })')
            }
        }
    }

    function assignThisDesktop() {
        for (var i = 0; i < dockRoot.menuInstances.length; i++) {
            if (dockRoot.menuInstances[i].pinned) {
                var addr = dockRoot.menuInstances[i].address
                dockRoot.dispatchLua('hl.dsp.window.pin({ window = "address:' + addr + '" })')
                dockRoot.dispatchLua('hl.dsp.window.float({ action = "toggle", window = "address:' + addr + '" })')
            }
        }
    }

    Loader {
        active: true
        sourceComponent: Component {
            PanelWindow {
                id: dockWin

                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.namespace:     "quickshell:dock"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors { bottom: true; left: true; right: true }
                implicitHeight: dockRoot.dockHeight + 80
                exclusiveZone:  dockRoot.pinned ? (dockRoot.dockHeight + 8) : 0
                color:          "transparent"

                mask: Region { item: dockMouseArea }

                LiquidGlassBackdrop {
                    id: dockBackdrop
                    wallpaperPath: ShellConfig.options.wallpaper.path
                    screenSize: Qt.size(dockWin.screen.width, dockWin.screen.height)
                    windowPosition: Qt.point(0, dockWin.screen.height - dockWin.height)
                    captureWindows: true
                    blurRadius: GlassSettings.blurRadius
                    monitorName: dockWin.screen.name
                    captureRegion: Qt.rect(0, dockWin.screen.height - dockWin.height, dockWin.screen.width, dockWin.height)
                }

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
                    implicitWidth: dockContainer.width
                    hoverEnabled:  true

                    Behavior on anchors.topMargin {
                        NumberAnimation { duration: 380; easing.type: Easing.OutQuart }
                    }

                    onContainsMouseChanged: {
                        dockRoot.hoverActive = containsMouse
                        if (!dockRoot.pinned) {
                            if (containsMouse) {
                                _hideTimer.stop()
                                dockRoot._dockReveal = true
                            } else if (!dockRoot.menuVisible && !dockRoot.submenuVisible) {
                                _hideTimer.restart()
                            }
                        }
                    }

                    DropArea {
                        id: _revealDropArea
                        anchors.fill: parent
                        onEntered: function(drag) {
                            if (!dockRoot.pinned) {
                                _hideTimer.stop()
                                dockRoot._dockReveal = true
                            }
                        }
                        onExited: {
                            if (!dockRoot.pinned && !dockRoot.hoverActive)
                                _hideTimer.restart()
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

                        Behavior on width {
                            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                        }

                        DropArea {
                            id: _dockDropArea
                            anchors.fill: parent
                            onDropped: function(drop) {
                                if (drop.hasUrls) {
                                    for (var i = 0; i < drop.urls.length; i++) {
                                        var raw  = drop.urls[i].toString()
                                        var path = decodeURIComponent(raw.replace(/^file:\/\//, ""))
                                        dockRoot.pinDroppedPath(path)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius:       dockRoot.dockRadius
                            visible:      _dockDropArea.containsDrag
                            color:        "transparent"
                            border.color: "#8877ffff"
                            border.width: 2
                            z:            500
                        }

                        LiquidGlass {
                            id:           dockGlass
                            anchors.fill: parent
                            backdrop:     dockBackdrop
                            cornerRadius: Math.min(height / 2, dockRoot.dockRadius)
                            b:            GlassSettings.refractionB
                            d:            GlassSettings.refractionD
                            fPower:       GlassSettings.refractionPower
                            noise:        GlassSettings.noise
                            glowWeight:   GlassSettings.glowWeight
                            glowBias:     0.0
                            glowEdge0:    GlassSettings.glowEdge0
                            glowEdge1:    GlassSettings.glowEdge1
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius:       Math.min(height / 2, dockRoot.dockRadius)
                            color:        Qt.rgba(1, 1, 1, GlassSettings.veil * dockGlass.level)
                            visible:      dockGlass.level > 0
                        }
                        GlassRim {
                            anchors.fill: parent
                            radius:       dockRoot.dockRadius
                            baseColor:    dockGlass.level > 0 ? "transparent" : "#22ffffff"
                            glowColor:    "#a0ffffff"
                            glowEdgeBand: 0.01
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
                                    id: _pinnedIcon
                                    required property var modelData
                                    required property int index

                                    property var    _inst:     dockRoot.pinnedGroupInstances(modelData)
                                    property string _groupKey: modelData.cmd.toLowerCase()

                                    appName:       modelData.name
                                    appCmd:        modelData.cmd
                                    appIconPath:   modelData.iconPath ? modelData.iconPath
                                                                       : Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    instanceCount: _inst.length
                                    iconIndex:     index
                                    totalIcons:    _pinnedRepeater.count + 1 + _activeRepeater.count
                                    dockHovered:   _magArea.containsMouse
                                    mouseXInDock:  _magArea.mouseX
                                    tooltipTarget: dockContainer
                                    menuTarget:    dockContainer
                                    menuYOffset:   dockWin.screen.height - (dockRoot.dockHeight + 80)
                                    groupKey:      _groupKey
                                    isPinnedApp:   true
                                    instances:     _inst
                                    reorderable:   true
                                    orderIndex:    index
                                    dragGroupId:   1
                                    maxOrderIndex: dockRoot.pinnedApps.length - 1
                                    onReorderRequested: function(fromIndex, toIndex) {
                                        dockRoot.reorderPinnedApps(fromIndex, toIndex)
                                    }

                                    Connections {
                                        target: dockRoot
                                        function onClientListChanged() {
                                            _pinnedIcon._inst = dockRoot.pinnedGroupInstances(_pinnedIcon.modelData)
                                        }
                                    }

                                    onClicked: {
                                        console.log("[Dock click]", "name=" + modelData.name, "cmd=" + appCmd, "instLen=" + _inst.length)
                                        if (_inst.length > 0)
                                            dockRoot.cycleWindow(_groupKey, _inst)
                                        else if (appCmd === "__settings-app__" || (appCmd === "" && modelData.name === "Settings"))
                                            dockRoot.launchSettingsApp()
                                        else
                                            dockRoot.launchDetached(appCmd)
                                    }
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
                                    menuTarget:    dockContainer
                                    menuYOffset:   dockWin.screen.height - (dockRoot.dockHeight + 80)
                                    groupKey:      modelData.key
                                    isPinnedApp:   false
                                    instances:     modelData.instances

                                    onClicked: dockRoot.cycleWindow(modelData.key, modelData.instances)
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
                                id: _filesRepeater
                                model: dockRoot.pinnedFiles

                                delegate: DockIcon {
                                    required property var modelData
                                    required property int index

                                    appName:       modelData.path.split("/").pop()
                                    appCmd:        modelData.path
                                    appIconPath:   dockRoot.fileIconPath(modelData)
                                    instanceCount: 0
                                    dockHovered:   _magArea.containsMouse
                                    mouseXInDock:  _magArea.mouseX
                                    tooltipTarget: dockContainer
                                    menuTarget:    dockContainer
                                    menuYOffset:   dockWin.screen.height - (dockRoot.dockHeight + 80)
                                    groupKey:      modelData.path
                                    isPinnedApp:   false
                                    instances:     []
                                    menuMode:      "file"
                                    reorderable:   true
                                    orderIndex:    index
                                    dragGroupId:   2
                                    maxOrderIndex: dockRoot.pinnedFiles.length - 1
                                    onReorderRequested: function(fromIndex, toIndex) {
                                        dockRoot.reorderPinnedFiles(fromIndex, toIndex)
                                    }

                                    onClicked: Quickshell.execDetached(["xdg-open", modelData.path])
                                }
                            }

                            DockIcon {
                                id: _trashIcon
                                appName:       "Corbeille"
                                appCmd:        ""
                                appIconPath:   Quickshell.iconPath("user-trash", true)
                                instanceCount: 0
                                dockHovered:   _magArea.containsMouse
                                mouseXInDock:  _magArea.mouseX
                                tooltipTarget: dockContainer
                                menuTarget:    dockContainer
                                menuYOffset:   dockWin.screen.height - (dockRoot.dockHeight + 80)
                                groupKey:      "__trash__"
                                isPinnedApp:   false
                                instances:     []
                                menuMode:      "trash"

                                onClicked: Quickshell.execDetached(["dolphin", "trash:/"])
                            }

                            Item {
                                id: _pinIconWrap
                                width:  dockRoot.baseIconSize
                                height: dockRoot.baseIconSize + 14

                                Item {
                                    id: _pinIconContainer
                                    anchors {
                                        bottom:           parent.bottom
                                        bottomMargin:     12
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width:  dockRoot.baseIconSize
                                    height: dockRoot.baseIconSize

                                    Rectangle {
                                        anchors.fill:    parent
                                        anchors.margins: 2
                                        radius:          14
                                        color:           dockRoot.pinned ? "#4d7fffff" : "#22ffffff"
                                        border.color:    "#38ffffff"
                                        border.width:    1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    Rectangle {
                                        anchors.fill:    parent
                                        anchors.margins: 2
                                        radius:          14
                                        color:           "#28ffffff"
                                        visible:         _pinMa.containsMouse
                                    }

                                    Canvas {
                                        id: _pinCanvas
                                        anchors.centerIn: parent
                                        width:  18
                                        height: 18
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            ctx.strokeStyle = dockRoot.pinned ? "#ffffffff" : "#ccffffff"
                                            ctx.lineWidth   = 1.8
                                            ctx.lineCap     = "round"
                                            ctx.beginPath(); ctx.arc(9, 6, 4.2, 0, Math.PI * 2); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(9, 10.2); ctx.lineTo(9, 16.5); ctx.stroke()
                                            ctx.beginPath(); ctx.moveTo(5.2, 6); ctx.lineTo(12.8, 6); ctx.stroke()
                                        }
                                        Connections {
                                            target: dockRoot
                                            function onPinnedChanged() { _pinCanvas.requestPaint() }
                                        }
                                    }

                                    MouseArea {
                                        id: _pinMa
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            var newHoverToReveal = !ShellConfig.options.dockAppearance.hoverToReveal
                                            ShellConfig.options.dockAppearance.hoverToReveal = newHoverToReveal
                                            if (newHoverToReveal) {
                                                _hideTimer.stop()
                                                dockRoot._dockReveal = true
                                            }
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

    Loader {
        active: dockRoot.menuVisible || dockRoot.submenuVisible
        sourceComponent: Component {
            PanelWindow {
                screen: {
                    var focused = Hyprland.focusedMonitor
                    if (focused) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.namespace:     "quickshell:dock-catcher"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: 0
                color:         "transparent"

                mask: Region { item: _catcherArea }

                MouseArea {
                    id: _catcherArea
                    anchors.fill:    parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: dockRoot.closeContextMenu()
                }

                Rectangle {
                    id: _ctxMenu
                    visible:      dockRoot.menuVisible
                    z:            10000
                    width:        204
                    height:       _ctxCol.implicitHeight + 12
                    radius:       10
                    color:        "#EE181818"
                    border.color: "#33ffffff"
                    border.width: 1
                    x: Math.max(4, Math.min(dockRoot.menuX - width / 2, parent.width - width - 4))
                    y: dockRoot.menuY - height - 45

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Column {
                        id: _ctxCol
                        anchors {
                            top: parent.top; left: parent.left; right: parent.right
                            topMargin: 6; leftMargin: 6; rightMargin: 6
                        }
                        spacing: 1

                        DockMenuItem {
                            id: _optionsItem
                            visible:    dockRoot.menuMode === "app"
                            label:      "Options"
                            hasSubmenu: true
                            onHoveredIn: {
                                var pt = _optionsItem.mapToItem(null, 0, 0)
                                dockRoot.submenuY    = pt.y - 6
                                dockRoot.submenuKind = "options"
                                dockRoot.submenuVisible = true
                            }
                        }

                        DockMenuDivider { visible: dockRoot.menuMode === "app" }

                        DockMenuItem {
                            visible: dockRoot.menuMode === "app"
                            label:   "Afficher toutes les fenêtres"
                            enabled: dockRoot.menuInstances.length > 0
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                dockRoot.showAllWindows()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            id: _hideItem
                            visible: dockRoot.menuMode === "app"
                            property bool _isHidden: dockRoot.menuInstances.length > 0 &&
                                                      dockRoot.menuInstances[0].wsName === "special:" + dockRoot.hiddenWorkspaceName(dockRoot.menuGroupKey)
                            label:   _hideItem._isHidden ? "Afficher" : "Masquer"
                            enabled: dockRoot.menuInstances.length > 0
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                if (_hideItem._isHidden)
                                    dockRoot.unhideWindows()
                                else
                                    dockRoot.hideWindows()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            visible:     dockRoot.menuMode === "app"
                            label:       "Quitter"
                            enabled:     dockRoot.menuInstances.length > 0
                            destructive: true
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                dockRoot.quitWindows()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuDivider { visible: dockRoot.menuMode === "app" }

                        DockMenuItem {
                            id: _assignItem
                            visible:    dockRoot.menuMode === "app"
                            label:      "Assigner à"
                            hasSubmenu: true
                            enabled:    dockRoot.menuInstances.length > 0
                            onHoveredIn: {
                                var pt = _assignItem.mapToItem(null, 0, 0)
                                dockRoot.submenuY    = pt.y - 6
                                dockRoot.submenuKind = "assign"
                                dockRoot.submenuVisible = true
                            }
                        }

                        DockMenuItem {
                            visible: dockRoot.menuMode === "file"
                            label:   "Ouvrir"
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                Quickshell.execDetached(["xdg-open", dockRoot.menuGroupKey])
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            visible: dockRoot.menuMode === "file"
                            label:   "Copier le chemin"
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                dockRoot.copyCommand()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuDivider { visible: dockRoot.menuMode === "file" }

                        DockMenuItem {
                            visible:     dockRoot.menuMode === "file"
                            label:       "Retirer du Dock"
                            destructive: true
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                dockRoot.unpinFile(dockRoot.menuGroupKey)
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            visible: dockRoot.menuMode === "trash"
                            label:   "Ouvrir la corbeille"
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                Quickshell.execDetached(["dolphin", "trash:/"])
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuDivider { visible: dockRoot.menuMode === "trash" }

                        DockMenuItem {
                            visible:     dockRoot.menuMode === "trash"
                            label:       "Vider la corbeille"
                            destructive: true
                            onHoveredIn: dockRoot.submenuVisible = false
                            onActivated: {
                                dockRoot.emptyTrash()
                                dockRoot.closeContextMenu()
                            }
                        }
                    }
                }

                Rectangle {
                    id: _ctxSubmenu
                    visible:      dockRoot.submenuVisible
                    z:            10001
                    width:        192
                    height:       _subCol.implicitHeight + 12
                    radius:       10
                    color:        "#EE181818"
                    border.color: "#33ffffff"
                    border.width: 1
                    x: {
                        var rightX = _ctxMenu.x + _ctxMenu.width + 6
                        if (rightX + width <= parent.width - 4) return rightX
                        return Math.max(4, _ctxMenu.x - width - 6)
                    }
                    y: Math.max(4, Math.min(dockRoot.submenuY, parent.height - height - 4))

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Column {
                        id: _subCol
                        anchors {
                            top: parent.top; left: parent.left; right: parent.right
                            topMargin: 6; leftMargin: 6; rightMargin: 6
                        }
                        spacing: 1

                        DockMenuItem {
                            visible: dockRoot.submenuKind === "options"
                            height:  visible ? 26 : 0
                            label:   dockRoot.menuIsPinned ? "Retirer du Dock" : "Garder dans le Dock"
                            checked: dockRoot.menuIsPinned
                            onActivated: {
                                dockRoot.toggleKeepInDock()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            id: _autostartItem
                            visible: dockRoot.submenuKind === "options"
                            height:  visible ? 26 : 0
                            property bool _isAutostart: {
                                for (var i = 0; i < dockRoot.pinnedApps.length; i++) {
                                    if (dockRoot.pinnedApps[i].cmd.toLowerCase() === dockRoot.menuGroupKey)
                                        return !!dockRoot.pinnedApps[i].autostart
                                }
                                return false
                            }
                            label:   "Ouvrir à la connexion"
                            checked: _autostartItem._isAutostart
                            enabled: dockRoot.menuIsPinned && dockRoot.menuGroupKey !== ""
                            onActivated: {
                                dockRoot.toggleAutostart()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            visible: dockRoot.submenuKind === "assign"
                            height:  visible ? 26 : 0
                            label:   "Tous les bureaux"
                            checked: dockRoot.menuInstances.length > 0 && dockRoot.menuInstances[0].pinned === true
                            onActivated: {
                                dockRoot.assignAllDesktops()
                                dockRoot.closeContextMenu()
                            }
                        }

                        DockMenuItem {
                            visible: dockRoot.submenuKind === "assign"
                            height:  visible ? 26 : 0
                            label:   "Ce bureau"
                            checked: !(dockRoot.menuInstances.length > 0 && dockRoot.menuInstances[0].pinned === true)
                            onActivated: {
                                dockRoot.assignThisDesktop()
                                dockRoot.closeContextMenu()
                            }
                        }
                    }
                }
            }
        }
    }

    component DockMenuItem: Item {
        id: menuItem

        property string label:       ""
        property bool   hasSubmenu:  false
        property bool   enabled:     true
        property bool   destructive: false
        property bool   checked:     false

        signal activated()
        signal hoveredIn()

        width:  parent ? parent.width : 190
        height: visible ? 26 : 0

        Rectangle {
            anchors.fill: parent
            radius:       6
            color:        _mi.containsMouse && menuItem.enabled ? "#3d5ea6ff" : "transparent"
        }

        Text {
            anchors {
                left:           parent.left
                leftMargin:     10
                verticalCenter: parent.verticalCenter
            }
            text:           (menuItem.checked ? "✓  " : "") + menuItem.label
            color:          menuItem.enabled ? (menuItem.destructive ? "#ff6b6b" : "#f2f2f2") : "#66ffffff"
            font.pixelSize: 13
            renderType:     Text.NativeRendering
        }

        Text {
            visible: menuItem.hasSubmenu
            anchors {
                right:          parent.right
                rightMargin:    8
                verticalCenter: parent.verticalCenter
            }
            text:           "›"
            color:          "#aaffffff"
            font.pixelSize: 14
            renderType:     Text.NativeRendering
        }

        MouseArea {
            id: _mi
            anchors.fill: parent
            hoverEnabled: true
            enabled:      menuItem.enabled
            cursorShape:  Qt.PointingHandCursor
            onClicked: if (!menuItem.hasSubmenu) menuItem.activated()
            onContainsMouseChanged: if (containsMouse) menuItem.hoveredIn()
        }
    }

    component DockMenuDivider: Item {
        width:  parent ? parent.width : 190
        height: visible ? 9 : 0

        Rectangle {
            anchors {
                left:           parent.left
                right:          parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 1
            color:  "#22ffffff"
        }
    }

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
        property Item   menuTarget:    null
        property string groupKey:      ""
        property bool   isPinnedApp:   false
        property var    instances:     []
        property string menuMode:      "app"
        property real   menuYOffset:   0
        property bool   reorderable:   false
        property int    orderIndex:    -1
        property int    dragGroupId:   0
        property int    maxOrderIndex: 0

        readonly property int _visualShiftSlots: {
            if (!iconItem.reorderable || dockRoot.dragListId !== iconItem.dragGroupId || dockRoot.dragFromIndex < 0)
                return 0
            var from = dockRoot.dragFromIndex
            var to   = dockRoot.dragToIndex
            var idx  = iconItem.orderIndex
            if (idx === from) return to - from
            if (from < to && idx > from && idx <= to) return -1
            if (from > to && idx >= to && idx < from) return 1
            return 0
        }

        transform: Translate {
            x: iconItem._visualShiftSlots * (dockRoot.baseIconSize + dockRoot.iconSpacing)
        }

        z: (iconItem.reorderable && dockRoot.dragListId === iconItem.dragGroupId &&
            dockRoot.dragFromIndex === iconItem.orderIndex && dockRoot.dragFromIndex >= 0) ? 100 : 0

        signal clicked()
        signal reorderRequested(int fromIndex, int toIndex)

        readonly property real iconCenterX: x + dockRoot.baseIconSize / 2
        readonly property real slotWidth:   dockRoot.baseIconSize + dockRoot.iconSpacing
        readonly property real distSlots: {
            if (!dockHovered) return 999
            return Math.abs(mouseXInDock - iconCenterX) / slotWidth
        }
        readonly property real magFactor: {
            if (dockRoot.reorderDragActive) return 1.0
            if (!dockHovered) return 1.0
            var d       = distSlots
            var maxDist = 2.6
            if (d >= maxDist) return 1.0
            var t       = d / maxDist
            var falloff = (Math.cos(t * Math.PI) + 1) / 2
            return 1.0 + falloff * (dockRoot.magScale1 - 1.0)
        }

        width:  dockRoot.baseIconSize * magFactor
        height: dockRoot.baseIconSize + 14

        Behavior on width {
            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        Behavior on x {
            enabled: !_iconMa.pressed
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Item {
            id: _iconContainer
            anchors {
                bottom:           parent.bottom
                bottomMargin:     12 + (iconItem.magFactor - 1) * 34
                horizontalCenter: parent.horizontalCenter
            }
            width:           dockRoot.baseIconSize
            height:          dockRoot.baseIconSize
            transformOrigin: Item.Bottom
            scale:           iconItem.magFactor

            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }

            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
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
                layer.enabled:   ShellConfig.options.dockAppearance.monochromeIcons
                layer.effect: MultiEffect {
                    saturation: -1
                }
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
                property bool _dragArmed: false
                anchors.fill:    parent
                hoverEnabled:    true
                cursorShape:     Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                property real _pressLocalX:    0
                property int  _dragStartIndex: -1
                property real _appliedOffsetPx: 0
                onClicked: iconItem.clicked()
                onPressed: function(mouse) {
                    _dragArmed       = false
                    _pressLocalX     = mouse.x
                    _dragStartIndex  = iconItem.orderIndex
                    _appliedOffsetPx = 0
                }
                onCanceled: {
                    _dragArmed = false
                    dockRoot.reorderDragActive = false
                    dockRoot.dragListId        = 0
                    dockRoot.dragFromIndex     = -1
                    dockRoot.dragToIndex       = -1
                }
                onPositionChanged: function(mouse) {
                    if (!iconItem.reorderable || !pressed) return
                    if (!_dragArmed) {
                        if (Math.abs(mouse.x - _pressLocalX) < 6) return
                        _dragArmed = true
                        dockRoot.reorderDragActive = true
                        dockRoot.dragListId        = iconItem.dragGroupId
                        dockRoot.dragFromIndex      = _dragStartIndex
                        dockRoot.dragToIndex        = _dragStartIndex
                    }
                    var correctedX  = mouse.x + _appliedOffsetPx
                    var deltaX      = correctedX - _pressLocalX
                    var rawSlots    = deltaX / iconItem.slotWidth
                    var currentSlots = dockRoot.dragToIndex - _dragStartIndex
                    var margin      = 0.18
                    var newSlots    = currentSlots
                    if (rawSlots > currentSlots + 0.5 + margin || rawSlots < currentSlots - 0.5 - margin)
                        newSlots = Math.round(rawSlots)
                    var rawTarget  = _dragStartIndex + newSlots
                    var clamped    = Math.max(0, Math.min(rawTarget, iconItem.maxOrderIndex))
                    dockRoot.dragToIndex = clamped
                    _appliedOffsetPx = (clamped - _dragStartIndex) * iconItem.slotWidth
                }
                onReleased: function(mouse) {
                    var doReorder = _dragArmed && iconItem.reorderable && dockRoot.dragToIndex !== _dragStartIndex
                    var fromIdx   = _dragStartIndex
                    var toIdx     = dockRoot.dragToIndex
                    var groupId   = iconItem.dragGroupId
                    _dragArmed = false
                    dockRoot.reorderDragActive = false
                    dockRoot.dragListId        = 0
                    dockRoot.dragFromIndex     = -1
                    dockRoot.dragToIndex       = -1
                    if (doReorder) {
                        Qt.callLater(function() {
                            if (groupId === 1) dockRoot.reorderPinnedApps(fromIdx, toIdx)
                            else if (groupId === 2) dockRoot.reorderPinnedFiles(fromIdx, toIdx)
                        })
                    }
                }
                onContainsMouseChanged: {
                    if (containsMouse) {
                        _tipDelay.restart()
                    } else {
                        _tipDelay.stop()
                        dockRoot.tooltipVisible = false
                    }
                }
            }

            MouseArea {
                id: _iconMaRight
                anchors.fill:    parent
                acceptedButtons: Qt.RightButton
                cursorShape:     Qt.PointingHandCursor
                onClicked: {
                    var pt = iconItem.mapToItem(null, iconItem.width / 2, 0)
                    dockRoot.openContextMenu(pt.x, pt.y + iconItem.menuYOffset, iconItem.appName, iconItem.groupKey,
                                              iconItem.isPinnedApp, iconItem.instances, iconItem.appIconPath,
                                              iconItem.menuMode)
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
