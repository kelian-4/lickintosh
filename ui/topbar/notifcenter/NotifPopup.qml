import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.ui.glass
import qs.ui.primitives
import qs.ui.topbar.notifcenter

Scope {
    id: root

    property var notifServer: null

    readonly property int popupWidth:  340
    readonly property int topOffset:   52
    readonly property int rightMargin: 10
    readonly property int gap:         8
    readonly property int animDur:     280

    Loader {
        active: NotifService.popupModel.count > 0
        sourceComponent: Component {
            PanelWindow {
                screen: {
                    var m = Hyprland.focusedMonitor
                    if (m) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === m.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace:     "quickshell:notifpopup"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.layer:         WlrLayer.Overlay
                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true }

                implicitWidth:  root.popupWidth + root.rightMargin
                implicitHeight: Math.max(1, _col.implicitHeight + root.topOffset + root.gap)

                Connections {
                    target: NotifService
                    function onDismissGenChanged() {
                        for (var i = 0; i < _repeater.count; i++) {
                            var d = _repeater.itemAt(i)
                            if (d) d.dismiss()
                        }
                    }
                }

                Column {
                    id: _col
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   root.topOffset
                    anchors.rightMargin: root.rightMargin
                    spacing: root.gap

                    Repeater {
                        id: _repeater
                        model: NotifService.popupModel
                        delegate: Item {
                            id: wrap
                            width:  root.popupWidth
                            height: _glass.height

                            property var myNotif: notifObj
                            property bool isLeaving: false

                            function dismiss() {
                                if (wrap.isLeaving) return
                                wrap.isLeaving = true
                                _out.start()
                            }

                            Component.onCompleted: {
                                wrap.x = root.popupWidth + root.rightMargin + 20
                                _in.start()
                            }

                            NumberAnimation {
                                id: _in
                                target: wrap; property: "x"
                                to: 0
                                duration: root.animDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.65
                            }

                            NumberAnimation {
                                id: _out
                                target: wrap; property: "x"
                                to: root.popupWidth + root.rightMargin + 20
                                duration: root.animDur
                                easing.type: Easing.InCubic
                                onFinished: NotifService.removePopup(wrap.myNotif)
                            }

                            BoxGlass {
                                id: _glass
                                width:  root.popupWidth
                                height: _content.implicitHeight + 24
                                radius: 20
                                color:  Qt.rgba(0.0, 0.0, 0.0, 0.6)
                                light:  Qt.rgba(1, 1, 1, 0.18)
                                rimStrength: 1.2

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            var pt = _glass.mapToItem(null, mouse.x, mouse.y)
                                            _ctxMenu.notification = wrap.myNotif
                                            _ctxMenu.isStack      = false
                                            _ctxMenu.openAt(pt.x, pt.y)
                                            return
                                        }
                                        var act = NotifService.findDefaultAction(wrap.myNotif)
                                        if (act) act.invoke()
                                        NotifService.stopGroupTimer()
                                        wrap.dismiss()
                                    }
                                }

                                RowLayout {
                                    id: _content
                                    anchors.left:        parent.left
                                    anchors.right:       parent.right
                                    anchors.top:         parent.top
                                    anchors.leftMargin:  14
                                    anchors.rightMargin: 14
                                    anchors.topMargin:   12
                                    spacing: 12

                                    Item {
                                        width:  36
                                        height: 36
                                        Layout.alignment: Qt.AlignTop

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 10
                                            color:  Qt.rgba(1, 1, 1, 0.12)
                                            visible: _popupIcon.resolvedSource === ""
                                        }

                                        NotifIcon {
                                            id: _popupIcon
                                            anchors.centerIn: parent
                                            size: 32
                                            icon:    wrap.myNotif.appIcon
                                            appName: wrap.myNotif.appName
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            Layout.fillWidth: true
                                            visible:         wrap.myNotif.summary !== ""
                                            text:            wrap.myNotif.summary
                                            font.pixelSize:  14
                                            font.weight:     Font.Bold
                                            font.family:     "SF Pro Rounded"
                                            color:           "#ffffff"
                                            elide:           Text.ElideRight
                                            renderType:      Text.NativeRendering
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible:          wrap.myNotif.body !== ""
                                            text:             wrap.myNotif.body
                                            font.pixelSize:   12
                                            font.family:      "SF Pro Rounded"
                                            color:            Qt.rgba(1, 1, 1, 0.72)
                                            wrapMode:         Text.Wrap
                                            maximumLineCount: 2
                                            elide:            Text.ElideRight
                                            renderType:       Text.NativeRendering
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                NotifContextMenu {
                    id: _ctxMenu
                    anchors.fill: parent
                    onRemindRequested: function(minutes) {
                        NotifService.remindLater(_ctxMenu.notification, minutes)
                    }
                    onOptionsRequested: {
                        NotifService.openAppOptions(_ctxMenu.notification)
                    }
                }
            }
        }
    }
}
