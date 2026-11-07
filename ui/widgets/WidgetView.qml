import QtQuick
import qs.components.glass
import qs.services

Item {
    id: root

    required property var widgetData

    readonly property var dims: WidgetState.sizeOf(root.widgetData.size)
    readonly property var resolved: WidgetRegistry.resolve(root.widgetData)

    width: root.dims.w
    height: root.dims.h

    WidgetPalette {
        id: palette
        theme: root.widgetData.theme || "glass"
    }

    BoxGlass {
        anchors.fill: parent
        visible: palette.glass
        radius: 22
        color: "#59101014"
        light: "#60ffffff"
        rimStrength: 1.0
    }

    Rectangle {
        anchors.fill: parent
        visible: !palette.glass
        radius: 22
        color: palette.background
        border.width: 1
        border.color: palette.rim
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: loader.item && loader.item.fullBleed ? 0 : 14
        source: "types/" + WidgetRegistry.fileOf(root.resolved.type) + ".qml"
        onLoaded: {
            loader.item.size = Qt.binding(function() { return root.widgetData.size })
            if (loader.item.look !== undefined) loader.item.look = Qt.binding(function() { return palette })
            if (loader.item.variant !== undefined) loader.item.variant = Qt.binding(function() { return root.resolved.variant })
        }
    }
}
