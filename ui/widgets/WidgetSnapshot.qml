import QtQuick
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

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: palette.glass ? "#59101014" : palette.background
        border.width: 1
        border.color: palette.glass ? "#30ffffff" : palette.rim
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: loader.item && loader.item.fullBleed ? 0 : 14
        source: "types/" + WidgetRegistry.fileOf(root.resolved.type) + ".qml"
        onLoaded: {
            loader.item.size = Qt.binding(function() { return root.widgetData.size })
            if (loader.item.widgetData !== undefined) loader.item.widgetData = Qt.binding(function() { return root.widgetData })
            if (loader.item.look !== undefined) loader.item.look = Qt.binding(function() { return palette })
            if (loader.item.variant !== undefined) loader.item.variant = Qt.binding(function() { return root.resolved.variant })
        }
    }
}
