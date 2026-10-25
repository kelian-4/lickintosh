import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    readonly property color tint: "#64d2ff"

    ResourceTitle {
        id: title
        title: root.size === "s" ? "CPU" : "CPU Status"
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

    ResourceRing {
        visible: root.size === "s"
        anchors.top: title.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: 92
        height: 92
        percent: ResourcesState.cpuPercent
        tint: root.tint
        caption: "load"
        thickness: 8
        valueSize: 20
    }

    ColumnLayout {
        visible: root.size !== "s"
        anchors.top: title.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ResourceRing {
                Layout.preferredWidth: root.size === "l" ? 104 : 92
                Layout.preferredHeight: root.size === "l" ? 104 : 92
                percent: ResourcesState.cpuPercent
                tint: root.tint
                caption: "load"
                thickness: 8
                valueSize: 20
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    visible: ResourcesState.cpuName !== ""
                    text: ResourcesState.cpuName
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }

                ResourceStat {
                    visible: ResourcesState.cpuTempAvailable
                    label: "Temp"
                    value: Math.round(ResourcesState.cpuTempC) + "°C"
                    tint: root.tint
                }
            }
        }

        Row {
            visible: root.size === "l"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            Repeater {
                model: ResourcesState.cpuHistory

                delegate: Item {
                    id: bar
                    required property real modelData
                    width: Math.max(2, (parent.width - 39 * 3) / 40)
                    height: parent.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(2, parent.height * bar.modelData / 100)
                        radius: width / 2
                        color: root.tint
                        opacity: 0.85
                    }
                }
            }
        }
    }
}
