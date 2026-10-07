import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    signal closeRequested()

    readonly property int maxRows: 4
    readonly property var pending: TasksState.pending
    readonly property var finished: TasksState.done

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: "#262626"
    }

    component TaskRow: Item {
        id: row
        property var task
        property bool finished: false

        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {
            id: box
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: row.finished ? "#1C7AFF" : "transparent"
            border.color: row.finished ? "#1C7AFF" : "#8A8A8A"
            border.width: 1.5
        }

        Text {
            anchors.left: box.right
            anchors.leftMargin: 8
            anchors.right: removeButton.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: row.task.text
            color: row.finished ? "#6A6A6A" : "#FFFFFF"
            font.pixelSize: 13
            font.strikeout: row.finished
            font.family: "SF Pro Rounded"
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: removeButton.left
            cursorShape: Qt.PointingHandCursor
            onClicked: TasksState.toggleTask(row.task.id)
        }

        CtrlButton {
            id: removeButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: "notch/trash-2.svg"
            size: 13
            onClicked: TasksState.removeTask(row.task.id)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 170
            Layout.maximumWidth: 170
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 2

            Item { Layout.fillHeight: true }

            Text {
                text: "Tâches"
                color: "#FFFFFF"
                font.pixelSize: 28
                font.bold: true
                font.family: "SF Pro Rounded"
            }
            Text {
                text: root.pending.length === 0 ? "Tout est fait" : root.pending.length + " à faire"
                color: "#8A8A8A"
                font.pixelSize: 15
                font.family: "SF Pro Rounded"
            }
            Text {
                Layout.topMargin: 8
                Layout.fillWidth: true
                text: "Ajout : >+ dans Spotlight"
                color: "#6A6A6A"
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }
        }

        Divider {}

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 2

            Text {
                text: "À faire"
                color: "#8A8A8A"
                font.pixelSize: 12
                font.bold: true
                font.family: "SF Pro Rounded"
            }

            Text {
                visible: root.pending.length === 0
                text: "Rien à faire"
                color: "#C0C0C0"
                font.pixelSize: 13
                font.family: "SF Pro Rounded"
            }

            Repeater {
                model: root.pending.slice(0, root.maxRows)
                delegate: TaskRow {
                    required property var modelData
                    task: modelData
                }
            }

            Text {
                visible: root.pending.length > root.maxRows
                text: "+" + (root.pending.length - root.maxRows) + " autres"
                color: "#6A6A6A"
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
            }

            Item { Layout.fillHeight: true }
        }

        Divider {}

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Terminées"
                    color: "#8A8A8A"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "SF Pro Rounded"
                }
                Item { Layout.fillWidth: true }
                CtrlButton {
                    icon: "notch/minimize-2.svg"
                    size: 14
                    onClicked: root.closeRequested()
                }
            }

            Text {
                visible: root.finished.length === 0
                text: "Aucune tâche terminée"
                color: "#6A6A6A"
                font.pixelSize: 13
                font.family: "SF Pro Rounded"
            }

            Repeater {
                model: root.finished.slice(0, root.maxRows)
                delegate: TaskRow {
                    required property var modelData
                    task: modelData
                    finished: true
                }
            }

            Text {
                visible: root.finished.length > root.maxRows
                text: "+" + (root.finished.length - root.maxRows) + " autres"
                color: "#6A6A6A"
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
            }

            Item { Layout.fillHeight: true }
        }
    }
}
