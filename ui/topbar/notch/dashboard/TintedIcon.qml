import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects

Item {
    id: root

    property url source
    property color tint: "#FFFFFF"
    property real size: 18

    implicitWidth: root.size
    implicitHeight: root.size

    VectorImage {
        anchors.fill: parent
        source: root.source
        preferredRendererType: VectorImage.CurveRenderer
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.tint
        }
    }
}
