import QtQuick
import qs.services

Item {
    id: root

    property var entries: []
    property var subEntries: []
    property real subY: 0
    readonly property int rowHeight: 26
    readonly property int separatorHeight: 9
    signal chosen(string action)

    anchors.fill: parent
    visible: false
    z: 1000

    function heightOf(list) {
        var h = 12
        for (var i = 0; i < list.length; i++) h += list[i].separator ? root.separatorHeight : root.rowHeight
        return h
    }

    function openAt(px, py, list) {
        root.subEntries = []
        root.entries = list
        panel.x = Math.max(8, Math.min(px, root.width - panel.width - 8))
        panel.y = Math.max(8, Math.min(py, root.height - root.heightOf(list) - 8))
        root.visible = true
    }

    function close() {
        root.visible = false
        root.subEntries = []
    }

    component MenuPanel: Rectangle {
        id: menuPanel

        property var items: []
        signal picked(string action)
        signal rowHovered(var item, real rowY)

        width: 210
        height: root.heightOf(menuPanel.items)
        radius: 12
        color: Qt.rgba(0.16, 0.16, 0.18, 0.97)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Column {
            x: 6
            y: 6
            width: parent.width - 12

            Repeater {
                model: menuPanel.items

                delegate: Item {
                    id: row
                    required property var modelData

                    readonly property bool isSeparator: row.modelData.separator === true
                    readonly property bool isDisabled: row.modelData.disabled === true
                    readonly property bool hasChildren: row.modelData.children !== undefined

                    width: parent.width
                    height: row.isSeparator ? root.separatorHeight : root.rowHeight

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.12)
                        visible: row.isSeparator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: ShellConfig.options.appearance.accentColor
                        visible: !row.isSeparator && !row.isDisabled && area.containsMouse
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.checked === true
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: row.modelData.checkable === true ? 26 : 10
                        anchors.right: parent.right
                        anchors.rightMargin: 26
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !row.isSeparator
                        text: row.modelData.label !== undefined ? row.modelData.label : ""
                        elide: Text.ElideRight
                        color: row.isDisabled ? Qt.rgba(1, 1, 1, 0.35) : (row.modelData.danger === true && !area.containsMouse ? "#ff6961" : "#ffffff")
                        font.pixelSize: 13
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.hasChildren
                        text: "›"
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.isSeparator
                        onEntered: menuPanel.rowHovered(row.modelData, row.y)
                        onClicked: {
                            if (row.isDisabled || row.hasChildren) return
                            menuPanel.picked(row.modelData.action)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.close()
    }

    MenuPanel {
        id: panel
        items: root.entries
        onPicked: function(action) {
            root.close()
            root.chosen(action)
        }
        onRowHovered: function(item, rowY) {
            root.subEntries = item.children !== undefined ? item.children : []
            root.subY = panel.y + 6 + rowY
        }
    }

    MenuPanel {
        id: subPanel
        visible: root.subEntries.length > 0
        items: root.subEntries
        x: panel.x + panel.width + subPanel.width + 8 > root.width ? panel.x - subPanel.width + 2 : panel.x + panel.width - 2
        y: Math.max(8, Math.min(root.subY, root.height - subPanel.height - 8))
        onPicked: function(action) {
            root.close()
            root.chosen(action)
        }
    }
}
