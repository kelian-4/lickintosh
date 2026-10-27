import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: root

    property Item backdrop: null

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
    property real cornerRadius: 0
    property real supersample: 1.0

    property point screenPosition: Qt.point(0, 0)
    property size screenExtent: Qt.size(0, 0)
    readonly property real effectiveWidth: screenExtent.width > 0 ? screenExtent.width : width
    readonly property real effectiveHeight: screenExtent.height > 0 ? screenExtent.height : height

    readonly property bool active: backdrop !== null && backdrop.ready && backdrop.captureSettled
    property real level: active ? 1 : 0

    Behavior on level { NumberAnimation { duration: 120; easing.type: Easing.InOutSine } }

    property Item registeredBackdrop: null

    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/liquidglass/"
    readonly property size screenSize: backdrop ? backdrop.screenSize : Qt.size(1, 1)

    function updatePosition() {
        if (!root.backdrop)
            return
        var p = root.mapToItem(null, 0, 0)
        var q = root.mapToItem(null, root.width, root.height)
        var wp = root.backdrop.windowPosition
        var nx = wp.x + p.x
        var ny = wp.y + p.y
        var ew = q.x - p.x
        var eh = q.y - p.y
        if (nx !== root.screenPosition.x || ny !== root.screenPosition.y)
            root.screenPosition = Qt.point(nx, ny)
        if (ew !== root.screenExtent.width || eh !== root.screenExtent.height)
            root.screenExtent = Qt.size(ew, eh)
    }

    function syncRegistration() {
        if (root.registeredBackdrop === root.backdrop)
            return
        if (root.registeredBackdrop)
            root.registeredBackdrop.unregisterQuad(root)
        root.registeredBackdrop = root.backdrop
        if (root.backdrop)
            root.backdrop.registerQuad(root)
    }

    function invalidate() {
        if (root.backdrop)
            root.backdrop.invalidateRegion()
    }

    onBackdropChanged: {
        syncRegistration()
        updatePosition()
    }
    onXChanged: updatePosition()
    onYChanged: updatePosition()
    onWidthChanged: {
        updatePosition()
        invalidate()
    }
    onHeightChanged: {
        updatePosition()
        invalidate()
    }
    onParentChanged: updatePosition()
    onVisibleChanged: invalidate()
    onScreenPositionChanged: invalidate()
    Component.onCompleted: {
        syncRegistration()
        updatePosition()
    }
    Component.onDestruction: {
        if (root.registeredBackdrop)
            root.registeredBackdrop.unregisterQuad(root)
    }

    Connections {
        target: root.Window.window
        ignoreUnknownSignals: true

        function onAfterAnimating() {
            root.updatePosition()
        }
    }

    Item {
        id: glassLayer
        anchors.fill: parent
        layer.enabled: root.cornerRadius > 0 || root.supersample > 1
        layer.smooth: true
        layer.textureSize: root.supersample > 1
            ? Qt.size(Math.max(1, Math.ceil(root.width * root.supersample)), Math.max(1, Math.ceil(root.height * root.supersample)))
            : Qt.size(0, 0)
        layer.effect: root.cornerRadius > 0 ? maskEffect : null

        ShaderEffect {
            anchors.fill: parent
            blending: true
            visible: root.level > 0 && root.width > 0 && root.height > 0
            opacity: root.level

            property variant u_Slots5: root.backdrop ? root.backdrop.blurSource : null
            property vector2d v_MidPoint: Qt.vector2d(
                2.0 * (root.screenPosition.x + root.effectiveWidth / 2) / root.screenSize.width - 1.0,
                1.0 - 2.0 * (root.screenPosition.y + root.effectiveHeight / 2) / root.screenSize.height
            )
            property vector2d v_QuadNDC2ScreenNDCScale: Qt.vector2d(
                root.effectiveWidth / root.screenSize.width,
                root.effectiveHeight / root.screenSize.height
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

    Component {
        id: maskEffect

        MultiEffect {
            maskEnabled: true
            maskSource: glassMask
        }
    }

    Rectangle {
        id: glassMask
        anchors.fill: parent
        radius: root.cornerRadius
        visible: false
        layer.enabled: root.cornerRadius > 0
        layer.smooth: true
    }
}
