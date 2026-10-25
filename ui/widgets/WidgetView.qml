import QtQuick
import qs.services

Item {
    id: root

    required property var widgetData

    readonly property var dims: WidgetState.sizeOf(root.widgetData.size)
    readonly property var resolved: WidgetRegistry.resolve(root.widgetData)

    width: root.dims.w
    height: root.dims.h

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Qt.rgba(0.09, 0.09, 0.11, 0.80)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: loader.item && loader.item.fullBleed ? 0 : 14
        source: "types/" + WidgetRegistry.fileOf(root.resolved.type) + ".qml"
        onLoaded: {
            loader.item.size = Qt.binding(function() { return root.widgetData.size })
            if (loader.item.variant !== undefined) loader.item.variant = Qt.binding(function() { return root.resolved.variant })
        }
    }
}
