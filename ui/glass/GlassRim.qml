import QtQuick
import Quickshell

Item {
    id: box

    property real     radius:       20.0
    property real     smallerVal:   Math.min(width, height)
    property vector4d cornerRadii:  Qt.vector4d(
        Math.min(smallerVal/2, radius),
        Math.min(smallerVal/2, radius),
        Math.min(smallerVal/2, radius),
        Math.min(smallerVal/2, radius)
    )
    property vector2d iResolution:  Qt.vector2d(width + 2, height + 2)
    property vector2d boxSize:      Qt.vector2d(width / 2, height / 2)
    property color    glowColor:    Qt.rgba(1, 1, 1, 0.15)
    property real     glowEdgeBand: 0.04
    property color    baseColor:    "#10000000"
    property vector2d lightDir:     Qt.vector2d(1.0, 1.0)

    layer.enabled: true
    layer.smooth:  true

    ShaderEffect {
        anchors.fill:    parent
        blending:        true
        property vector2d iResolution:  box.iResolution
        property vector2d boxSize:      box.boxSize
        property vector4d cornerRadii:  box.cornerRadii
        property vector4d glowColor:    Qt.vector4d(box.glowColor.r, box.glowColor.g, box.glowColor.b, box.glowColor.a)
        property real     glowEdgeBand: box.glowEdgeBand
        property vector4d baseColor:    Qt.vector4d(box.baseColor.r, box.baseColor.g, box.baseColor.b, box.baseColor.a)
        property vector2d lightDir:     box.lightDir
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/grxframe.frag.qsb")
        vertexShader:   Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/grxframe.vert.qsb")
    }
}
