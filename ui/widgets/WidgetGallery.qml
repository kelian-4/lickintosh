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
    readonly property string zoneTitle: WidgetState.galleryZone === "desktop" ? "Desktop" : "Notification Center"

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
                color: "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true; bottom: true; left: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: WidgetState.closeGallery()
                }

                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(720, parent.width - 48)
                    height: Math.min(560, parent.height - 96)
                    radius: 26
                    color: Qt.rgba(0.11, 0.11, 0.13, 0.96)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    property bool vis: false
                    Component.onCompleted: panel.vis = root.opened
                    Connections {
                        target: root
                        function onOpenedChanged() { panel.vis = root.opened }
                    }

                    opacity: panel.vis ? 1 : 0
                    scale: panel.vis ? 1 : 0.96
                    Behavior on opacity {
                        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: ShellMotion.enter(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(e) { e.accepted = true }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 0

                                Text {
                                    text: "Widgets"
                                    color: "#ffffff"
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    font.family: "SF Pro Rounded"
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: "Add to " + root.zoneTitle
                                    color: Qt.rgba(1, 1, 1, 0.55)
                                    font.pixelSize: 12
                                    font.family: "SF Pro Rounded"
                                    renderType: Text.NativeRendering
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 28
                                radius: 14
                                color: ShellConfig.options.appearance.accentColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Done"
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: "SF Pro Rounded"
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WidgetState.closeGallery()
                                }
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: sections.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: sections
                                width: parent.width
                                spacing: 18

                                Repeater {
                                    model: WidgetRegistry.types

                                    delegate: ColumnLayout {
                                        id: section
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: section.modelData.title
                                            color: "#ffffff"
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            font.family: "SF Pro Rounded"
                                            renderType: Text.NativeRendering
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: WidgetState.gap

                                            Repeater {
                                                model: section.modelData.sizes

                                                delegate: Item {
                                                    id: tile
                                                    required property string modelData
                                                    readonly property var dims: WidgetState.sizeOf(tile.modelData)

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
                                                        color: ShellConfig.options.appearance.accentColor
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
}
