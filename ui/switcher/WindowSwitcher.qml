import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components.glass
import qs.components
import qs.services

Scope {
    id: root

    property bool opened: false
    property var apps: []
    property int index: 0
    property var mru: []
    property var pending: null

    function normalize(address) {
        var a = String(address || "").toLowerCase()
        if (a === "") return ""
        return a.indexOf("0x") === 0 ? a : "0x" + a
    }

    function hyprFor(handle) {
        var list = Hyprland.toplevels.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].wayland === handle) return list[i]
        }
        return null
    }

    function track() {
        var t = ToplevelManager.activeToplevel
        if (!t) return
        var list = [t]
        for (var i = 0; i < root.mru.length && list.length < 80; i++) {
            if (root.mru[i] !== t) list.push(root.mru[i])
        }
        root.mru = list
    }

    function build() {
        try { Hyprland.refreshToplevels() } catch (e) {}
        var all = []
        var vals = ToplevelManager.toplevels.values
        for (var i = 0; i < vals.length; i++) all.push(vals[i])

        var order = []
        var active = ToplevelManager.activeToplevel
        if (active && all.indexOf(active) >= 0) order.push(active)
        for (var m = 0; m < root.mru.length; m++) {
            if (all.indexOf(root.mru[m]) >= 0 && order.indexOf(root.mru[m]) < 0) order.push(root.mru[m])
        }
        for (var j = 0; j < all.length; j++) {
            if (order.indexOf(all[j]) < 0) order.push(all[j])
        }

        var seen = {}
        var out = []
        for (var k = 0; k < order.length; k++) {
            var t = order[k]
            var cls = t.appId || ""
            if (cls === "") continue
            if (seen[cls] !== undefined) {
                out[seen[cls]].count++
                continue
            }
            var entry = DesktopEntries.heuristicLookup(cls)
            var icon = entry && entry.icon ? IconResolver.byName(entry.icon) : ""
            if (icon === "") icon = IconResolver.byName(cls)
            if (icon === "") icon = IconResolver.byName(cls.toLowerCase())
            if (icon === "") icon = IconResolver.generic()
            var h = root.hyprFor(t)
            var ipc = h && h.lastIpcObject ? h.lastIpcObject : {}
            seen[cls] = out.length
            out.push({
                cls: cls,
                name: entry && entry.name ? entry.name : cls,
                icon: icon,
                handle: t,
                addr: h ? root.normalize(h.address) : "",
                ws: ipc.workspace && ipc.workspace.id ? ipc.workspace.id : 0,
                count: 1
            })
        }
        console.log("[switcher] windows=" + all.length + " apps=" + out.length)
        return out
    }

    function step(direction) {
        if (!root.opened) {
            var list = root.build()
            if (list.length === 0) return
            root.apps = list
            root.index = 0
            root.opened = true
        }
        var n = root.apps.length
        if (n === 0) return
        root.index = (root.index + (direction >= 0 ? 1 : n - 1)) % n
        idleTimer.restart()
    }

    function cancel() {
        idleTimer.stop()
        root.opened = false
    }

    function commit() {
        if (!root.opened) return
        idleTimer.stop()
        var target = root.apps[root.index]
        root.opened = false
        if (!target) return
        root.pending = target
        focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: {
            var t = root.pending
            root.pending = null
            if (!t) return
            if (t.addr !== "") {
                Hyprland.dispatch('hl.dsp.focus({ window = "address:' + t.addr + '" })')
                if (t.ws > 0) Hyprland.dispatch('hl.dsp.focus({ workspace = "' + t.ws + '" })')
                Hyprland.dispatch('hl.dsp.window.bring_to_top()')
            } else if (t.handle) {
                t.handle.activate()
            }
        }
    }

    Timer {
        id: idleTimer
        interval: 6000
        onTriggered: root.commit()
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { root.track() }
    }

    IpcHandler {
        target: "switcher"
        function next(): void { root.step(1) }
        function prev(): void { root.step(-1) }
        function commit(): void { root.commit() }
        function cancel(): void { root.cancel() }
    }

    Component.onCompleted: root.track()

    GlobalShortcut {
        name: "switcher-next"
        description: "Next application"
        onPressed: root.step(1)
    }

    GlobalShortcut {
        name: "switcher-prev"
        description: "Previous application"
        onPressed: root.step(-1)
    }

    Loader {
        active: root.opened

        sourceComponent: PanelWindow {
            id: win

            screen: {
                var focused = Hyprland.focusedMonitor
                if (focused) {
                    var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
                    if (s) return s
                }
                return Quickshell.screens[0]
            }

            readonly property int count: root.apps.length
            readonly property real maxWidth: Math.max(240, (screen ? screen.width : 1200) - 120)
            readonly property real cell: Math.max(52, Math.min(96, (maxWidth - 40) / Math.max(1, count)))
            readonly property real iconSize: cell * 0.7

            WlrLayershell.namespace: "quickshell:switcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: count * cell + 40
            implicitHeight: cell + 78

            GlassBackdrop { id: backdrop; element: "osd" }

            Item {
                id: panel
                anchors.fill: parent
                focus: true
                opacity: 0
                scale: 0.96

                Component.onCompleted: {
                    forceActiveFocus()
                    opacity = 1
                    scale = 1
                }

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) root.step(1)
                    else if (event.key === Qt.Key_Backtab) root.step(-1)
                    else if (event.key === Qt.Key_Right) root.step(1)
                    else if (event.key === Qt.Key_Left) root.step(-1)
                    else if (event.key === Qt.Key_Escape) root.cancel()
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.commit()
                    else return
                    event.accepted = true
                }

                Keys.onReleased: function(event) {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
                        root.commit()
                        event.accepted = true
                    }
                }

                BoxGlass {
                    anchors.fill: parent
                    backdrop: backdrop
                    radius: 30
                    color: "#30000000"
                    light: "#55ffffff"
                    rimSize: 0.014
                    rimStrength: 1.1
                }

                Row {
                    id: row
                    anchors.top: parent.top
                    anchors.topMargin: 18
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: root.apps

                        Item {
                            id: cellItem
                            required property var modelData
                            required property int index
                            width: win.cell
                            height: win.cell

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: 20
                                color: "#33ffffff"
                                visible: cellItem.index === root.index
                            }

                            Image {
                                anchors.centerIn: parent
                                width: win.iconSize
                                height: win.iconSize
                                source: cellItem.modelData.icon
                                sourceSize.width: 128
                                sourceSize.height: 128
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.index = cellItem.index
                                    root.commit()
                                }
                            }
                        }
                    }
                }

                CFText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: 15
                    text: {
                        var a = root.apps[root.index]
                        if (!a) return ""
                        return a.count > 1 ? a.name + "  (" + a.count + ")" : a.name
                    }
                }
            }
        }
    }
}
