import QtQuick
import qs.services

Item {
    id: root

    property var entries: []
    readonly property int rowHeight: 26
    signal chosen(string action)

    anchors.fill: parent
    visible: false
    z: 1000

    function openAt(px, py, list) {
        root.entries = list
        panel.x = Math.max(8, Math.min(px, root.width - panel.width - 8))
        panel.y = Math.max(8, Math.min(py, root.height - panel.height - 8))
        root.visible = true
    }

    function close() {
        root.visible = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.close()
    }

    Rectangle {
        id: panel
        width: 190
        height: root.entries.length * root.rowHeight + 12
        radius: 12
        color: Qt.rgba(0.16, 0.16, 0.18, 0.96)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Column {
            anchors.fill: parent
            anchors.margins: 6

            Repeater {
                model: root.entries

                delegate: Rectangle {
                    id: row
                    required property var modelData

                    width: parent.width
                    height: root.rowHeight
                    radius: 6
                    color: area.containsMouse ? ShellConfig.options.appearance.accentColor : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.close()
                            root.chosen(row.modelData.action)
                        }
                    }
                }
            }
        }
    }
}
