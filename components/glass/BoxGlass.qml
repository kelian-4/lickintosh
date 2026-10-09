import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Effects
import qs.services

Item {
    id: box

    property color color: "#10000000"
    property bool highlightEnabled: true
    property bool transparent: false
    
    property color light: '#40ffffff'
    property vector2d   lightDir: Qt.vector2d(1, 1)
    property real  rimSize: 0.01
    property real  rimStrength: 1.0

    property var negLight: ""
    property var highlight: ""
    property var shadowOpacity: ""

    
    property real radius: 50

    property int animationSpeed: 16
    property int animationSpeed2: 16

    property Item backdrop: null

    readonly property real glassCorner: Math.min(Math.min(width, height) / 2, radius)
    readonly property bool glassWanted: GlassSettings.enabled
        && !transparent
        && color.a > GlassSettings.minAlpha
        && color.a < 0.99
        && Math.min(width, height) >= GlassSettings.minSize

    Behavior on color { PropertyAnimation { duration: animationSpeed; easing.type: Easing.InSine } }

    function ensureBackdrop() {
        if (!glassWanted || backdrop !== null)
            return
        var win = box.QsWindow.window
        if (!win || !win.contentItem)
            return
        var host = win.contentItem
        for (var i = 0; i < host.children.length; i++) {
            if (host.children[i].objectName === "liquidGlassBackdrop") {
                backdrop = host.children[i]
                return
            }
        }
        backdrop = backdropComponent.createObject(host, { hostWindow: win })
    }

    onGlassWantedChanged: ensureBackdrop()
    Component.onCompleted: ensureBackdrop()

    Timer {
        interval: 100
        repeat: true
        running: box.glassWanted && box.backdrop === null
        onTriggered: box.ensureBackdrop()
    }

    Component {
        id: backdropComponent

        LiquidGlassBackdrop {
            objectName: "liquidGlassBackdrop"

            property var hostWindow: null

            readonly property string monitor: hostWindow && hostWindow.screen ? hostWindow.screen.name : ""
            readonly property var layerPos: GlassLayers.lookup(
                monitor,
                hostWindow ? hostWindow.width : 0,
                hostWindow ? hostWindow.height : 0,
                GlassLayers.revision
            )

            ready: layerPos !== null && wallpaperPath !== ""
            wallpaperPath: ShellConfig.options.wallpaper.path
            screenSize: hostWindow && hostWindow.screen ? Qt.size(hostWindow.screen.width, hostWindow.screen.height) : Qt.size(1, 1)
            windowPosition: layerPos ? Qt.point(layerPos.x, layerPos.y) : Qt.point(0, 0)
            monitorName: monitor
            captureWindows: GlassSettings.captureWindows && ready
            captureRegion: Qt.rect(
                windowPosition.x,
                windowPosition.y,
                hostWindow ? hostWindow.width : 0,
                hostWindow ? hostWindow.height : 0
            )
            blurRadius: GlassSettings.blurRadius
        }
    }

    LiquidGlass {
        anchors.fill: parent
        visible: box.glassWanted && box.backdrop !== null
        backdrop: box.backdrop
        cornerRadius: box.glassCorner
        noise: GlassSettings.noise
        glowWeight: GlassSettings.glowWeight
        glowBias: 0.0
        glowEdge0: 0.06
        glowEdge1: 0.0
    }

    GlassRim {
        id: boxContainer
        anchors.fill: parent
        baseColor: box.transparent ? "transparent" : box.color
        radius: box.radius
        glowColor: box.highlightEnabled ? box.light : "#00000000"
        lightDir: box.lightDir
        glowEdgeBand: box.rimSize
    }
}
