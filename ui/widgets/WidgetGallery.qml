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

                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(700, parent.width - 48)
                    height: Math.min(580, parent.height - 96)
                    radius: 26
                    color: Qt.rgba(0.13, 0.13, 0.15, 0.97)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    property string category: "all"
                    property string query: ""
                    readonly property var filtered: WidgetRegistry.types.filter(function(t) {
                        var inCategory = panel.category === "all" || t.type === panel.category
                        var inQuery = panel.query === "" || t.title.toLowerCase().indexOf(panel.query.toLowerCase()) >= 0
                        return inCategory && inQuery
                    })

                    property bool vis: false
                    Component.onCompleted: panel.vis = root.opened
                    Connections {
                        target: root
                        function onOpenedChanged() { panel.vis = root.opened }
                    }

                    property bool dragging: false

                    opacity: panel.vis ? (panel.dragging ? 0.25 : 1) : 0
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

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 196
                            color: Qt.rgba(0, 0, 0, 0.18)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    radius: 10
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    border.width: searchInput.activeFocus ? 2 : 1
                                    border.color: searchInput.activeFocus ? "#a35cf0" : Qt.rgba(1, 1, 1, 0.12)

                                    TextInput {
                                        id: searchInput
                                        focus: true
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "#ffffff"
                                        clip: true
                                        selectByMouse: true
                                        font.pixelSize: 13
                                        font.family: "SF Pro Rounded"
                                        renderType: Text.NativeRendering
                                        onTextChanged: panel.query = searchInput.text
                                        Keys.onEscapePressed: WidgetState.closeGallery()

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            visible: searchInput.text === "" && !searchInput.preeditText
                                            text: "Search Widgets"
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font: searchInput.font
                                            renderType: Text.NativeRendering
                                        }
                                    }
                                }

                                Repeater {
                                    model: [{ type: "all", title: "All Widgets", icon: "notch/columns.svg", tint: "#8e8e93" }].concat(WidgetRegistry.types)

                                    delegate: Rectangle {
                                        id: category
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 10
                                        color: panel.category === category.modelData.type ? Qt.rgba(1, 1, 1, 0.14) : (catArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 10

                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                radius: 6
                                                color: category.modelData.tint

                                                CFVI {
                                                    anchors.centerIn: parent
                                                    size: 14
                                                    icon: category.modelData.icon
                                                    colorized: category.modelData.type !== "weather"
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: category.modelData.title
                                                elide: Text.ElideRight
                                                color: "#ffffff"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                font.family: "SF Pro Rounded"
                                                renderType: Text.NativeRendering
                                            }
                                        }

                                        MouseArea {
                                            id: catArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.category = category.modelData.type
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 0

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.margins: 18
                                contentWidth: width
                                contentHeight: sections.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: sections
                                    width: parent.width
                                    spacing: 20

                                    Text {
                                        Layout.fillWidth: true
                                        visible: panel.filtered.length === 0
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "No Widgets Found"
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 14
                                        font.family: "SF Pro Rounded"
                                        renderType: Text.NativeRendering
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

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Qt.rgba(1, 1, 1, 0.10)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                Layout.leftMargin: 18
                                Layout.rightMargin: 18

                                Text {
                                    Layout.fillWidth: true
                                    text: "Click or drag a widget to add it to " + root.zoneTitle + "."
                                    elide: Text.ElideRight
                                    color: Qt.rgba(1, 1, 1, 0.75)
                                    font.pixelSize: 12
                                    font.family: "SF Pro Rounded"
                                    renderType: Text.NativeRendering
                                }

                                Rectangle {
                                    Layout.preferredWidth: 68
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: "#a35cf0"

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
                        }
                    }
                }
            }
        }
    }
}
