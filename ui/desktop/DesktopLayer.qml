import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.ui.widgets

Scope {
    id: root

    PanelWindow {
        id: win

        screen: Quickshell.screens[0]

        WlrLayershell.namespace: "quickshell:desktop"
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors { top: true; right: true; bottom: true; left: true }

        Item {
            id: stage
            anchors.fill: parent
            anchors.topMargin: 44
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16

            readonly property int iconW: 96
            readonly property int iconH: 104
            readonly property int iconRows: Math.max(1, Math.floor(stage.height / stage.iconH))

            Binding {
                target: WidgetState
                property: "areaWidth"
                value: stage.width
            }

            Binding {
                target: WidgetState
                property: "areaHeight"
                value: stage.height
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: function(mouse) {
                    DesktopFiles.selected = ""
                    if (mouse.button === Qt.RightButton) {
                        menu.target = ""
                        menu.openAt(mouse.x + stage.x, mouse.y + stage.y, WidgetState.menuEntries("desktop", null))
                    }
                }
            }

            Repeater {
                model: DesktopFiles.model

                delegate: Item {
                    id: iconSlot

                    required property int index
                    required property string fileName
                    required property string filePath
                    required property bool fileIsDir

                    readonly property var saved: WidgetState.iconPosition(iconSlot.fileName)
                    readonly property real homeX: stage.width - (Math.floor(iconSlot.index / stage.iconRows) + 1) * stage.iconW
                    readonly property real homeY: (iconSlot.index % stage.iconRows) * stage.iconH

                    x: iconSlot.saved ? Math.min(iconSlot.saved.x, stage.width - stage.iconW) : iconSlot.homeX
                    y: iconSlot.saved ? Math.min(iconSlot.saved.y, stage.height - stage.iconH) : iconSlot.homeY
                    width: stage.iconW
                    height: stage.iconH

                    Item {
                        id: iconMover
                        width: parent.width
                        height: parent.height

                        DesktopIcon {
                            fileName: iconSlot.fileName
                            filePath: iconSlot.filePath
                            fileIsDir: iconSlot.fileIsDir
                        }

                        DragHandler {
                            target: iconMover
                            acceptedButtons: Qt.LeftButton
                            onActiveChanged: {
                                if (active) return
                                var nx = Math.round((iconSlot.x + iconMover.x) / stage.iconW) * stage.iconW
                                var ny = Math.round((iconSlot.y + iconMover.y) / stage.iconH) * stage.iconH
                                nx = Math.max(0, Math.min(nx, stage.width - stage.iconW))
                                ny = Math.max(0, Math.min(ny, stage.height - stage.iconH))
                                iconMover.x = 0
                                iconMover.y = 0
                                WidgetState.setIconPosition(iconSlot.fileName, nx, ny)
                            }
                        }
                    }
                }
            }

            Repeater {
                model: WidgetState.desktop

                delegate: Item {
                    id: slot

                    required property var modelData
                    readonly property var dims: WidgetState.sizeOf(slot.modelData.size)

                    x: slot.modelData.x
                    y: slot.modelData.y
                    width: slot.dims.w
                    height: slot.dims.h

                    Item {
                        id: mover
                        width: parent.width
                        height: parent.height

                        WidgetView {
                            widgetData: slot.modelData
                        }

                        DragHandler {
                            target: mover
                            acceptedButtons: Qt.LeftButton
                            onActiveChanged: {
                                if (active) return
                                var nx = slot.x + mover.x
                                var ny = slot.y + mover.y
                                mover.x = 0
                                mover.y = 0
                                WidgetState.moveWidget(slot.modelData.id, nx, ny)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onPressed: function(mouse) {
                                menu.target = slot.modelData.id
                                var p = mapToItem(menu, mouse.x, mouse.y)
                                menu.openAt(p.x, p.y, WidgetState.menuEntries("desktop", slot.modelData))
                            }
                        }
                    }
                }
            }
        }

        WidgetContextMenu {
            id: menu

            property string target: ""

            onChosen: function(action) {
                WidgetState.applyAction("desktop", menu.target, action)
            }
        }
    }
}
