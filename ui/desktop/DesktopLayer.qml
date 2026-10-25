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

                    property bool dragging: false
                    property real dragDX: 0
                    property real dragDY: 0

                    x: (iconSlot.saved ? Math.min(iconSlot.saved.x, stage.width - stage.iconW) : iconSlot.homeX) + iconSlot.dragDX
                    y: (iconSlot.saved ? Math.min(iconSlot.saved.y, stage.height - stage.iconH) : iconSlot.homeY) + iconSlot.dragDY
                    z: iconSlot.dragging ? 100 : 0
                    width: stage.iconW
                    height: stage.iconH

                    Behavior on x {
                        enabled: !iconSlot.dragging
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }
                    Behavior on y {
                        enabled: !iconSlot.dragging
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }

                    Item {
                        id: iconMover
                        width: parent.width
                        height: parent.height
                        scale: iconSlot.dragging ? 1.06 : 1
                        Behavior on scale {
                            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                        }

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
                            target: null
                            acceptedButtons: Qt.LeftButton
                            enabled: DesktopFiles.renaming !== iconSlot.filePath
                            onActiveChanged: {
                                if (active) {
                                    iconSlot.dragging = true
                                    return
                                }
                                var rawX = iconSlot.x
                                var rawY = iconSlot.y
                                var nx = Math.round(rawX / stage.iconW) * stage.iconW
                                var ny = Math.round(rawY / stage.iconH) * stage.iconH
                                nx = Math.max(0, Math.min(nx, stage.width - stage.iconW))
                                ny = Math.max(0, Math.min(ny, stage.height - stage.iconH))
                                iconSlot.dragging = false
                                iconSlot.dragDX = 0
                                iconSlot.dragDY = 0
                                WidgetState.setIconPosition(iconSlot.fileName, nx, ny)
                            }
                            onCentroidChanged: {
                                if (!active) return
                                iconSlot.dragDX = centroid.scenePosition.x - centroid.scenePressPosition.x
                                iconSlot.dragDY = centroid.scenePosition.y - centroid.scenePressPosition.y
                            }
                        }
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: WidgetState.desktop
                    objectProp: "id"
                }

                delegate: Item {
                    id: slot

                    required property var modelData
                    readonly property var spec: WidgetState.entryOf("desktop", slot.modelData.id) || slot.modelData
                    readonly property var dims: WidgetState.sizeOf(slot.spec.size)

                    property bool dragging: false
                    property real dragDX: 0
                    property real dragDY: 0

                    x: slot.spec.x + slot.dragDX
                    y: slot.spec.y + slot.dragDY
                    z: slot.dragging ? 100 : 0
                    width: slot.dims.w
                    height: slot.dims.h
                    scale: slot.dragging ? 1.04 : 1

                    Behavior on x {
                        enabled: !slot.dragging
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }
                    Behavior on y {
                        enabled: !slot.dragging
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                    }

                    WidgetView {
                        widgetData: slot.spec
                    }

                    DragHandler {
                        target: null
                        acceptedButtons: Qt.LeftButton
                        onActiveChanged: {
                            if (active) {
                                slot.dragging = true
                                return
                            }
                            var nx = slot.x
                            var ny = slot.y
                            slot.dragging = false
                            slot.dragDX = 0
                            slot.dragDY = 0
                            WidgetState.moveWidget(slot.modelData.id, nx, ny)
                        }
                        onCentroidChanged: {
                            if (!active) return
                            slot.dragDX = centroid.scenePosition.x - centroid.scenePressPosition.x
                            slot.dragDY = centroid.scenePosition.y - centroid.scenePressPosition.y
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: function(mouse) {
                            menu.target = { kind: "widget", id: slot.modelData.id }
                            var p = mapToItem(menu, mouse.x, mouse.y)
                            menu.openAt(p.x, p.y, WidgetState.menuEntries("desktop", slot.spec))
                        }
                    }
                }
            }

            Rectangle {
                id: dropGuide
                property var shape: null
                property real gx: 0
                property real gy: 0
                property bool active: false
                x: dropGuide.gx
                y: dropGuide.gy
                width: dropGuide.shape ? dropGuide.shape.w : 0
                height: dropGuide.shape ? dropGuide.shape.h : 0
                radius: 22
                color: "#30ffffff"
                border.width: 2
                border.color: "#80ffffff"
                opacity: dropGuide.active ? 1 : 0
                visible: opacity > 0
                Behavior on x {
                    enabled: dropGuide.opacity > 0.5
                    NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                }
                Behavior on y {
                    enabled: dropGuide.opacity > 0.5
                    NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
                }
                Behavior on opacity {
                    NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/plain"]

                function parse(drag) {
                    if (!drag.hasText || drag.text.indexOf("widget:") !== 0) return null
                    var parts = drag.text.split(":")
                    return { type: parts[1], size: parts[2] }
                }

                function track(drag) {
                    var spec = parse(drag)
                    if (!spec) return
                    var d = WidgetState.sizeOf(spec.size)
                    var p = WidgetState.snap(spec.size, drag.x - d.w / 2, drag.y - d.h / 2)
                    dropGuide.shape = d
                    dropGuide.gx = p.x
                    dropGuide.gy = p.y
                    dropGuide.active = true
                }

                onEntered: function(drag) {
                    drag.accepted = WidgetState.galleryZone === "desktop" && parse(drag) !== null
                    if (drag.accepted) track(drag)
                }
                onPositionChanged: function(drag) { track(drag) }
                onExited: dropGuide.active = false
                onDropped: function(drop) {
                    var spec = parse(drop)
                    dropGuide.active = false
                    if (!spec) return
                    drop.accept(Qt.CopyAction)
                    WidgetState.addWidgetAt("desktop", spec.type, spec.size, dropGuide.gx, dropGuide.gy)
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
