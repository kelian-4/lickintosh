import Quickshell
import QtQuick

Text {
    id: uitext
    property bool gray: false
    renderType: Text.NativeRendering
    renderTypeQuality: Text.VeryHighRenderTypeQuality
    font.family: "SF Pro Display"
    color: gray ? "#a0ffffff" : "#ffffff"
    Behavior on color { ColorAnimation { duration: 300 } }
}
