import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui.glass
import qs.ui.primitives

BoxGlass {
    id: root

    property var notification: null
    property bool showClose: true
    property bool isStack: false

    signal contextMenuRequested(real x, real y)

    property string receivedTime: Qt.formatTime(new Date(), "HH:mm")

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

    Layout.preferredHeight: _row.implicitHeight + 20
    implicitHeight: _row.implicitHeight + 20
    radius: 16
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
                var pt = root.mapToItem(null, mouse.x, mouse.y)
                root.contextMenuRequested(pt.x, pt.y)
                return
            }
            var act = root.defaultAction()
            if (act) act.invoke()
        }
    }

    RowLayout {
        id: _row
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.top:         parent.top
        anchors.leftMargin:  14
        anchors.rightMargin: 14
        anchors.topMargin:   10
        spacing: 12

        Item {
            id: _iconSlot
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

            Text {
                Layout.fillWidth: true
                text: "RAW=[" + (root.notification ? root.notification.appIcon : "") + "] APP=[" + (root.notification ? root.notification.appName : "") + "] RES=[" + _notifIcon.resolvedSource + "]"
                color: "#ff0000"
                font.pixelSize: 8
                wrapMode: Text.Wrap
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
