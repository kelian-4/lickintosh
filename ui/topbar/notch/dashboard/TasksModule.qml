import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    Layout.preferredWidth: 168
    Layout.fillHeight: true

    readonly property var visibleTasks: TasksState.pending.slice(0, 3)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: "Tâches"
            color: "#8A8A8A"
            font.pixelSize: 12
            font.bold: true
            font.family: "SF Pro Rounded"
        }

        Text {
            Layout.fillWidth: true
            visible: root.visibleTasks.length === 0
            text: "Rien à faire"
            color: "#C0C0C0"
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
        }

        Repeater {
            model: root.visibleTasks

            delegate: Item {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 20

                Rectangle {
                    id: box
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: "transparent"
                    border.color: "#8A8A8A"
                    border.width: 1.5
                }

                Text {
                    anchors.left: box.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.text
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.family: "SF Pro Rounded"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TasksState.toggleTask(row.modelData.id)
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
