import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property string monitorName: ""
    property rect region: Qt.rect(0, 0, 100000, 100000)

    readonly property var monitorObject: {
        var ms = Hyprland.monitors.values
        for (var i = 0; i < ms.length; i++) {
            if (ms[i].name === root.monitorName)
                return ms[i]
        }
        return null
    }
    readonly property real monitorX: monitorObject && monitorObject.lastIpcObject ? (monitorObject.lastIpcObject.x ?? 0) : 0
    readonly property real monitorY: monitorObject && monitorObject.lastIpcObject ? (monitorObject.lastIpcObject.y ?? 0) : 0

    Component.onCompleted: GlassLayers.captureUsers++
    Component.onDestruction: GlassLayers.captureUsers--

    Repeater {
        model: Hyprland.toplevels

        ScreencopyView {
            id: view

            required property var modelData

            readonly property var ipc: modelData.lastIpcObject
            readonly property bool shown: ipc !== undefined && ipc !== null
                && modelData.wayland !== null
                && modelData.monitor !== null
                && modelData.monitor.name === root.monitorName
                && modelData.workspace !== null
                && modelData.workspace.active
                && ipc.hidden !== true
                && ipc.mapped !== false
                && ipc.at !== undefined && ipc.size !== undefined
                && (ipc.at[0] - root.monitorX) < (root.region.x + root.region.width)
                && (ipc.at[0] - root.monitorX + ipc.size[0]) > root.region.x
                && (ipc.at[1] - root.monitorY) < (root.region.y + root.region.height)
                && (ipc.at[1] - root.monitorY + ipc.size[1]) > root.region.y
            readonly property real rank: ipc && ipc.focusHistoryID !== undefined ? ipc.focusHistoryID : 0

            captureSource: shown ? modelData.wayland : null
            live: true
            visible: shown
            x: ipc && ipc.at ? ipc.at[0] - root.monitorX : 0
            y: ipc && ipc.at ? ipc.at[1] - root.monitorY : 0
            width: ipc && ipc.size ? ipc.size[0] : 0
            height: ipc && ipc.size ? ipc.size[1] : 0
            z: (ipc && ipc.floating ? 1000 : 0) - rank
        }
    }
}
