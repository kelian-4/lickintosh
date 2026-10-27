import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components.glass
import qs.components
import qs.ui.topbar.statusarea.notifcenter

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
                        var items = []
                        for (var i = 0; i < _repeater.count; i++) {
                            var d = _repeater.itemAt(i)
                            if (d) items.push(d)
                        }
                        for (var j = 0; j < items.length; j++) {
                            items[j].autoHide()
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

                            property var  myNotif: notifObj
                            property bool isLeaving: false
                            property bool _shouldDismissNotif: false

                            function dismiss() {
                                if (wrap.isLeaving) return
                                wrap.isLeaving = true
                                wrap._shouldDismissNotif = true
                                _out.start()
                            }

                            function autoHide() {
                                if (wrap.isLeaving) return
                                wrap.isLeaving = true
                                wrap._shouldDismissNotif = false
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
                                onFinished: {
                                    NotifService.removePopup(wrap.myNotif)
                                    if (wrap._shouldDismissNotif && wrap.myNotif) {
                                        wrap.myNotif.dismiss()
                                    }
                                }
                            }

                            BoxGlass {
                                id: _glass
                                width:  root.popupWidth
                                height: _row.implicitHeight + 24
                                radius: 20
                                clip:   true
                                color:  Qt.rgba(0.0, 0.0, 0.0, 0.6)
                                light:  Qt.rgba(1, 1, 1, 0.18)
                                rimStrength: 1.2

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    z: -1
                                    onEntered: NotifService.stopGroupTimer()
                                    onExited:  NotifService.restartGroupTimer()
                                    onClicked: {
                                        var act = NotifService.findDefaultAction(wrap.myNotif)
                                        if (act) act.invoke()
                                        wrap.dismiss()
                                    }
                                }

                                RowLayout {
                                    id: _row
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
            }
        }
    }
}
