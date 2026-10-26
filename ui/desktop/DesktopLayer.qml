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
        WlrLayershell.keyboardFocus: DesktopFiles.renaming !== "" || WidgetState.typing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

            readonly property real iconW: 96
            readonly property real iconH: 104
            readonly property real iconPad: 8
            readonly property int iconCols: Math.max(1, Math.floor((stage.width - stage.iconPad * 2) / stage.iconW))
            readonly property int iconRows: Math.max(1, Math.floor((stage.height - stage.iconPad * 2) / stage.iconH))

            property var iconCells: ({})

            function fileNames() {
                var names = []
                for (var i = 0; i < DesktopFiles.model.count; i++) names.push(DesktopFiles.model.get(i, "fileName"))
                return names
            }

            function relayout() {
                var names = stage.fileNames()
                var saved = WidgetState.iconPositions
                var taken = {}
                var result = {}
                names.forEach(function(name) {
                    for (var j = 0; j < saved.length; j++) {
                        if (saved[j].name !== name) continue
                        if (saved[j].col < 0 || saved[j].row < 0 || saved[j].col >= stage.iconCols || saved[j].row >= stage.iconRows) return
                        var key = saved[j].col + "," + saved[j].row
                        if (taken[key]) return
                        taken[key] = true
                        result[name] = { col: saved[j].col, row: saved[j].row }
                        return
                    }
                })
                names.forEach(function(name) {
                    if (result[name]) return
                    for (var col = 0; result[name] === undefined; col++) {
                        for (var row = 0; row < stage.iconRows; row++) {
                            var key = col + "," + row
                            if (taken[key]) continue
                            taken[key] = true
                            result[name] = { col: col, row: row }
                            break
                        }
                    }
                })
                stage.iconCells = result
            }

            function cellX(col) {
                return stage.width - stage.iconPad - (col + 1) * stage.iconW
            }

            function cellY(row) {
                return stage.iconPad + row * stage.iconH
            }

            function dropIcon(name, centerX, centerY) {
                var targetCol = Math.min(stage.iconCols - 1, Math.max(0, Math.round((stage.width - stage.iconPad - centerX) / stage.iconW - 0.5)))
                var targetRow = Math.min(stage.iconRows - 1, Math.max(0, Math.round((centerY - stage.iconPad - stage.iconH / 2) / stage.iconH)))
                var spot = stage.nearestFreeCell(name, targetCol, targetRow, [])
                WidgetState.setIconPosition(name, spot.col, spot.row)
            }

            function nearestFreeCell(name, col, row, extra) {
                var occupied = {}
                for (var other in stage.iconCells) {
                    if (other === name) continue
                    occupied[stage.iconCells[other].col + "," + stage.iconCells[other].row] = true
                }
                for (var k = 0; k < extra.length; k++) occupied[extra[k].col + "," + extra[k].row] = true
                var best = null
                for (var c = 0; c < stage.iconCols; c++) {
                    for (var r = 0; r < stage.iconRows; r++) {
                        if (occupied[c + "," + r]) continue
                        var dist = (c - col) * (c - col) + (r - row) * (r - row)
                        if (best === null || dist < best.dist) best = { col: c, row: r, dist: dist }
                    }
                }
                return best || { col: col, row: row }
            }

            onIconColsChanged: stage.relayout()
            onIconRowsChanged: stage.relayout()
            Component.onCompleted: stage.relayout()

            Connections {
                target: DesktopFiles.model

                function onCountChanged() { stage.relayout() }
                function onModelReset() { stage.relayout() }
                function onRowsInserted() { stage.relayout() }
                function onRowsRemoved() { stage.relayout() }
            }

            Connections {
                target: WidgetState

                function onIconPositionsChanged() { stage.relayout() }
            }

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
                    stage.forceActiveFocus()
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

                delegate: DesktopIcon {
                    id: icon

                    required property var fileSize
                    required property var fileModified

                    cellX: stage.cellX(stage.iconCells[icon.fileName] ? stage.iconCells[icon.fileName].col : 0)
                    cellY: stage.cellY(stage.iconCells[icon.fileName] ? stage.iconCells[icon.fileName].row : 0)
                    cellWidth: stage.iconW
                    cellHeight: stage.iconH

                    onDropped: function(centerX, centerY) { stage.dropIcon(icon.fileName, centerX, centerY) }
                    onContextRequested: function(x, y) {
                        DesktopFiles.selected = icon.filePath
                        menu.target = {
                            kind: "icon",
                            path: icon.filePath,
                            name: icon.fileName,
                            isDir: icon.fileIsDir,
                            size: icon.fileSize,
                            modified: icon.fileModified
                        }
                        var p = stage.mapToItem(menu, x, y)
                        menu.openAt(p.x, p.y, DesktopFiles.fileMenu())
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
                keys: ["text/uri-list"]

                onEntered: function(drag) {
                    drag.accepted = drag.hasUrls
                }
                onDropped: function(drop) {
                    if (!drop.hasUrls) return
                    drop.accept(Qt.CopyAction)
                    var names = DesktopFiles.linkNames(drop.urls)
                    var taken = []
                    for (var i = 0; i < names.length; i++) {
                        var baseCol = Math.min(stage.iconCols - 1, Math.max(0, Math.round((stage.width - stage.iconPad - drop.x) / stage.iconW - 0.5)))
                        var baseRow = Math.min(stage.iconRows - 1, Math.max(0, Math.round((drop.y - stage.iconPad - stage.iconH / 2) / stage.iconH)))
                        var spot = stage.nearestFreeCell(names[i], baseCol, baseRow, taken)
                        taken.push(spot)
                        WidgetState.setIconPosition(names[i], spot.col, spot.row)
                    }
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/plain"]

                function parse(drag) {
                    if (!drag.hasText || drag.text.indexOf("widget:") !== 0) return null
                    var parts = drag.text.split(":")
                    return { type: parts[1], size: parts[2], variant: parts[3] || "" }
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
                    WidgetState.addWidgetAt("desktop", spec.type, spec.size, spec.variant, dropGuide.gx, dropGuide.gy)
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
                        font.family: "SF Pro Text"
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
                                font.family: "SF Pro Text"
                                renderType: Text.NativeRendering
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                elide: Text.ElideMiddle
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.family: "SF Pro Text"
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
