import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "s"

    function rate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576) return (bytesPerSecond / 1048576).toFixed(1) + " MB/s"
        return Math.round(bytesPerSecond / 1024) + " KB/s"
    }

    component Meter: ColumnLayout {
        id: meter

        property string title: ""
        property string detail: ""
        property real percent: 0
        property color tint: "#64d2ff"

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: meter.title
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: meter.detail
                color: Qt.rgba(1, 1, 1, 0.6)
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.12)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.percent / 100))
                height: parent.height
                radius: 3
                color: meter.tint
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item { Layout.fillHeight: true }

        Meter {
            title: "CPU"
            detail: Math.round(ResourcesState.cpuPercent) + "%"
            percent: ResourcesState.cpuPercent
            tint: "#64d2ff"
        }

        Meter {
            title: "Memory"
            detail: ResourcesState.memoryUsedGb.toFixed(1) + " / " + ResourcesState.memoryTotalGb.toFixed(1) + " GB"
            percent: ResourcesState.memoryPercent
            tint: "#30d158"
        }

        Meter {
            visible: root.size !== "s"
            title: "Disk"
            detail: ResourcesState.storageUsedGb.toFixed(0) + " / " + ResourcesState.storageTotalGb.toFixed(0) + " GB"
            percent: ResourcesState.storagePercent
            tint: "#ff9f0a"
        }

        RowLayout {
            visible: root.size === "l"
            Layout.fillWidth: true

            Text {
                text: "↓ " + root.rate(ResourcesState.netDownBps)
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "↑ " + root.rate(ResourcesState.netUpBps)
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }

        Text {
            visible: root.size === "l" && ResourcesState.cpuTempAvailable
            text: "CPU " + Math.round(ResourcesState.cpuTempC) + "°C"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 12
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }
    }
}
