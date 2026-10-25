import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

Scope {
    id: root

    Loader {
        active: ControlCatalog.galleryOpen

        sourceComponent: Component {
            FloatingWindow {
                id: win

                visible: true
                title: "Edit Controls"
                implicitWidth: 820
                implicitHeight: 600
                minimumSize: Qt.size(820, 600)
                maximumSize: Qt.size(820, 600)
                color: "transparent"

                onClosed: ControlCatalog.galleryOpen = false

                GalleryFrame {
                    id: panel
                    anchors.fill: parent
                    window: win

                    readonly property var sections: ControlCatalog.categories.map(function(cat) {
                        return {
                            cat: cat,
                            items: ControlCatalog.controls.filter(function(c) {
                                var inQuery = panel.query === "" || c.title.toLowerCase().indexOf(panel.query.toLowerCase()) >= 0
                                return c.category === cat.key && inQuery
                            })
                        }
                    }).filter(function(s) {
                        return s.items.length > 0 && (panel.category === "all" || panel.category === s.cat.key)
                    })

                    categories: [{ key: "all", title: "All Controls", icon: "notch/columns.svg", tint: "#8e8e93" }].concat(
                        ControlCatalog.categories.map(function(c) {
                            return { key: c.key, title: c.title, icon: c.icon, tint: c.tint }
                        }))
                    searchPlaceholder: "Search Controls"
                    hint: "Drag a control into Control Center, or click it to add."
                    emptyText: "No Controls Found"
                    empty: panel.sections.length === 0
                    onDone: win.close()

                    Repeater {
                        model: panel.sections

                        delegate: ColumnLayout {
                            id: section
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: section.modelData.cat.title
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                font.family: "SF Pro Rounded"
                                renderType: Text.NativeRendering
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: flow.implicitHeight + 16
                                color: "transparent"

                                Flow {
                                    id: flow
                                    x: 4
                                    y: 8
                                    width: parent.width - 8
                                    spacing: 18

                                    Repeater {
                                        model: section.modelData.items

                                        delegate: Column {
                                            id: tile
                                            required property var modelData
                                            readonly property bool added: ShellConfig.ccWidgetVisible(tile.modelData.id)

                                            spacing: 6

                                            ControlPreview {
                                                id: face
                                                info: tile.modelData
                                                opacity: tile.added ? 0.55 : 1

                                                Drag.active: dragHandler.active
                                                Drag.dragType: Drag.Automatic
                                                Drag.supportedActions: Qt.CopyAction
                                                Drag.proposedAction: Qt.CopyAction
                                                Drag.mimeData: ({ "text/plain": "cc:" + tile.modelData.id })
                                                Drag.hotSpot.x: face.width / 2
                                                Drag.hotSpot.y: face.height / 2

                                                MouseArea {
                                                    id: faceArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onPressed: face.grabToImage(function(result) { face.Drag.imageSource = result.url })
                                                    onClicked: ControlCatalog.add(tile.modelData.id)
                                                }

                                                DragHandler {
                                                    id: dragHandler
                                                    target: null
                                                    grabPermissions: PointerHandler.CanTakeOverFromAnything
                                                }

                                                Rectangle {
                                                    anchors.top: parent.top
                                                    anchors.right: parent.right
                                                    anchors.topMargin: -4
                                                    anchors.rightMargin: -4
                                                    width: 22
                                                    height: 22
                                                    radius: 11
                                                    color: tile.added ? "#48484c" : "#a35cf0"
                                                    border.width: 1
                                                    border.color: "#50ffffff"
                                                    visible: tile.added || faceArea.containsMouse

                                                    CFVI {
                                                        anchors.centerIn: parent
                                                        size: 11
                                                        visible: tile.added
                                                        icon: "check.svg"
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !tile.added
                                                        text: "+"
                                                        color: "#ffffff"
                                                        font.pixelSize: 17
                                                        font.family: "SF Pro Rounded"
                                                        renderType: Text.NativeRendering
                                                    }
                                                }
                                            }

                                            Text {
                                                width: face.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: tile.modelData.title
                                                elide: Text.ElideRight
                                                color: "#ffffff"
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                font.family: "SF Pro Rounded"
                                                renderType: Text.NativeRendering
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
}
