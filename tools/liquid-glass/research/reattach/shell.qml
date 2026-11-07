import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        id: win
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "reattach"
        exclusiveZone: -1
        anchors { bottom: true; left: true }
        implicitWidth: 1080
        implicitHeight: 260
        color: "#303030"

        property var tl: ToplevelManager.toplevels.values.length > 0 ? ToplevelManager.toplevels.values[0] : null
        property bool attached: true

        ScreencopyView {
            id: v1
            x: 0
            width: 350
            height: 260
            captureSource: win.attached ? win.tl : null
            live: true
            onHasContentChanged: console.log("RA v1 hasContent", hasContent, "attached", win.attached, "t", Date.now() % 1000000)
        }

        ScreencopyView {
            id: v2
            x: 365
            width: 350
            height: 260
            visible: win.attached
            captureSource: win.attached ? win.tl : null
            live: true
            onHasContentChanged: console.log("RA v2 hasContent", hasContent, "attached", win.attached, "t", Date.now() % 1000000)
        }

        ScreencopyView {
            id: v3
            x: 730
            width: 350
            height: 260
            opacity: win.attached ? 1 : 0
            captureSource: win.tl
            live: true
            onHasContentChanged: console.log("RA v3 hasContent", hasContent, "attached", win.attached, "t", Date.now() % 1000000)
        }

        Timer {
            interval: 12000
            running: win.tl !== null
            repeat: true
            onTriggered: {
                win.attached = !win.attached
                console.log("RA toggle attached", win.attached, "t", Date.now() % 1000000)
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: console.log("RA state attached", win.attached, "v1", v1.hasContent, "v2", v2.hasContent, "v3", v3.hasContent, "t", Date.now() % 1000000)
        }
    }
}
