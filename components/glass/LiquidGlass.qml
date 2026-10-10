import QtQuick
import Quickshell

Item {
    id: root

    property Item backdrop: null

    property real cornerRadius: -1
    property vector2d lightDir: Qt.vector2d(-1, 1)
    property real rimWidth: 1.6
    property real rimStrength: 0.0
    property real sheenWidth: 10
    property real sheenStrength: 0.0
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

    property point screenPosition: Qt.point(0, 0)

    readonly property bool active: backdrop !== null && backdrop.ready && backdrop.captureSettled
    property real level: active ? 1 : 0

    Behavior on level { NumberAnimation { duration: GlassSettings.fadeDuration; easing.type: Easing.InOutSine } }

    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/liquidglass/"
    readonly property size screenSize: backdrop ? backdrop.screenSize : Qt.size(1, 1)

    function updatePosition() {
        if (!root.backdrop)
            return
        var p = root.mapToItem(null, 0, 0)
        var wp = root.backdrop.windowPosition
        var nx = wp.x + p.x
        var ny = wp.y + p.y
        if (nx !== root.screenPosition.x || ny !== root.screenPosition.y)
            root.screenPosition = Qt.point(nx, ny)
    }

    onBackdropChanged: updatePosition()
    onXChanged: updatePosition()
    onYChanged: updatePosition()
    onWidthChanged: updatePosition()
    onHeightChanged: updatePosition()
    onParentChanged: updatePosition()
    Component.onCompleted: updatePosition()

    Connections {
        target: root.Window.window
        ignoreUnknownSignals: true

        function onAfterAnimating() {
            root.updatePosition()
        }
    }

    ShaderEffect {
        anchors.fill: parent
        blending: true
        visible: root.level > 0 && root.width > 0 && root.height > 0
        opacity: root.level

        property variant u_Slots5: root.backdrop ? root.backdrop.blurSource : null
        property vector2d v_MidPoint: Qt.vector2d(
            2.0 * (root.screenPosition.x + root.width / 2) / root.screenSize.width - 1.0,
            1.0 - 2.0 * (root.screenPosition.y + root.height / 2) / root.screenSize.height
        )
        property vector2d v_QuadNDC2ScreenNDCScale: Qt.vector2d(
            root.width / root.screenSize.width,
            root.height / root.screenSize.height
        )
        property vector2d u_size: Qt.vector2d(root.width, root.height)
        property real u_cornerRadius: root.cornerRadius
        property vector2d u_lightDir: root.lightDir
        property real u_rimWidth: root.rimWidth
        property real u_rimStrength: root.rimStrength
        property real u_sheenWidth: root.sheenWidth
        property real u_sheenStrength: root.sheenStrength
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
