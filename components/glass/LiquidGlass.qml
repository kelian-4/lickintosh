import QtQuick
import Quickshell

Item {
    id: root

    property string backdropPath: ""
    property size screenSize: Qt.size(1920, 1080)
    property point screenPosition: Qt.point(0, 0)

    property real powerFactor: 3.0
    property real a: 0.7
    property real b: 2.3
    property real c: 5.2
    property real d: 6.9
    property real fPower: 1.0
    property real noise: 0.06
    property real glowWeight: 0.25
    property real glowBias: 0.0
    property real glowEdge0: 0.5
    property real glowEdge1: -0.5

    property real blurRadius: 2.0
    property real blurDownscale: 0.5
    property real aa: 1

    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/liquidglass/"

    Item {
        id: scene
        visible: false
        width: root.screenSize.width
        height: root.screenSize.height

        Image {
            anchors.fill: parent
            source: root.backdropPath !== "" ? "file://" + root.backdropPath : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            sourceSize: Qt.size(scene.width, scene.height)
        }
    }

    ShaderEffectSource {
        id: fb
        visible: false
        sourceItem: scene
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

    ShaderEffect {
        id: glass
        anchors.fill: parent
        blending: true

        property variant u_Slots5: blurFinal
        property vector2d v_MidPoint: Qt.vector2d(
            2.0 * (root.screenPosition.x + root.width / 2) / root.screenSize.width - 1.0,
            1.0 - 2.0 * (root.screenPosition.y + root.height / 2) / root.screenSize.height
        )
        property vector2d v_QuadNDC2ScreenNDCScale: Qt.vector2d(
            root.width / root.screenSize.width,
            root.height / root.screenSize.height
        )
        property real u_powerFactor: root.powerFactor
        property real u_a: root.a
        property real u_b: root.b
        property real u_c: root.c
        property real u_d: root.d
        property real u_fPower: root.fPower
        property real u_noise: root.noise
        property real u_glowWeight: root.glowWeight
        property real u_glowBias: root.glowBias
        property real u_glowEdge0: root.glowEdge0
        property real u_glowEdge1: root.glowEdge1

        vertexShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlass.vert.qsb")
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "LiquidGlass.frag.qsb")
    }
}
