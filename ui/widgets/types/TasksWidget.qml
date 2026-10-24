import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "s"
    readonly property int visibleCount: root.size === "l" ? 8 : (root.size === "m" ? 3 : 0)
    readonly property var shown: TasksState.pending.slice(0, root.visibleCount)

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Tasks"
                color: "#ff9f0a"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: TasksState.pending.length
                color: "#ffffff"
                font.pixelSize: root.size === "s" ? 38 : 20
                font.weight: Font.Light
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.size === "s"
            text: TasksState.pending.length === 1 ? "task left" : "tasks left"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 12
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            visible: root.size !== "s" && TasksState.pending.length === 0
            text: "Nothing to do"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.shown

            delegate: RowLayout {
                id: taskRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "transparent"
                    border.width: 1.5
                    border.color: "#ff9f0a"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TasksState.toggleTask(taskRow.modelData.id)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: taskRow.modelData.text
                    elide: Text.ElideRight
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
