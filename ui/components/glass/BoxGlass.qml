import QtQuick
import Quickshell

Item {
    id: box

    property color    color:            "#10000000"
    property color    light:            "#40ffffff"
    property vector2d lightDir:         Qt.vector2d(0.5, -1.0)
    property real     rimSize:          0.012
    property real     rimStrength:      0.55
    property real     radius:           50
    property bool     highlightEnabled: true
    property bool     transparent:      false

    GlassRim {
        anchors.fill:  parent
        baseColor:     box.transparent ? "transparent" : box.color
        radius:        box.radius
        glowColor:     box.highlightEnabled
                           ? Qt.rgba(box.light.r, box.light.g, box.light.b, box.rimStrength * box.light.a)
                           : Qt.rgba(0, 0, 0, 0)
        lightDir:      box.lightDir
        glowEdgeBand:  box.rimSize
    }
}

