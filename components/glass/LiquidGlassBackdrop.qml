import QtQuick
import Quickshell

Item {
    id: root

    property string wallpaperPath: ""
    property size screenSize: Qt.size(1920, 1080)
    property point windowPosition: Qt.point(0, 0)

    property bool captureWindows: false
    property string monitorName: ""
    property rect captureRegion: glassRegion
    property rect glassRegion: Qt.rect(0, 0, 0, 0)
    property var quads: []
    property bool ready: true
    property bool warm: false

    property real blurRadius: 2.0
    property real blurDownscale: 0.5
    property real aa: GlassTracker.backdropScale

    readonly property Item blurSource: blurFinal
    readonly property bool captureSettled: warm && (!captureWindows || (windowsLoader.item !== null && windowsLoader.item.latched))
    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/liquidglass/"

    function registerQuad(q) {
        if (root.quads.indexOf(q) === -1)
            root.quads.push(q)
        regionTimer.restart()
    }

    function unregisterQuad(q) {
        var i = root.quads.indexOf(q)
        if (i !== -1)
            root.quads.splice(i, 1)
        regionTimer.restart()
    }

    function invalidateRegion() {
        regionTimer.restart()
    }

    function recomputeRegion() {
        var x0 = 1e9
        var y0 = 1e9
        var x1 = -1e9
        var y1 = -1e9
        var any = false
        for (var i = 0; i < root.quads.length; i++) {
            var q = root.quads[i]
            if (!q.visible || q.width <= 0 || q.height <= 0)
                continue
            any = true
            x0 = Math.min(x0, q.screenPosition.x)
            y0 = Math.min(y0, q.screenPosition.y)
            x1 = Math.max(x1, q.screenPosition.x + q.width)
            y1 = Math.max(y1, q.screenPosition.y + q.height)
        }
        var r = any ? Qt.rect(x0, y0, x1 - x0, y1 - y0) : Qt.rect(0, 0, 0, 0)
        if (r.x !== root.glassRegion.x || r.y !== root.glassRegion.y || r.width !== root.glassRegion.width || r.height !== root.glassRegion.height)
            root.glassRegion = r
    }

    onReadyChanged: {
        warm = false
        if (ready)
            warmTimer.restart()
    }

    Timer {
        id: regionTimer
        interval: 16
        onTriggered: root.recomputeRegion()
    }

    Timer {
        id: warmTimer
        interval: 50
        running: root.ready
        onTriggered: root.warm = true
    }

    width: 0
    height: 0

    Item {
        id: scene
        width: root.screenSize.width
        height: root.screenSize.height

        Image {
            anchors.fill: parent
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            sourceSize: Qt.size(scene.width, scene.height)
        }

        Loader {
            id: windowsLoader
            anchors.fill: parent
            active: root.captureWindows
            sourceComponent: GlassWindows {
                monitorName: root.monitorName
                region: root.captureRegion
            }
        }
    }

    ShaderEffectSource {
        id: fb
        visible: false
        live: root.ready
        sourceItem: scene
        hideSource: true
        textureSize: Qt.size(root.screenSize.width * root.aa, root.screenSize.height * root.aa)
    }

    ShaderEffect {
        id: blurH
        visible: false
        width: root.screenSize.width * root.aa * root.blurDownscale
        height: root.screenSize.height * root.aa * root.blurDownscale
        property variant u_in: fb
        property vector2d u_direction: Qt.vector2d(1.0, 0.0)
        property vector2d u_resolution: Qt.vector2d(fb.textureSize.width, fb.textureSize.height)
        property real u_radius: root.blurRadius
        vertexShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlassBlur.vert.qsb")
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlassBlur.frag.qsb")
    }

    ShaderEffectSource {
        id: blurIntermediate
        visible: false
        sourceItem: blurH
        textureSize: Qt.size(blurH.width, blurH.height)
    }

    ShaderEffect {
        id: blurV
        visible: false
        width: blurH.width
        height: blurH.height
        property variant u_in: blurIntermediate
        property vector2d u_direction: Qt.vector2d(0.0, 1.0)
        property vector2d u_resolution: Qt.vector2d(fb.textureSize.width, fb.textureSize.height)
        property real u_radius: root.blurRadius
        vertexShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlassBlur.vert.qsb")
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlassBlur.frag.qsb")
    }

    ShaderEffectSource {
        id: blurFinal
        visible: false
        sourceItem: blurV
        textureSize: Qt.size(blurV.width, blurV.height)
    }
}
