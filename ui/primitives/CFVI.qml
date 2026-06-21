import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage
import QtQuick.Effects

VectorImage {
    id: vi
    property bool gray: false
    property color color: gray ? "#a0ffffff" : "#fff"
    property int size: 16
    property bool colorized: true
    property string icon: ""
    source: icon.startsWith("/") ? "file://" + icon : Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + icon)
    width: size
    height: size
    preferredRendererType: VectorImage.CurveRenderer
    layer.enabled: colorized
    layer.samples: 16
    layer.effect: MultiEffect {
        colorization: vi.colorized ? 1 : 0
        colorizationColor: vi.color
    }
}
