import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    property real progress: 0
    property rect bar: Qt.rect(0, 0, 0, 0)
    property real barRadius: 30
    property real bubbleCenterY: 0
    property real rightEdge: 0
    property real bubbleRadius: 29
    property real bubbleGap: 10
    property real neckSmoothing: 26
    property real rimWidth: 1.6
    property color baseColor: "#c01e1e1e"
    property color rimColor: "#20ffffff"
    property vector2d lightDir: Qt.vector2d(1, 1)

    property Item backdrop: GlassRegistry.lookup(QsWindow.window)
    readonly property bool glassOn: backdrop !== null && backdrop.ready && backdrop.captureSettled
    property point screenOrigin: Qt.point(0, 0)

    function syncOrigin() {
        if (!root.backdrop)
            return
        var p = root.mapToItem(null, 0, 0)
        var wp = root.backdrop.windowPosition
        var nx = wp.x + p.x
        var ny = wp.y + p.y
        if (nx !== root.screenOrigin.x || ny !== root.screenOrigin.y)
            root.screenOrigin = Qt.point(nx, ny)
    }

    onXChanged: syncOrigin()
    onYChanged: syncOrigin()
    onWidthChanged: syncOrigin()
    onHeightChanged: syncOrigin()
    onBackdropChanged: syncOrigin()
    Component.onCompleted: syncOrigin()

    Connections {
        target: root.Window.window
        ignoreUnknownSignals: true

        function onAfterAnimating() {
            root.syncOrigin()
        }
    }

    readonly property real pad: 24
    readonly property real totalDuration: ShellMotion.split() + 3 * ShellMotion.stagger()

    function smooth(t) {
        const c = Math.max(0, Math.min(1, t))
        return c * c * (3 - 2 * c)
    }

    readonly property var buds: {
        const split = Math.max(1, ShellMotion.split())
        const stagger = ShellMotion.stagger()
        const out = []
        let edge = root.bar.x + root.bar.width
        for (let i = 0; i < 4; i++) {
            const t = Math.max(0, Math.min(1, (root.progress * root.totalDuration - i * stagger) / split))
            if (t <= 0) {
                out.push({ x: edge, y: root.bubbleCenterY, r: 0, k: 0, t: 0 })
                continue
            }
            const r = root.bubbleRadius * root.smooth(t / 0.55)
            const overlap = 0.55 * r + (-root.bubbleGap - 0.55 * r) * root.smooth(t)
            const cx = edge + r - overlap
            const k = root.neckSmoothing * (1 - root.smooth((t - 0.5) / 0.5))
            out.push({ x: cx, y: root.bubbleCenterY, r: r, k: k, t: t })
            edge = cx + r
        }
        return out
    }

    x: root.bar.x - root.pad
    y: root.bar.y - root.pad
    width: root.rightEdge - root.bar.x + 2 * root.pad
    height: root.bar.height + 2 * root.pad

    function budVector(i) {
        const b = root.buds[i]
        return Qt.vector4d(b.x - root.x, b.y - root.y, b.r, b.k)
    }

    ShaderEffect {
        anchors.fill: parent
        blending: true
        property vector2d itemSize: Qt.vector2d(root.width, root.height)
        property vector4d bar: Qt.vector4d(root.pad, root.pad, root.bar.width, root.bar.height)
        property real barRadius: root.barRadius
        property real rimWidth: root.rimWidth
        property vector2d lightDir: root.lightDir
        property vector4d baseColor: root.glassOn ? Qt.vector4d(0, 0, 0, 0) : Qt.vector4d(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseColor.a)
        property vector4d rimColor: root.glassOn ? Qt.vector4d(0, 0, 0, 0) : Qt.vector4d(root.rimColor.r, root.rimColor.g, root.rimColor.b, root.rimColor.a)
        property vector4d bud0: root.budVector(0)
        property vector4d bud1: root.budVector(1)
        property vector4d bud2: root.budVector(2)
        property vector4d bud3: root.budVector(3)
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/splitglass.frag.qsb")
    }

    ShaderEffect {
        anchors.fill: parent
        blending: true
        visible: root.glassOn

        property variant backTex: root.backdrop ? root.backdrop.blurSource : null
        property vector2d itemSize: Qt.vector2d(root.width, root.height)
        property vector4d bar: Qt.vector4d(root.pad, root.pad, root.bar.width, root.bar.height)
        property real barRadius: root.barRadius
        property vector4d bud0: root.budVector(0)
        property vector4d bud1: root.budVector(1)
        property vector4d bud2: root.budVector(2)
        property vector4d bud3: root.budVector(3)
        property vector2d backgroundSize: root.backdrop ? Qt.vector2d(root.backdrop.screenSize.width, root.backdrop.screenSize.height) : Qt.vector2d(1, 1)
        property vector2d screenOrigin: Qt.vector2d(root.screenOrigin.x, root.screenOrigin.y)
        property vector2d halfpixel: root.backdrop ? Qt.vector2d(0.5 / root.backdrop.screenSize.width, 0.5 / root.backdrop.screenSize.height) : Qt.vector2d(0, 0)
        property real thickness: root.bar.height * 0.35
        property real refractionWidth: 18.0
        property real rgbDriftStrength: 2.88
        property real highlightWidth: 3.5
        property real highlightStrength: 0.1
        property real saturation: 1.33
        property real centerOpacity: 0.98

        vertexShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/SplitLiquidGlass.vert.qsb")
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/SplitLiquidGlass.frag.qsb")
    }
}
