import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.components.glass
import qs.components
import qs.services
import qs.ui.topbar.statusarea.notifcenter
import qs.ui.widgets

Scope {
    id: root

    property bool opened: false
    property var  notifServer: null
    signal closing()

    onOpenedChanged: NotifService.centerOpened = root.opened

    readonly property int panelWidth:   320
    readonly property int panelMarginR: 10
    readonly property int topOffset:    48

    Presence {
        id: presence
        wanted: root.opened
        exitDuration: ShellMotion.enter()
    }

    Loader {
        active: presence.present
        sourceComponent: Component {
            PanelWindow {
                id: ncWin

                screen: {
                    var m = Hyprland.focusedMonitor
                    if (m) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === m.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace:     "quickshell:notifcenter"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer:         WlrLayer.Overlay
                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true; bottom: true; left: true }

                mask: WidgetState.galleryZone === "notifCenter" ? galleryMask : null

                Region {
                    id: galleryMask
                    item: panel
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closing()
                }

                Item {
                    id: panel
                    width:  root.panelWidth
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.bottom:      parent.bottom
                    anchors.topMargin:   root.topOffset
                    anchors.rightMargin: root.panelMarginR

                    property bool vis: false
                    Component.onCompleted: panel.vis = root.opened
                    Connections {
                        target: root
                        function onOpenedChanged() { panel.vis = root.opened }
                    }

                    transform: Translate {
                        x: panel.vis ? 0 : root.panelWidth + root.panelMarginR
                        Behavior on x {
                            NumberAnimation {
                                duration: ShellMotion.enter()
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: ShellMotion.spatialCurve
                            }
                        }
                    }
                    opacity: panel.vis ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: ShellMotion.enter(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: false
                        onClicked: function(e) { e.accepted = true }
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["text/plain"]

                        function parse(drag) {
                            if (!drag.hasText || drag.text.indexOf("widget:") !== 0) return null
                            var parts = drag.text.split(":")
                            return { type: parts[1], size: parts[2], variant: parts[3] || "" }
                        }

                        onEntered: function(drag) {
                            drag.accepted = WidgetState.galleryZone === "notifCenter" && parse(drag) !== null
                        }
                        onDropped: function(drop) {
                            var spec = parse(drop)
                            if (!spec) return
                            drop.accept(Qt.CopyAction)
                            WidgetState.addWidget("notifCenter", spec.type, spec.size, spec.variant)
                        }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth:  width
                        contentHeight: _col.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: _col
                            width: parent.width
                            spacing: 8

                            ColumnLayout {
                                id: _notifsBlock
                                Layout.fillWidth: true
                                spacing: 8

                                SequentialAnimation {
                                    id: _clearAnim
                                    NumberAnimation { target: _notifsBlock; property: "opacity"; to: 0; duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                                    ScriptAction { script: NotifService.dismissAll() }
                                    PauseAnimation { duration: 20 }
                                    NumberAnimation { target: _notifsBlock; property: "opacity"; to: 1; duration: 1 }
                                }

                                Repeater {
                                    model: NotifService.systemGroupsList
                                    delegate: NotifStack {
                                        Layout.fillWidth: true
                                        Layout.topMargin: index === 0 ? 8 : 0
                                        appName: modelData.appName
                                        items:   modelData.items
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin:   8
                                    Layout.leftMargin:  2
                                    Layout.rightMargin: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Notification Center"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        font.family: "SF Pro Rounded"
                                        color: "#ffffff"
                                        renderType: Text.NativeRendering
                                    }

                                    Rectangle {
                                        width:  20
                                        height: 20
                                        radius: 10
                                        color:  Qt.rgba(1, 1, 1, 0.18)
                                        visible: NotifService.trackedCount > 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            font.pixelSize: 15
                                            font.family: "SF Pro Rounded"
                                            color: "#ffffff"
                                            renderType: Text.NativeRendering
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                _clearAnim.start()
                                            }
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    visible: NotifService.trackedCount === 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No Notifications"
                                        font.pixelSize: 12
                                        font.family: "SF Pro Rounded"
                                        color: Qt.rgba(1, 1, 1, 0.40)
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Repeater {
                                    model: NotifService.appGroupsList
                                    delegate: NotifStack {
                                        Layout.fillWidth: true
                                        appName: modelData.appName
                                        items:   modelData.items
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 10
                                    visible: NotifService.trackedCount > 0
                                }
                            }

                            Flow {
                                id: _widgetFlow
                                Layout.fillWidth: true
                                Layout.preferredHeight: _widgetFlow.childrenRect.height
                                spacing: WidgetState.gap

                                Repeater {
                                    model: WidgetState.notifCenter

                                    delegate: Item {
                                        id: _wslot
                                        required property var modelData
                                        readonly property var dims: WidgetState.sizeOf(_wslot.modelData.size)
                                        width: _wslot.dims.w
                                        height: _wslot.dims.h

                                        WidgetView {
                                            widgetData: _wslot.modelData
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.RightButton
                                            onPressed: function(mouse) {
                                                _widgetMenu.target = _wslot.modelData.id
                                                var p = mapToItem(_widgetMenu, mouse.x, mouse.y)
                                                _widgetMenu.openAt(p.x, p.y, WidgetState.menuEntries("notifCenter", _wslot.modelData))
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: _editLabel.implicitWidth + 28
                                    height: 26
                                    radius: 13
                                    color: Qt.rgba(1, 1, 1, 0.18)

                                    Text {
                                        id: _editLabel
                                        anchors.centerIn: parent
                                        text: "Edit Widgets…"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        font.family: "SF Pro Rounded"
                                        renderType: Text.NativeRendering
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: WidgetState.openGallery("notifCenter")
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 10
                            }
                        }
                    }
                }

                WidgetContextMenu {
                    id: _widgetMenu

                    property string target: ""

                    onChosen: function(action) {
                        WidgetState.applyAction("notifCenter", _widgetMenu.target, action)
                    }
                }
            }
        }
    }
}
