import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components.glass

ShellRoot {
    id: appRoot

    readonly property string bgPath: Quickshell.env("LG_TEST_BG") ?? ""

    PanelWindow {
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "lgtest:wallpaper"
        exclusiveZone: -1
        anchors { top: true; left: true; right: true; bottom: true }
        color: "#000000"

        Image {
            anchors.fill: parent
            source: appRoot.bgPath !== "" ? "file://" + appRoot.bgPath : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
        }
    }

    PanelWindow {
        id: fullWin
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "lgtest:full"
        exclusiveZone: -1
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        mask: Region {}

        LiquidGlassBackdrop {
            id: fullBackdrop
            wallpaperPath: appRoot.bgPath
            screenSize: Qt.size(fullWin.screen.width, fullWin.screen.height)
            windowPosition: Qt.point(0, 0)
            captureWindows: true
            monitorName: fullWin.screen.name
        }

        LiquidGlass {
            backdrop: fullBackdrop
            width: 330
            height: 330
            x: (fullWin.width - width) / 2
            y: (fullWin.height - height) / 2
            noise: 0.1
            glowWeight: 0.3
            glowBias: 0.0
            glowEdge0: 0.06
            glowEdge1: 0.0
        }

        LiquidGlass {
            backdrop: fullBackdrop
            width: 110
            height: 44
            x: 120
            y: 520
            noise: 0.1
            glowWeight: 0.3
            glowBias: 0.0
            glowEdge0: 0.06
            glowEdge1: 0.0
        }
    }

    PanelWindow {
        id: dockWin
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "lgtest:dock"
        exclusiveZone: 0
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 140
        color: "transparent"
        mask: Region {}

        LiquidGlassBackdrop {
            id: dockBackdrop
            wallpaperPath: appRoot.bgPath
            screenSize: Qt.size(dockWin.screen.width, dockWin.screen.height)
            windowPosition: Qt.point(0, dockWin.screen.height - dockWin.height)
            captureWindows: true
            monitorName: dockWin.screen.name
            captureRegion: Qt.rect(0, dockWin.screen.height - dockWin.height, dockWin.screen.width, dockWin.height)
        }

        LiquidGlass {
            backdrop: dockBackdrop
            width: 520
            height: 72
            x: (dockWin.width - width) / 2
            y: dockWin.height - height - 24
            noise: 0.06
            glowWeight: 0.3
            glowBias: 0.0
            glowEdge0: 0.06
            glowEdge1: 0.0
        }
    }
}
