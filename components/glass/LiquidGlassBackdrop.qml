import QtQuick
import Quickshell

Item {
    id: root

    property string wallpaperPath: ""
    property size screenSize: Qt.size(1920, 1080)
    property point windowPosition: Qt.point(0, 0)

    property bool captureWindows: false
    property string monitorName: ""
    property rect captureRegion: Qt.rect(0, 0, screenSize.width, screenSize.height)

    property real blurRadius: 2.0
    property real blurDownscale: 0.5
    property real aa: 1
    property bool ready: true

    readonly property Item blurSource: blurFinal
    readonly property bool captureSettled: !captureWindows || (windowsLoader.item !== null && windowsLoader.item.latched)
    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/liquidglass/"

    width: 0
    height: 0

    Component.onCompleted: GlassLayers.users++
    Component.onDestruction: GlassLayers.users--

    Item {
        id: scene
        width: root.screenSize.width
        height: root.screenSize.height

        Image {
            anchors.fill: parent
            source: root.ready && root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
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
