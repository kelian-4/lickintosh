import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.services
import qs.ui.widgets

Item {
    id: root

    property var look: null

    property string size: "s"

    readonly property bool present: UPower.displayDevice.isLaptopBattery
    readonly property real fraction: root.present ? UPower.displayDevice.percentage : 1
    readonly property bool charging: UPower.onBattery ? UPower.displayDevice.state === 1 : true
    readonly property color level: root.fraction <= 0.15 ? "#ff453a" : (root.fraction <= 0.3 ? "#ff9f0a" : "#30d158")
    readonly property string stateText: !root.present ? "Plugged in" : (root.charging ? "Charging" : "On battery")
    readonly property real timeSeconds: root.charging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty
    readonly property string timeText: root.present && root.timeSeconds > 0 ? root.duration(root.timeSeconds) : "—"
    readonly property real freeGb: Math.max(0, ResourcesState.memoryTotalGb - ResourcesState.memoryUsedGb)
    readonly property real diskFreeGb: Math.max(0, ResourcesState.storageTotalGb - ResourcesState.storageUsedGb)
    readonly property bool wantsTop: root.size === "l"
    property bool registered: false

    function duration(seconds) {
        var minutes = Math.round(seconds / 60)
        var hours = Math.floor(minutes / 60)
        return hours > 0 ? hours + "h " + (minutes % 60) + "m" : minutes + "m"
    }

    function memory(mb) {
        return mb >= 1024 ? (mb / 1024).toFixed(2) + " GB" : mb.toFixed(1) + " MB"
    }

    function sync() {
        if (root.wantsTop && !root.registered) {
            ResourcesState.topMemoryWatchers++
            root.registered = true
        } else if (!root.wantsTop && root.registered) {
            ResourcesState.topMemoryWatchers--
            root.registered = false
        }
    }

    onWantsTopChanged: root.sync()
    Component.onCompleted: root.sync()
    Component.onDestruction: {
        if (root.registered) ResourcesState.topMemoryWatchers--
    }

    component Block: ColumnLayout {
        id: block

        property var look: null
        property string name: ""
        property real percent: 0
        property color tint: "#30d158"
        property string detail: ""

        Layout.fillWidth: true
        spacing: 3

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: block.name
                elide: Text.ElideRight
                color: block.look.primary
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Text {
                text: Math.round(block.percent) + "%"
                color: block.tint
                font.pixelSize: 11
                font.weight: Font.Bold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 5
            radius: 2.5
            color: block.look.track

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, block.percent / 100))
                height: parent.height
                radius: 2.5
                color: block.tint
            }
        }

        Text {
            text: block.detail
            color: block.look.secondary
            font.pixelSize: 10
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }

    ResourceTitle {
        look: root.look
        id: title
        title: root.size === "s" ? "Battery" : (root.size === "m" ? "System Status" : "System Monitor")
        tint: root.level
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: root.size !== "s"
        text: title.updated
        color: root.look.secondary
        font.pixelSize: 11
        font.family: "SF Pro Text"
        renderType: Text.NativeRendering
    }

    ColumnLayout {
        visible: root.size === "s"
        anchors.top: title.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 4

        ResourceRing {
            look: root.look
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 78
            Layout.preferredHeight: 78
            percent: root.fraction * 100
            tint: root.level
            caption: "charge"
            thickness: 7
            valueSize: 18
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.stateText
                    color: root.level
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "State"
                    color: root.look.secondary
                    font.pixelSize: 10
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.timeText !== "—"
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.timeText
                    color: root.level
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.charging ? "To full" : "Left"
                    color: root.look.secondary
                    font.pixelSize: 10
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    GridLayout {
        visible: root.size === "m"
        anchors.top: title.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        columns: 2
        columnSpacing: 16
        rowSpacing: 8

        Block {
            look: root.look
            name: "Battery"
            percent: root.fraction * 100
            tint: root.level
            detail: root.stateText
        }

        Block {
            look: root.look
            name: "Memory"
            percent: ResourcesState.memoryPercent
            tint: "#30d158"
            detail: root.freeGb.toFixed(2) + " GB free"
        }

        Block {
            look: root.look
            name: "CPU"
            percent: ResourcesState.cpuPercent
            tint: "#64d2ff"
            detail: ResourcesState.cpuTempAvailable ? Math.round(ResourcesState.cpuTempC) + "°C" : "Load"
        }

        Block {
            look: root.look
            name: "Storage"
            percent: ResourcesState.storagePercent
            tint: "#ff9f0a"
            detail: root.diskFreeGb.toFixed(0) + " GB free"
        }
    }

    ColumnLayout {
        visible: root.size === "l"
        anchors.top: title.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ResourceRing {
                look: root.look
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                Layout.preferredWidth: 66
                percent: root.fraction * 100
                tint: root.level
                caption: "BAT"
                thickness: 6
                valueSize: 14
            }

            ResourceRing {
                look: root.look
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                Layout.preferredWidth: 66
                percent: ResourcesState.cpuPercent
                tint: "#64d2ff"
                caption: "CPU"
                thickness: 6
                valueSize: 14
            }

            ResourceRing {
                look: root.look
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                Layout.preferredWidth: 66
                percent: ResourcesState.memoryPercent
                tint: "#30d158"
                caption: "RAM"
                thickness: 6
                valueSize: 14
            }

            ResourceRing {
                look: root.look
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                Layout.preferredWidth: 66
                percent: ResourcesState.storagePercent
                tint: "#ff9f0a"
                caption: "DISK"
                thickness: 6
                valueSize: 14
            }
        }

        Text {
            text: "Top Memory Users"
            color: root.look.primary
            font.pixelSize: 12
            font.weight: Font.Bold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: ResourcesState.topMemory.slice(0, 5)

            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: 8
                color: root.look.surface

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: usage.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: root.look.primary
                    font.pixelSize: 11
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    id: usage
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.memory(row.modelData.mb)
                    color: root.look.secondary
                    font.pixelSize: 11
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: root.stateText + " · " + root.timeText
            color: root.look.secondary
            font.pixelSize: 11
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }
}
