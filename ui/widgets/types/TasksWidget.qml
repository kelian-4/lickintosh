import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "s"

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
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: TasksState.pending.length
                color: "#ffffff"
                font.pixelSize: root.size === "s" ? 38 : 20
                font.weight: Font.Light
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.size === "s"
            text: TasksState.pending.length === 1 ? "task left" : "tasks left"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 12
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            Layout.fillWidth: true
            visible: root.size !== "s" && TasksState.pending.length === 0
            text: "Nothing to do"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 13
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.size !== "s"
            contentWidth: width
            contentHeight: tasksColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: tasksColumn
                width: parent.width
                spacing: 6

                Repeater {
                    model: TasksState.pending

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
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }

    }
}
