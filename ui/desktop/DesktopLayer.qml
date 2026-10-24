import QtQuick
import QtQuick.Layouts
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
        WlrLayershell.keyboardFocus: DesktopFiles.renaming !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors { top: true; right: true; bottom: true; left: true }

        Item {
            id: stage
            anchors.fill: parent
            anchors.topMargin: WidgetState.desktopOffsetY
            anchors.leftMargin: WidgetState.desktopOffsetX
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
                    DesktopFiles.renaming = ""
                    if (mouse.button === Qt.RightButton) {
                        menu.target = { kind: "desktop" }
                        menu.openAt(mouse.x + stage.x, mouse.y + stage.y, DesktopFiles.desktopMenu())
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
                    required property var fileSize
                    required property var fileModified

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

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onPressed: function(mouse) {
                                DesktopFiles.selected = iconSlot.filePath
                                menu.target = {
                                    kind: "icon",
                                    path: iconSlot.filePath,
                                    name: iconSlot.fileName,
                                    isDir: iconSlot.fileIsDir,
                                    size: iconSlot.fileSize,
                                    modified: iconSlot.fileModified
                                }
                                var p = mapToItem(menu, mouse.x, mouse.y)
                                menu.openAt(p.x, p.y, DesktopFiles.fileMenu())
                            }
                        }

                        DragHandler {
                            target: iconMover
                            acceptedButtons: Qt.LeftButton
                            enabled: DesktopFiles.renaming !== iconSlot.filePath
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
                                menu.target = { kind: "widget", id: slot.modelData.id }
                                var p = mapToItem(menu, mouse.x, mouse.y)
                                menu.openAt(p.x, p.y, WidgetState.menuEntries("desktop", slot.modelData))
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: infoLayer
            anchors.fill: parent
            visible: DesktopFiles.infoTarget !== null
            z: 900

            MouseArea {
                anchors.fill: parent
                onPressed: DesktopFiles.infoTarget = null
            }

            Rectangle {
                anchors.centerIn: parent
                width: 320
                height: infoColumn.implicitHeight + 36
                radius: 18
                color: Qt.rgba(0.16, 0.16, 0.18, 0.97)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: infoColumn
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: DesktopFiles.infoTarget ? DesktopFiles.labelFor(DesktopFiles.infoTarget.name) : ""
                        elide: Text.ElideMiddle
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        font.family: "SF Pro Rounded"
                        renderType: Text.NativeRendering
                    }

                    Repeater {
                        model: DesktopFiles.infoTarget ? [
                            { key: "Kind", value: DesktopFiles.kindFor(DesktopFiles.infoTarget.name, DesktopFiles.infoTarget.isDir) },
                            { key: "Size", value: DesktopFiles.infoTarget.isDir ? "—" : DesktopFiles.formatSize(DesktopFiles.infoTarget.size) },
                            { key: "Modified", value: Qt.formatDateTime(DesktopFiles.infoTarget.modified, "d MMM yyyy, HH:mm") },
                            { key: "Where", value: DesktopFiles.infoTarget.path.slice(0, DesktopFiles.infoTarget.path.lastIndexOf("/")) }
                        ] : []

                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                Layout.preferredWidth: 64
                                text: modelData.key
                                color: Qt.rgba(1, 1, 1, 0.55)
                                font.pixelSize: 12
                                font.family: "SF Pro Rounded"
                                renderType: Text.NativeRendering
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                elide: Text.ElideMiddle
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.family: "SF Pro Rounded"
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        WidgetContextMenu {
            id: menu

            property var target: ({ kind: "desktop" })

            onChosen: function(action) {
                if (menu.target.kind === "widget") WidgetState.applyAction("desktop", menu.target.id, action)
                else DesktopFiles.handle(action, menu.target)
            }
        }
    }
}
