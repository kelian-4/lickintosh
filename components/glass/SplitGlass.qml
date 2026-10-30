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
        property vector4d baseColor: Qt.vector4d(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseColor.a)
        property vector4d rimColor: Qt.vector4d(root.rimColor.r, root.rimColor.g, root.rimColor.b, root.rimColor.a)
        property vector4d bud0: root.budVector(0)
        property vector4d bud1: root.budVector(1)
        property vector4d bud2: root.budVector(2)
        property vector4d bud3: root.budVector(3)
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/splitglass.frag.qsb")
    }
}
