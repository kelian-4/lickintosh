import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

Scope {
    id: root

    readonly property bool opened: WidgetState.galleryZone !== ""
    readonly property string zoneTitle: WidgetState.galleryZone === "desktop" ? "the Desktop" : "the Notification Center"

    Loader {
        active: root.opened

        sourceComponent: Component {
            FloatingWindow {
                id: win

                visible: true
                title: "Edit Widgets"
                implicitWidth: 820
                implicitHeight: 620
                minimumSize: Qt.size(820, 620)
                maximumSize: Qt.size(820, 620)
                color: "transparent"

                onClosed: WidgetState.closeGallery()

                GalleryFrame {
                    id: panel
                    anchors.fill: parent
                    window: win

                    readonly property var filtered: WidgetRegistry.types.filter(function(t) {
                        var inCategory = panel.category === "all" || t.type === panel.category
                        var inQuery = panel.query === "" || t.title.toLowerCase().indexOf(panel.query.toLowerCase()) >= 0
                        return inCategory && inQuery
                    })

                    categories: [{ key: "all", title: "All Widgets", icon: "notch/columns.svg", tint: "#8e8e93" }].concat(
                        WidgetRegistry.types.map(function(t) {
                            return { key: t.type, title: t.title, icon: t.icon, tint: t.tint, raw: t.type === "weather" }
                        }))
                    searchPlaceholder: "Search Widgets"
                    hint: "Click or drag a widget to add it to " + root.zoneTitle + "."
                    emptyText: "No Widgets Found"
                    empty: panel.filtered.length === 0
                    showThemes: true
                    theme: WidgetState.galleryTheme
                    onThemePicked: function(theme) { WidgetState.galleryTheme = theme }
                    onDone: WidgetState.closeGallery()

                    Repeater {
                        model: panel.filtered

                        delegate: ColumnLayout {
                            id: section
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: section.modelData.title
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                font.family: "SF Pro Text"
                                renderType: Text.NativeRendering
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Qt.rgba(1, 1, 1, 0.10)
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: WidgetState.gap

                                Repeater {
                                    model: WidgetRegistry.tilesOf(section.modelData.type)

                                    delegate: Column {
                                        id: tile
                                        required property var modelData
                                        readonly property var dims: WidgetState.sizeOf(tile.modelData.size)

                                        spacing: 6

                                        Item {
                                            id: face
                                            width: tile.dims.w
                                            height: tile.dims.h

                                            Drag.active: dragHandler.active
                                            Drag.dragType: Drag.Automatic
                                            Drag.supportedActions: Qt.CopyAction
                                            Drag.proposedAction: Qt.CopyAction
                                            Drag.mimeData: ({ "text/plain": "widget:" + section.modelData.type + ":" + tile.modelData.size + ":" + tile.modelData.variant + ":" + WidgetState.galleryTheme })
                                            Drag.hotSpot.x: face.width / 2
                                            Drag.hotSpot.y: face.height / 2

                                            WidgetView {
                                                widgetData: ({ id: "preview", type: section.modelData.type, variant: tile.modelData.variant, size: tile.modelData.size, theme: WidgetState.galleryTheme })
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 22
                                                color: tileArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                            }

                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 8
                                                width: 24
                                                height: 24
                                                radius: 12
                                                color: "#a35cf0"
                                                visible: tileArea.containsMouse

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "+"
                                                    color: "#ffffff"
                                                    font.pixelSize: 18
                                                    font.family: "SF Pro Text"
                                                    renderType: Text.NativeRendering
                                                }
                                            }

                                            MouseArea {
                                                id: tileArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onPressed: face.grabToImage(function(result) { face.Drag.imageSource = result.url }, Qt.size(face.width, face.height))
                                                onClicked: WidgetState.addWidget(WidgetState.galleryZone, section.modelData.type, tile.modelData.size, tile.modelData.variant, WidgetState.galleryTheme)
                                            }

                                            DragHandler {
                                                id: dragHandler
                                                target: null
                                                grabPermissions: PointerHandler.CanTakeOverFromAnything
                                            }
                                        }

                                        Text {
                                            width: tile.dims.w
                                            horizontalAlignment: Text.AlignHCenter
                                            text: tile.modelData.label
                                            color: Qt.rgba(1, 1, 1, 0.55)
                                            font.pixelSize: 11
                                            font.family: "SF Pro Text"
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
