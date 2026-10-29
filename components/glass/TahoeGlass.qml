import QtQuick
import Quickshell

Item {
    id: root

    property Item backdrop: null

    property real cornerRadius: 20.0
    property real cornerSquircle: 0.0
    property real refractionWidth: 18.0
    property real magnifyGlassStrength: 0.1
    property real rgbDriftStrength: 12.0
    property real highlightWidth: 3.5
    property real highlightStrength: 0.1
    property real saturation: 1.33
    property real materialOpacity: 1.0
    property real centerOpacity: 0.98

    property point screenPosition: Qt.point(0, 0)
    property size screenExtent: Qt.size(0, 0)
    readonly property real effectiveWidth: screenExtent.width > 0 ? screenExtent.width : width
    readonly property real effectiveHeight: screenExtent.height > 0 ? screenExtent.height : height
    readonly property real extentScale: width > 0 ? effectiveWidth / width : 1

    readonly property bool active: backdrop !== null && backdrop.ready && backdrop.captureSettled
    property real level: active ? 1 : 0

    Behavior on level {
        NumberAnimation {
            duration: root.backdrop && root.backdrop.instantReveal ? 0 : 120
            easing.type: Easing.InOutSine
        }
    }

    property Item registeredBackdrop: null

    readonly property string shaderDir: Quickshell.shellDir + "/assets/shaders/tahoeglass/"
    readonly property size screenSize: backdrop ? backdrop.screenSize : Qt.size(1, 1)
    readonly property real clampedRadius: Math.max(0, Math.min(cornerRadius, Math.min(width, height) / 2))
    readonly property real screenRadius: clampedRadius * extentScale

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

    ShaderEffect {
        anchors.fill: parent
        blending: true
        visible: root.level > 0 && root.width > 0 && root.height > 0
        opacity: root.level

        property variant texUnit: root.backdrop ? root.backdrop.blurSource : null
        property matrix4x4 colorMatrix: Qt.matrix4x4(
            (1.0 - root.saturation) * 0.2126 + root.saturation, (1.0 - root.saturation) * 0.2126, (1.0 - root.saturation) * 0.2126, 0.0,
            (1.0 - root.saturation) * 0.7152, (1.0 - root.saturation) * 0.7152 + root.saturation, (1.0 - root.saturation) * 0.7152, 0.0,
            (1.0 - root.saturation) * 0.0722, (1.0 - root.saturation) * 0.0722, (1.0 - root.saturation) * 0.0722 + root.saturation, 0.0,
            0.0, 0.0, 0.0, 1.0
        )
        property vector4d cornerRadius: Qt.vector4d(root.screenRadius, root.screenRadius, root.screenRadius, root.screenRadius)
        property vector2d blurSize: Qt.vector2d(root.effectiveWidth, root.effectiveHeight)
        property vector2d backgroundSize: Qt.vector2d(root.screenSize.width, root.screenSize.height)
        property vector2d screenOrigin: Qt.vector2d(root.screenPosition.x, root.screenPosition.y)
        property vector2d halfpixel: Qt.vector2d(0.5 / root.screenSize.width, 0.5 / root.screenSize.height)
        property real cornerSquircle: root.cornerSquircle
        property real rgbDriftStrength: root.rgbDriftStrength * 0.24
        property real magnifyGlassStrength: root.magnifyGlassStrength
        property real refractionWidth: root.refractionWidth
        property real highlightWidth: root.highlightWidth
        property real highlightStrength: root.highlightStrength
        property real materialOpacity: root.materialOpacity
        property real centerOpacity: root.centerOpacity

        vertexShader: Qt.resolvedUrl(root.shaderDir + "TahoeGlass.vert.qsb")
        fragmentShader: Qt.resolvedUrl(root.shaderDir + "TahoeGlass.frag.qsb")
    }
}
