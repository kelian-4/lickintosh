import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    readonly property color tint: "#0a84ff"

    function rate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576) return (bytesPerSecond / 1048576).toFixed(1) + " MB/s"
        return Math.round(bytesPerSecond / 1024) + " KB/s"
    }

    ResourceTitle {
        id: title
        title: root.size === "s" ? "Network" : "Network Status"
        tint: root.tint
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: root.size === "m"
        text: title.updated
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: 11
        font.family: "SF Pro Rounded"
        renderType: Text.NativeRendering
    }

    ColumnLayout {
        anchors.top: title.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        Text {
            text: "↓ " + root.rate(ResourcesState.netDownBps)
            color: root.tint
            font.pixelSize: root.size === "s" ? 17 : 22
            font.weight: Font.Bold
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Text {
            text: "↑ " + root.rate(ResourcesState.netUpBps)
            color: "#30d158"
            font.pixelSize: root.size === "s" ? 17 : 22
            font.weight: Font.Bold
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        ResourceStat {
            visible: root.size === "m"
            label: "Session"
            value: "↓ " + ResourcesState.netTotalDownGb.toFixed(2) + " GB   ↑ " + ResourcesState.netTotalUpGb.toFixed(2) + " GB"
        }
    }
}
