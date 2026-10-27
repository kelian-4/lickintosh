import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.glass
import qs.components

BoxGlass {
    id: root

    property var  notification: null
    property bool showClose: true
    property bool isStack: false
    property var  stackItems: []

    readonly property int animDur: 240

    property bool   expanded: false
    property bool   _remindMode: false
    property string _remindInput: "15"

    function closeExpanded() {
        root.expanded = false
        root._remindMode = false
    }

    readonly property string receivedTime: Qt.formatTime(new Date(), "HH:mm")

    function defaultAction() {
        return NotifService.findDefaultAction(root.notification)
    }

    function visibleActions() {
        if (!root.notification) return []
        var acts = root.notification.actions
        var out = []
        for (var i = 0; i < acts.length; i++) {
            if (acts[i].identifier !== "default") out.push(acts[i])
        }
        return out
    }

    height: root.expanded
        ? (_headerZone.height + _footerZone.height)
        : _headerZone.height

    Behavior on height {
        NumberAnimation { duration: root.animDur; easing.type: Easing.OutCubic }
    }

    Layout.preferredHeight: height
    implicitHeight: height

    radius: 16
    clip: true
    color:  Qt.rgba(0.0, 0.0, 0.0, 0.6)
    light:  Qt.rgba(1, 1, 1, 0.18)
    rimStrength: 1.2

    MouseArea {
        anchors.fill: parent
        cursorShape: root.defaultAction() ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: -1
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.expanded = !root.expanded
                if (!root.expanded) root._remindMode = false
                return
            }
            var act = root.defaultAction()
            if (act) act.invoke()
        }
    }

    Item {
        id: _headerZone
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   parent.top
        height: _headerRow.implicitHeight + 20

        RowLayout {
            id: _headerRow
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.top:         parent.top
            anchors.leftMargin:  14
            anchors.rightMargin: 14
            anchors.topMargin:   10
            spacing: 12

            Item {
                width:  36
                height: 36
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color:  Qt.rgba(1, 1, 1, 0.12)
                    visible: _notifIcon.resolvedSource === ""
                }

                NotifIcon {
                    id: _notifIcon
                    anchors.centerIn: parent
                    size: 32
                    visible: root.notification !== null
                    icon:    root.notification !== null ? root.notification.appIcon : ""
                    appName: root.notification !== null ? root.notification.appName : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        visible:         root.notification !== null && root.notification.summary !== ""
                        text:            root.notification ? root.notification.summary : ""
                        font.pixelSize:  14
                        font.weight:     Font.Bold
                        font.family:     "SF Pro Rounded"
                        color:           "#ffffff"
                        elide:           Text.ElideRight
                        renderType:      Text.NativeRendering
                    }

                    Text {
                        Layout.alignment: Qt.AlignTop
                        text:           root.receivedTime
                        font.pixelSize: 10
                        font.family:    "SF Pro Rounded"
                        color:          Qt.rgba(1, 1, 1, 0.45)
                        renderType:     Text.NativeRendering
                    }
                }

                TextEdit {
                    Layout.fillWidth: true
                    visible:          root.notification !== null && root.notification.body !== ""
                    text:             root.notification ? root.notification.body : ""
                    font.pixelSize:   12
                    font.family:      "SF Pro Rounded"
                    color:            Qt.rgba(1, 1, 1, 0.72)
                    wrapMode:         Text.Wrap
                    readOnly:         true
                    selectByMouse:    true
                    persistentSelection: true
                    renderType:       Text.NativeRendering
                    selectionColor:   Qt.rgba(1, 1, 1, 0.30)
                    textFormat:       TextEdit.PlainText
                    cursorVisible:    false
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6
                    visible: root.notification !== null && root.visibleActions().length > 0

                    Repeater {
                        model: root.notification ? root.visibleActions() : null
                        delegate: Rectangle {
                            Layout.preferredHeight: 26
                            Layout.preferredWidth:  _atxt.implicitWidth + 20
                            radius: 13
                            color:  Qt.rgba(1, 1, 1, 0.14)

                            Text {
                                id: _atxt
                                anchors.centerIn: parent
                                text:            modelData.text
                                font.pixelSize:  11
                                font.weight:     Font.DemiBold
                                font.family:     "SF Pro Rounded"
                                color:           "#ffffff"
                                renderType:      Text.NativeRendering
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    modelData.invoke()
                            }
                        }
                    }
                }
            }

            MouseArea {
                width:       18
                height:      18
                Layout.alignment: Qt.AlignTop
                visible:     root.showClose
                cursorShape: Qt.PointingHandCursor
                onClicked:   { if (root.notification) root.notification.dismiss() }

                Rectangle {
                    anchors.centerIn: parent
                    width:  15
                    height: 15
                    radius: 8
                    color:  Qt.rgba(1, 1, 1, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text:           "×"
                        font.pixelSize: 12
                        font.family:    "SF Pro Rounded"
                        color:          Qt.rgba(1, 1, 1, 0.70)
                        renderType:     Text.NativeRendering
                    }
                }
            }
        }
    }

    Item {
        id: _footerZone
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   _headerZone.bottom
        height: _footerContent.implicitHeight + 20
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: root.animDur / 2 }
        }

        ColumnLayout {
            id: _footerContent
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.top:         parent.top
            anchors.leftMargin:  14
            anchors.rightMargin: 14
            anchors.topMargin:   10
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !root._remindMode

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color:  _leftMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: root.isStack ? "Effacer" : "Rappeler plus tard"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "SF Pro Rounded"
                        color: "#ffffff"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: _leftMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isStack) {
                                NotifService.dismissGroup(root.stackItems)
                                root.closeExpanded()
                            } else {
                                root._remindMode = true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color:  _rightMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "Options"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "SF Pro Rounded"
                        color: "#ffffff"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: _rightMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotifService.openAppOptions(root.notification)
                            root.closeExpanded()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root._remindMode

                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.12)

                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: root._remindInput
                        font.pixelSize: 14
                        font.family: "SF Pro Rounded"
                        color: "#ffffff"
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        validator: IntValidator { bottom: 1; top: 1440 }
                        selectByMouse: true
                        onTextChanged: root._remindInput = text
                    }
                }

                Text {
                    text: "minutes"
                    font.pixelSize: 12
                    font.family: "SF Pro Rounded"
                    color: Qt.rgba(1, 1, 1, 0.55)
                    renderType: Text.NativeRendering
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 36
                    radius: 10
                    color: _confirmMa.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.18)

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
                            var minutes = parseInt(root._remindInput)
                            if (isNaN(minutes) || minutes < 1) minutes = 15
                            NotifService.remindLater(root.notification, minutes)
                            root.closeExpanded()
                        }
                    }
                }
            }
        }
    }
}
