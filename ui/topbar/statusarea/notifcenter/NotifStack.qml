import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.glass
import qs.components

ColumnLayout {
    id: root

    property string appName: ""
    property var    items:    []

    readonly property int animDur:       260
    readonly property int cascadeOffset:  10
    property int maxVisible: 3

    property bool expanded: false

    spacing: 6

    opacity: 0
    scale:   0.92
    Component.onCompleted: _arrivalAnim.start()

    ParallelAnimation {
        id: _arrivalAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.animDur + 60; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale";   to: 1; duration: root.animDur + 60; easing.type: Easing.OutBack; easing.overshoot: 0.4 }
    }

    Item {
        id: _collapsedView
        Layout.fillWidth: true
        Layout.preferredHeight: _topCard.implicitHeight + Math.min(root.items.length - 1, 2) * root.cascadeOffset
        visible: !root.expanded

        Repeater {
            model: Math.max(0, Math.min(root.items.length, 3) - 1)
            delegate: BoxGlass {
                z: -(index + 1)
                width:  _collapsedView.width - ((index + 1) * 14)
                height: _topCard.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: (index + 1) * root.cascadeOffset
                radius: 16
                color:  Qt.rgba(0.0, 0.0, 0.0, Math.max(0.30, 0.55 - (index + 1) * 0.08))
                light:  Qt.rgba(1, 1, 1, 0.14)
                rimStrength: 1.0
            }
        }

        NotifItem {
            id: _topCard
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   parent.top
            notification: root.items.length > 0 ? root.items[0] : null
            showClose: root.items.length === 1
            isStack: root.items.length > 1
            stackItems: root.items
        }

        Rectangle {
            visible: root.items.length > 1
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: root.items.length === 1 ? 36 : 10
            width:  Math.max(20, _cnt.implicitWidth + 12)
            height: 18
            radius: 9
            color:  Qt.rgba(1, 1, 1, 0.18)

            Text {
                id: _cnt
                anchors.centerIn: parent
                text:           root.items.length.toString()
                font.pixelSize: 10
                font.weight:    Font.Bold
                font.family:    "SF Pro Rounded"
                color:          "#ffffff"
                renderType:     Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.items.length > 1
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    ColumnLayout {
        id: _expandedView
        Layout.fillWidth: true
        spacing: 4
        visible: root.expanded

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2

            Text {
                Layout.fillWidth: true
                text: root.appName
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                color: "#ffffff"
                renderType: Text.NativeRendering
            }

            Rectangle {
                width:  _lessLabel.implicitWidth + 16
                height: 22
                radius: 11
                color:  _lessMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12)

                Text {
                    id: _lessLabel
                    anchors.centerIn: parent
                    text: "Show less"
                    font.pixelSize: 11
                    font.family: "SF Pro Rounded"
                    color: "#ffffff"
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: _lessMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.expanded = false; root.maxVisible = 3 }
                }
            }

            Rectangle {
                width:  18
                height: 18
                radius: 9
                color:  _closeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 13
                    font.family: "SF Pro Rounded"
                    color: "#ffffff"
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: _closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotifService.dismissGroup(root.items)
                }
            }
        }

        Repeater {
            model: root.expanded ? Math.min(root.items.length, root.maxVisible) : 0
            delegate: NotifItem {
                id: _delegateItem
                Layout.fillWidth: true
                notification: root.items[index]

                opacity: 0
                Component.onCompleted: _appearAnim.start()

                NumberAnimation {
                    id: _appearAnim
                    target: _delegateItem
                    property: "opacity"
                    to: 1
                    duration: root.animDur
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 10
            color: _moreMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
            visible: root.items.length > root.maxVisible

            Text {
                anchors.centerIn: parent
                text: (root.items.length - root.maxVisible) + " more notification" + (root.items.length - root.maxVisible > 1 ? "s" : "")
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
                color: Qt.rgba(1, 1, 1, 0.60)
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: _moreMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.maxVisible = root.items.length
            }
        }
    }
}
