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

    readonly property real glassLevel: box.glassWanted && box.backdrop !== null ? liquid.level : 0

    LiquidGlass {
        id: liquid
        anchors.fill: parent
        visible: box.glassWanted && box.backdrop !== null
        backdrop: box.backdrop
        cornerRadius: box.glassCorner
        b: GlassSettings.refractionB
        d: GlassSettings.refractionD
        fPower: GlassSettings.refractionPower
        noise: GlassSettings.noise
        glowWeight: GlassSettings.glowWeight
        glowBias: 0.0
        glowEdge0: GlassSettings.glowEdge0
        glowEdge1: GlassSettings.glowEdge1
        lightDir: Qt.vector2d(box.lightDir.x, -box.lightDir.y)
        rimWidth: GlassSettings.rimWidth
        rimStrength: box.highlightEnabled
            ? GlassSettings.rimStrength * box.rimStrength * Math.max(0, Math.min(1.6, box.light.a / 0.5))
            : 0
        sheenWidth: GlassSettings.sheenWidth
        sheenStrength: box.highlightEnabled ? GlassSettings.sheenStrength : 0
    }

    Rectangle {
        anchors.fill: parent
        radius: box.glassCorner
        color: Qt.rgba(1, 1, 1, GlassSettings.veil * box.glassLevel)
        visible: box.glassLevel > 0
    }

    GlassRim {
        id: boxContainer
        anchors.fill: parent
        baseColor: box.transparent ? "transparent" : Qt.rgba(
            box.color.r,
            box.color.g,
            box.color.b,
            box.color.a * (1 - (1 - GlassSettings.tintScale) * box.glassLevel)
        )
        radius: box.radius
        glowColor: box.highlightEnabled
            ? Qt.rgba(box.light.r, box.light.g, box.light.b, box.light.a * (1 - box.glassLevel))
            : "#00000000"
        lightDir: box.lightDir
        glowEdgeBand: box.rimSize
    }
}
