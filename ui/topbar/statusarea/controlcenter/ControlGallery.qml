import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.services

Scope {
    id: root

    readonly property bool opened: ControlCatalog.galleryOpen

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

                WlrLayershell.namespace: "quickshell:controlgallery"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                color: "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true; bottom: true; left: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ControlCatalog.galleryOpen = false
                }

                Rectangle {
                    id: ghost
                    property bool shown: false
                    property var info: null
                    readonly property int unit: ControlCatalog.box
                    width: ghost.info ? ghost.info.w * ghost.unit + (ghost.info.w - 1) * ControlCatalog.boxMargin : ghost.unit
                    height: ghost.unit
                    radius: 20
                    color: "#e6303034"
                    border.width: 1
                    border.color: "#40ffffff"
                    visible: ghost.shown
                    z: 100
                    enabled: false

                    CFVI {
                        anchors.centerIn: parent
                        size: 26
                        icon: ghost.info ? ghost.info.icon : ""
                    }
                }

                GalleryFrame {
                    id: panel

                    width: Math.min(760, win.width - ControlCatalog.panelWidth - 80)
                    height: Math.min(600, win.height - 96)
                    x: Math.max(24, (win.width - ControlCatalog.panelWidth - 10 - panel.width) / 2)
                    y: (win.height - panel.height) / 2

                    property bool vis: false
                    property bool dragging: false
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
                    hint: "Click or drag a control to place it in the Control Center."
                    emptyText: "No Controls Found"
                    empty: panel.sections.length === 0
                    onDone: ControlCatalog.galleryOpen = false

                    Component.onCompleted: panel.vis = root.opened
                    Connections {
                        target: root
                        function onOpenedChanged() { panel.vis = root.opened }
                    }

                    opacity: panel.vis ? (panel.dragging ? 0.4 : 1) : 0
                    scale: panel.vis ? 1 : 0.96
                    Behavior on opacity {
                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: ShellMotion.enter(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }

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
                                Layout.preferredHeight: 1
                                color: Qt.rgba(1, 1, 1, 0.10)
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 16

                                Repeater {
                                    model: section.modelData.items

                                    delegate: Column {
                                        id: tile
                                        required property var modelData
                                        readonly property bool added: ShellConfig.ccWidgetVisible(tile.modelData.id)

                                        spacing: 6

                                        Rectangle {
                                            id: face
                                            width: tile.modelData.w * ControlCatalog.box + (tile.modelData.w - 1) * ControlCatalog.boxMargin
                                            height: ControlCatalog.box
                                            radius: 20
                                            color: faceArea.containsMouse && !tile.modelData.locked ? "#3c3c42" : "#2a2a2e"
                                            border.width: 1
                                            border.color: "#20ffffff"

                                            CFVI {
                                                anchors.centerIn: parent
                                                size: 26
                                                icon: tile.modelData.icon
                                                gray: tile.modelData.locked
                                            }

                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 6
                                                width: 18
                                                height: 18
                                                radius: 9
                                                color: tile.modelData.locked ? "#48484c" : "#a35cf0"
                                                visible: tile.added || tile.modelData.locked

                                                CFVI {
                                                    anchors.centerIn: parent
                                                    size: 10
                                                    icon: tile.modelData.locked ? "lock.svg" : "check.svg"
                                                }
                                            }

                                            MouseArea {
                                                id: faceArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: tile.modelData.locked ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                onClicked: ControlCatalog.toggle(tile.modelData.id)
                                            }

                                            DragHandler {
                                                target: null
                                                enabled: !tile.modelData.locked
                                                onActiveChanged: {
                                                    if (active) {
                                                        ghost.info = tile.modelData
                                                        ghost.shown = true
                                                        panel.dragging = true
                                                        return
                                                    }
                                                    ghost.shown = false
                                                    panel.dragging = false
                                                    ControlCatalog.dropAt(tile.modelData.id, ghost.x + ghost.width / 2, ghost.y + ghost.height / 2)
                                                }
                                                onCentroidChanged: {
                                                    if (!active) return
                                                    ghost.x = centroid.scenePosition.x - ghost.width / 2
                                                    ghost.y = centroid.scenePosition.y - ghost.height / 2
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

                                        Text {
                                            width: face.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: tile.modelData.locked ? "Always shown" : (tile.added ? "Added" : "Not added")
                                            elide: Text.ElideRight
                                            color: Qt.rgba(1, 1, 1, 0.5)
                                            font.pixelSize: 10
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
