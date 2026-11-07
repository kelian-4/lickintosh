import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.VectorImage
import QtQuick.Effects
import qs.services

VectorImage {
    id: vi
    property bool gray: false
    property color color: Theme.ink(vi, gray)
    property int size: 16
    property bool colorized: true
    property string icon: ""
    source: icon === "" ? "" : icon.startsWith("/") ? "file://" + icon : Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + icon)
    width: size
    height: size
    preferredRendererType: VectorImage.CurveRenderer
    layer.enabled: colorized
    layer.samples: 16
    layer.smooth: true
    layer.textureSize: Qt.size(Math.ceil(vi.width * 3), Math.ceil(vi.height * 3))
    layer.effect: MultiEffect {
        colorization: vi.colorized ? 1 : 0
        colorizationColor: vi.color
    }
}
