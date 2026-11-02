import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lgprobe"
        exclusiveZone: -1
        anchors { bottom: true; left: true }
        implicitWidth: 700
        implicitHeight: 260
        color: "#303030"

        Repeater {
            model: ToplevelManager.toplevels

            ScreencopyView {
                id: view
                required property var modelData
                required property int index
                captureSource: modelData
                live: true
                x: 10 + index * 340
                y: 10
                width: 320
                height: 240
                onHasContentChanged: console.log("PROBE hasContent", modelData.title, hasContent, sourceSize.width, sourceSize.height)
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: {
                Hyprland.refreshToplevels()
                var n = ToplevelManager.toplevels.values.length
                console.log("PROBE wayland toplevels", n)
                var hv = Hyprland.toplevels.values
                for (var i = 0; i < hv.length; i++) {
                    var o = hv[i].lastIpcObject
                    console.log("PROBE hypr", hv[i].title, JSON.stringify(o.at), JSON.stringify(o.size), "floating", o.floating, "ws", JSON.stringify(o.workspace), "fs", o.fullscreen, "hidden", o.hidden)
                }
            }
        }
    }
}
