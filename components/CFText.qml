import Quickshell
import QtQuick
import qs.services

Text {
    id: uitext
    property bool gray: false
    renderType: Text.NativeRendering
    renderTypeQuality: Text.VeryHighRenderTypeQuality
    font.family: "SF Pro Display"
    color: Theme.ink(uitext, gray)
    Behavior on color { ColorAnimation { duration: 300 } }
}
