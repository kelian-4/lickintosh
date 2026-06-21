import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui.glass
import qs.ui.primitives

ColumnLayout {
    id: root

    property string appName: ""
    property var    items:    []

    readonly property int cascadeOffset: 10
    readonly property int animDur:       260

    property bool expanded: false

    signal contextMenuRequested(real x, real y, var notification, bool isStack)

    spacing: 6

    opacity: 0
    scale:   0.92
    Component.onCompleted: _arrivalAnim.start()

    ParallelAnimation {
        id: _arrivalAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: root.animDur + 60; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale";   to: 1; duration: root.animDur + 60; easing.type: Easing.OutBack; easing.overshoot: 0.4 }
    }

    Layout.preferredHeight: root.expanded ? _expandedView.implicitHeight : _collapsedView.implicitHeight

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic }
    }

    Item {
        id: _collapsedView
        Layout.fillWidth: true
        implicitHeight: _topCard.implicitHeight + Math.min(root.items.length - 1, 2) * root.cascadeOffset
        visible: opacity > 0
        opacity: root.expanded ? 0 : 1
        scale:   root.expanded ? 0.94 : 1.0

        Behavior on opacity { NumberAnimation { duration: root.animDur } }
        Behavior on scale   { NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic } }

        Repeater {
            model: Math.max(0, Math.min(root.items.length, 3) - 1)
            delegate: BoxGlass {
                z: -(index + 1)
                width:  _collapsedView.width - ((index + 1) * 14)
                height: _topCard.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: (index + 1) * root.cascadeOffset

                Behavior on width        { NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic } }
                Behavior on anchors.topMargin { NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic } }

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

            onContextMenuRequested: function(x, y) {
                root.contextMenuRequested(x, y, _topCard.notification, root.items.length > 1)
            }
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
        spacing: 6
        visible: opacity > 0
        opacity: root.expanded ? 1 : 0
        scale:   root.expanded ? 1.0 : 0.94

        Behavior on opacity { NumberAnimation { duration: root.animDur } }
        Behavior on scale   { NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic } }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            visible: root.items.length > 1

            Text {
                Layout.fillWidth: true
                text: root.appName
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                color: Qt.rgba(1, 1, 1, 0.65)
                renderType: Text.NativeRendering
            }

            Rectangle {
                width:  _lessTxt.implicitWidth + 20
                height: 24
                radius: 12
                color:  Qt.rgba(1, 1, 1, 0.14)

                Text {
                    id: _lessTxt
                    anchors.centerIn: parent
                    text: "Voir moins"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: "SF Pro Rounded"
                    color: "#ffffff"
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }
            }
        }

        Repeater {
            model: root.expanded ? root.items : []
            delegate: NotifItem {
                id: _delegateItem
                Layout.fillWidth: true
                notification: modelData

                opacity: 0
                Component.onCompleted: _appearAnim.start()

                onContextMenuRequested: function(x, y) {
                    root.contextMenuRequested(x, y, _delegateItem.notification, false)
                }

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
    }
}
