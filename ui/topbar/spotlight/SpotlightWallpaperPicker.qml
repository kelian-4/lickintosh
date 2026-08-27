import QtQuick
import Quickshell

ListView {
    id: root

    required property list<var> answers
    required property int currentIdx

    signal itemClicked(var data)

    function activateIndex(idx) {
        var item = itemAtIndex(idx)
        if (item) root.itemClicked(item.modelData)
    }

    readonly property int itemSlotWidth: 210
    readonly property int shownCount: Math.max(1, Math.min(3, root.answers.length))

    orientation: ListView.Horizontal
    interactive: false
    clip: true

    width:  root.shownCount * root.itemSlotWidth
    height: 130

    currentIndex: root.currentIdx
    highlightRangeMode:   ListView.StrictlyEnforceRange
    preferredHighlightBegin: (root.width - root.itemSlotWidth) / 2
    preferredHighlightEnd:   (root.width + root.itemSlotWidth) / 2
    snapMode: ListView.SnapOneItem

    Behavior on contentX { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    model: ScriptModel {
        values: root.answers
    }

    delegate: Item {
        id: tile
        required property var modelData
        required property int index

        width:  root.itemSlotWidth
        height: root.height

        readonly property bool isCurrent: tile.index === root.currentIdx
        readonly property bool isNear:    Math.abs(tile.index - root.currentIdx) <= 1

        scale:   tile.isCurrent ? 1.0 : 0.8
        opacity: tile.isNear ? 1 : 0

        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            id: thumb
            anchors.centerIn: parent
            width: 170; height: 96
            radius: 14
            color: "#20ffffff"
            clip: true
            border.width: tile.isCurrent ? 3 : 0
            border.color: "#ffffff"
            Behavior on border.width { NumberAnimation { duration: 150 } }

            Image {
                anchors.fill: parent
                source: "file://" + tile.modelData.path
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                cache: true
                smooth: !root.moving
            }
        }

        Text {
            anchors.top: thumb.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: thumb.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.modelData.title || ""
            color: "#ffffff"
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.itemClicked(tile.modelData)
        }
    }
}
