import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    property bool  visible_: false
    property real  menuX: 0
    property real  menuY: 0
    property var   notification: null
    property var   stackItems: []
    property bool  isStack: false

    signal clearRequested()
    signal remindRequested(int minutes)
    signal optionsRequested()

    property bool _remindMode: false
    property real _remindMinutes: 15

    visible: root.visible_
    z: 9999

    function openAt(x, y) {
        root._remindMode = false
        root.menuX = x
        root.menuY = y
        root.visible_ = true
    }

    function close() {
        root.visible_ = false
        root._remindMode = false
    }

    MouseArea {
        anchors.fill: parent
        visible: root.visible_
        onClicked: root.close()
        onPressed: function(e) { e.accepted = true }
    }

    BoxGlass {
        id: _menuBox
        x: Math.max(4, Math.min(root.menuX, root.parent ? root.parent.width - width - 4 : root.menuX))
        y: root.menuY
        width: 220
        height: _menuContent.implicitHeight + 16
        radius: 14
        color:  Qt.rgba(0.08, 0.10, 0.18, 0.92)
        light:  Qt.rgba(1, 1, 1, 0.18)
        rimStrength: 1.2
        visible: root.visible_

        MouseArea {
            anchors.fill: parent
            onClicked: function(e) { e.accepted = true }
        }

        ColumnLayout {
            id: _menuContent
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   parent.top
            anchors.margins: 8
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color:  _clearMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                visible: root.isStack

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Effacer"
                    font.pixelSize: 13
                    font.family: "SF Pro Rounded"
                    color: "#ffffff"
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: _clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.clearRequested()
                        root.close()
                    }
                }
            }

            Item {
                visible: !root._remindMode && !root.isStack
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height

                ColumnLayout {
                    width: parent.width
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 8
                        color:  _remindMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Rappeler plus tard"
                            font.pixelSize: 13
                            font.family: "SF Pro Rounded"
                            color: "#ffffff"
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: _remindMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._remindMode = true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 8
                        color:  _optMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Options"
                            font.pixelSize: 13
                            font.family: "SF Pro Rounded"
                            color: "#ffffff"
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: _optMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.optionsRequested()
                                root.close()
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 6
                spacing: 8
                visible: root._remindMode

                Text {
                    Layout.fillWidth: true
                    text: "Rappeler dans " + Math.round(root._remindMinutes) + " min"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: "SF Pro Rounded"
                    color: "#ffffff"
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    id: _sliderTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.18)

                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: "#ffffff"
                        width: parent.width * ((root._remindMinutes - 1) / 119)
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onPressed: function(mouse) {
                            var ratio = Math.max(0, Math.min(1, mouse.x / _sliderTrack.width))
                            root._remindMinutes = 1 + ratio * 119
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            var ratio = Math.max(0, Math.min(1, mouse.x / _sliderTrack.width))
                            root._remindMinutes = 1 + ratio * 119
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 8
                    color:  _confirmMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: "Confirmer"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.family: "SF Pro Rounded"
                        color: "#ffffff"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: _confirmMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.remindRequested(Math.round(root._remindMinutes))
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
