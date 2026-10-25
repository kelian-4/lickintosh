import QtQuick
import qs.components.glass
import qs.services

Item {
    id: root

    required property var widgetData

    readonly property var dims: WidgetState.sizeOf(root.widgetData.size)

    width: root.dims.w
    height: root.dims.h

    BoxGlass {
        anchors.fill: parent
        radius: 22
        color: "#59101014"
        light: "#60ffffff"
        rimStrength: 1.0
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: loader.item && loader.item.fullBleed ? 0 : 14
        source: "types/" + WidgetRegistry.fileOf(root.widgetData.type) + ".qml"
        onLoaded: loader.item.size = Qt.binding(function() { return root.widgetData.size })
    }
}
