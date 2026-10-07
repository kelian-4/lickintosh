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
        id: panel
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "lgtest:panel"
        exclusiveZone: -1
        implicitWidth: 330
        implicitHeight: 330
        color: "transparent"

        LiquidGlass {
            anchors.fill: parent
            screenSize: Qt.size(panel.screen.width, panel.screen.height)
            screenPosition: Qt.point((panel.screen.width - width) / 2, (panel.screen.height - height) / 2)
            backdropPath: appRoot.bgPath
            powerFactor: 3.0
            blurRadius: 2.0
            blurDownscale: 0.5
            noise: 0.1
            fPower: 1.0
            glowWeight: 0.3
            glowBias: 0.0
            glowEdge0: 0.06
            glowEdge1: 0.0
        }
    }
}
