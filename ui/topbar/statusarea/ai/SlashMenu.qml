import QtQuick
import QtQuick.Layouts
import qs.ui.glass

Item {
    id: root

    property var items: []
    property int selectedIndex: 0
    property bool active: false
    property string emptyMessage: "Aucune correspondance — choisis une valeur de la liste"
    property real maxHeight: 280
    signal itemChosen(var item)

    visible: active
    implicitWidth: 300
    implicitHeight: Math.min(list.contentHeight, root.maxHeight)

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        visible: root.items.length > 0
        model: root.items
        spacing: 6
        currentIndex: root.selectedIndex
        highlightMoveDuration: 80
        boundsBehavior: Flickable.StopAtBounds

        onCurrentIndexChanged: list.positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: BoxGlass {
            id: delegateRoot
            required property int index
            required property var modelData
            width: list.width
            height: 40
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.06)
            light: Qt.rgba(1, 1, 1, 0.20)
            lightDir: Qt.vector2d(0.0, -1.0)
            rimStrength: 0.6

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "transparent"
                border.width: 2
                border.color: delegateRoot.index === root.selectedIndex ? "#7DD3FC" : "transparent"
                Behavior on border.color { ColorAnimation { duration: 80 } }
            }

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: delegateRoot.index === root.selectedIndex ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: delegateRoot.modelData.label
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "monospace"
                    renderType: Text.NativeRendering
                }
                Text {
                    text: delegateRoot.modelData.sub || ""
                    visible: (delegateRoot.modelData.sub || "") !== ""
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.family: "monospace"
                    renderType: Text.NativeRendering
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: delegateRoot.modelData.desc || ""
                    visible: (delegateRoot.modelData.desc || "") !== ""
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 150
                    renderType: Text.NativeRendering
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: delegateRoot.modelData.nonInsertable ? Qt.ArrowCursor : Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                property real _lastGX: -1
                property real _lastGY: -1
                onClicked: if (!delegateRoot.modelData.nonInsertable) root.itemChosen(delegateRoot.modelData)
                onPositionChanged: function(mouse) {
                    if (delegateRoot.modelData.nonInsertable) return
                    var g = mapToGlobal(mouse.x, mouse.y)
                    if (_lastGX === g.x && _lastGY === g.y) return
                    _lastGX = g.x; _lastGY = g.y
                    if (root.selectedIndex !== delegateRoot.index) root.selectedIndex = delegateRoot.index
                }
            }
        }
    }

    BoxGlass {
        visible: root.active && root.items.length === 0
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.06)
        light: Qt.rgba(1, 1, 1, 0.20)
        lightDir: Qt.vector2d(0.0, -1.0)
        rimStrength: 0.6

        Text {
            anchors.centerIn: parent
            width: parent.width - 24
            text: root.emptyMessage
            color: "#FFFFFF"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }
    }
}
