import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    readonly property color tint: "#30d158"
    readonly property real freeGb: Math.max(0, ResourcesState.memoryTotalGb - ResourcesState.memoryUsedGb)
    readonly property bool wantsTop: root.size === "l"
    property bool registered: false

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

    function mem(mb) {
        return mb >= 1024 ? (mb / 1024).toFixed(2) + " GB" : mb.toFixed(1) + " MB"
    }

    ResourceTitle {
        id: title
        title: root.size === "m" ? "RAM Status" : (root.size === "l" ? "RAM Monitor" : "RAM")
        tint: root.tint
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: root.size !== "s"
        text: title.updated
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: 11
        font.family: "SF Pro Rounded"
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
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 78
            Layout.preferredHeight: 78
            percent: ResourcesState.memoryPercent
            tint: root.tint
            caption: "used"
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
                    text: ResourcesState.memoryUsedGb.toFixed(2) + " GB"
                    color: root.tint
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Used"
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: 10
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.freeGb.toFixed(2) + " GB"
                    color: root.tint
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Free"
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: 10
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    RowLayout {
        visible: root.size === "m"
        anchors.top: title.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 16

        ResourceRing {
            Layout.preferredWidth: 92
            Layout.preferredHeight: 92
            Layout.alignment: Qt.AlignVCenter
            percent: ResourcesState.memoryPercent
            tint: root.tint
            caption: "Memory"
            thickness: 8
            valueSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            ResourceStat { label: "Total"; value: ResourcesState.memoryTotalGb.toFixed(0) + " GB" }
            ResourceStat { label: "Used"; value: ResourcesState.memoryUsedGb.toFixed(2) + " GB"; tint: root.tint }
            ResourceStat { label: "Free"; value: root.freeGb.toFixed(2) + " GB"; tint: root.tint }
        }
    }

    RowLayout {
        visible: root.size === "l"
        anchors.top: title.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 14

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 104
            spacing: 10

            ResourceRing {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                percent: ResourcesState.memoryPercent
                tint: root.tint
                caption: "used"
                thickness: 9
                valueSize: 22
            }

            ResourceStat { label: "Used"; value: ResourcesState.memoryUsedGb.toFixed(2) + " GB"; tint: root.tint; labelWidth: 34 }
            ResourceStat { label: "Free"; value: root.freeGb.toFixed(2) + " GB"; tint: root.tint; labelWidth: 34 }
            ResourceStat { label: "Total"; value: ResourcesState.memoryTotalGb.toFixed(0) + " GB"; labelWidth: 34 }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Text {
                text: "Top Memory Users"
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Repeater {
                model: ResourcesState.topMemory

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: usage.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    Text {
                        id: usage
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mem(row.modelData.mb)
                        color: Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize: 11
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
