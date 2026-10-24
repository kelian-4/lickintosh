import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.services

Scope {
    id: root

    readonly property bool opened: WidgetState.galleryZone !== ""
    readonly property string zoneTitle: WidgetState.galleryZone === "desktop" ? "the Desktop" : "the Notification Center"

    Presence {
        id: presence
        wanted: root.opened
        exitDuration: ShellMotion.fade()
    }

    Loader {
        active: presence.present

        sourceComponent: Component {
            PanelWindow {
                id: win

                screen: {
                    var m = Hyprland.focusedMonitor
                    if (m) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === m.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace: "quickshell:widgetgallery"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                color: "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true; bottom: true; left: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: WidgetState.closeGallery()
                }

                WidgetView {
                    id: ghost
                    property bool shown: false
                    property var spec: ({ id: "ghost", type: "clock", size: "s" })
                    widgetData: ghost.spec
                    visible: ghost.shown
                    opacity: 0.9
                    z: 100
                    enabled: false
                }

                GalleryFrame {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(760, parent.width - 48)
                    height: Math.min(600, parent.height - 96)

                    property bool vis: false
                    property bool dragging: false
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
                    onDone: WidgetState.closeGallery()

                    Component.onCompleted: panel.vis = root.opened
                    Connections {
                        target: root
                        function onOpenedChanged() { panel.vis = root.opened }
                    }

                    opacity: panel.vis ? (panel.dragging ? 0.25 : 1) : 0
                    scale: panel.vis ? 1 : 0.96
                    Behavior on opacity {
                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: ShellMotion.enter(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }

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
                                font.family: "SF Pro Rounded"
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
                                    model: section.modelData.sizes

                                    delegate: Column {
                                        id: tile
                                        required property string modelData
                                        readonly property var dims: WidgetState.sizeOf(tile.modelData)

                                        spacing: 6

                                        Item {
                                            width: tile.dims.w
                                            height: tile.dims.h

                                            WidgetView {
                                                widgetData: ({ id: "preview", type: section.modelData.type, size: tile.modelData })
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
                                                    font.family: "SF Pro Rounded"
                                                    renderType: Text.NativeRendering
                                                }
                                            }

                                            MouseArea {
                                                id: tileArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: WidgetState.addWidget(WidgetState.galleryZone, section.modelData.type, tile.modelData)
                                            }

                                            DragHandler {
                                                target: null
                                                onActiveChanged: {
                                                    if (active) {
                                                        ghost.spec = ({ id: "ghost", type: section.modelData.type, size: tile.modelData })
                                                        ghost.shown = true
                                                        panel.dragging = true
                                                        return
                                                    }
                                                    var cx = ghost.x + ghost.width / 2
                                                    var cy = ghost.y + ghost.height / 2
                                                    var inside = cx >= panel.x && cx <= panel.x + panel.width && cy >= panel.y && cy <= panel.y + panel.height
                                                    ghost.shown = false
                                                    panel.dragging = false
                                                    if (!inside) {
                                                        WidgetState.addWidgetAt(WidgetState.galleryZone, section.modelData.type, tile.modelData,
                                                            ghost.x - WidgetState.desktopOffsetX, ghost.y - WidgetState.desktopOffsetY)
                                                    }
                                                }
                                                onCentroidChanged: {
                                                    if (!active) return
                                                    ghost.x = centroid.scenePosition.x - ghost.width / 2
                                                    ghost.y = centroid.scenePosition.y - ghost.height / 2
                                                }
                                            }
                                        }

                                        Text {
                                            width: tile.dims.w
                                            horizontalAlignment: Text.AlignHCenter
                                            text: WidgetRegistry.sizeLabels[tile.modelData]
                                            color: Qt.rgba(1, 1, 1, 0.55)
                                            font.pixelSize: 11
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
