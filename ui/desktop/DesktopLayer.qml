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
            anchors.bottomMargin: 0

            readonly property real iconW: 96
            readonly property real iconH: 100
            readonly property real iconPad: 8
            readonly property int iconCols: Math.max(1, Math.floor((stage.width - stage.iconPad * 2) / stage.iconW))
            readonly property int iconRows: Math.max(1, Math.floor((stage.height - stage.iconPad * 2) / stage.iconH))

            property var iconCells: ({})
            property var iconPaths: ({})
            property bool groupDragging: false
            property var preview: ({})
            property real groupDX: 0
            property real groupDY: 0

            function fileNames() {
                var names = []
                for (var i = 0; i < DesktopFiles.model.count; i++) names.push(DesktopFiles.model.get(i, "fileName"))
                return names
            }

            function relayout() {
                var names = stage.fileNames()
                var paths = {}
                for (var n = 0; n < DesktopFiles.model.count; n++) paths[DesktopFiles.model.get(n, "fileName")] = DesktopFiles.model.get(n, "filePath")
                stage.iconPaths = paths
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

            function cellFromCenter(centerX, centerY) {
                return {
                    col: Math.min(stage.iconCols - 1, Math.max(0, Math.round((stage.width - stage.iconPad - centerX) / stage.iconW - 0.5))),
                    row: Math.min(stage.iconRows - 1, Math.max(0, Math.round((centerY - stage.iconPad - stage.iconH / 2) / stage.iconH)))
                }
            }

            function commitCells(overrides) {
                var list = []
                for (var name in stage.iconCells) {
                    var cell = overrides[name] || stage.iconCells[name]
                    list.push({ name: name, col: cell.col, row: cell.row })
                }
                for (var extra in overrides) {
                    if (stage.iconCells[extra] === undefined) list.push({ name: extra, col: overrides[extra].col, row: overrides[extra].row })
                }
                WidgetState.setIconPositions(list)
            }

            function selectedNames() {
                var names = []
                for (var name in stage.iconPaths) {
                    if (DesktopFiles.isSelected(stage.iconPaths[name])) names.push(name)
                }
                return names
            }

            function nearestAvoiding(blocked, col, row) {
                var best = null
                for (var c = 0; c < stage.iconCols; c++) {
                    for (var r = 0; r < stage.iconRows; r++) {
                        if (blocked[c + "," + r]) continue
                        var dist = (c - col) * (c - col) + (r - row) * (r - row)
                        if (best === null || dist < best.dist) best = { col: c, row: r, dist: dist }
                    }
                }
                return best || { col: col, row: row }
            }

            function computeDrop(name, centerX, centerY) {
                var group = stage.selectedNames()
                if (group.indexOf(name) < 0) group = [name]
                var inGroup = {}
                group.forEach(function(member) { inGroup[member] = true })
                var origin = stage.iconCells[name]
                var target = stage.cellFromCenter(centerX, centerY)
                var occupant = {}
                for (var other in stage.iconCells) {
                    if (inGroup[other]) continue
                    occupant[stage.iconCells[other].col + "," + stage.iconCells[other].row] = other
                }
                var claimed = {}
                var overrides = {}
                var displaced = []
                var ordered = [name].concat(group.filter(function(member) { return member !== name }))
                ordered.forEach(function(member) {
                    var from = stage.iconCells[member]
                    var col = member === name ? target.col : Math.min(stage.iconCols - 1, Math.max(0, from.col + target.col - origin.col))
                    var row = member === name ? target.row : Math.min(stage.iconRows - 1, Math.max(0, from.row + target.row - origin.row))
                    var spot = claimed[col + "," + row] ? stage.nearestAvoiding(claimed, col, row) : { col: col, row: row }
                    var key = spot.col + "," + spot.row
                    claimed[key] = true
                    overrides[member] = { col: spot.col, row: spot.row }
                    if (occupant[key] !== undefined) {
                        displaced.push({ name: occupant[key], prefer: from })
                        delete occupant[key]
                    }
                })
                var blocked = {}
                for (var key in claimed) blocked[key] = true
                for (var k in occupant) blocked[k] = true
                displaced.forEach(function(entry) {
                    var home = stage.iconCells[entry.name]
                    var spot = !blocked[entry.prefer.col + "," + entry.prefer.row] ? { col: entry.prefer.col, row: entry.prefer.row } : stage.nearestAvoiding(blocked, home.col, home.row)
                    blocked[spot.col + "," + spot.row] = true
                    overrides[entry.name] = spot
                })
                return overrides
            }

            function dropIcon(name, centerX, centerY) {
                var overrides = stage.computeDrop(name, centerX, centerY)
                stage.commitCells(overrides)
                stage.preview = ({})
                stage.groupDragging = false
                stage.groupDX = 0
                stage.groupDY = 0
            }

            function nearestFreeCell(skip, col, row, extra) {
                var occupied = {}
                for (var other in stage.iconCells) {
                    if (skip[other]) continue
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
                id: backdrop

                property real startX: 0
                property real startY: 0
                property var baseSelection: []
                property bool banding: false

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                function updateBand(mouse) {
                    var x1 = Math.min(backdrop.startX, mouse.x)
                    var y1 = Math.min(backdrop.startY, mouse.y)
                    var x2 = Math.max(backdrop.startX, mouse.x)
                    var y2 = Math.max(backdrop.startY, mouse.y)
                    band.x = x1
                    band.y = y1
                    band.width = x2 - x1
                    band.height = y2 - y1
                    var picked = backdrop.baseSelection.slice()
                    for (var name in stage.iconCells) {
                        var cell = stage.iconCells[name]
                        var left = stage.cellX(cell.col) + 6
                        var top = stage.cellY(cell.row) + 4
                        var hit = left < x2 && left + stage.iconW - 12 > x1 && top < y2 && top + stage.iconH - 8 > y1
                        var path = stage.iconPaths[name]
                        if (hit && picked.indexOf(path) < 0) picked.push(path)
                    }
                    DesktopFiles.selectMany(picked)
                }

                onPressed: function(mouse) {
                    stage.forceActiveFocus()
                    DesktopFiles.renaming = ""
                    if (mouse.button === Qt.RightButton) {
                        DesktopFiles.clearSelection()
                        menu.target = { kind: "desktop" }
                        menu.openAt(mouse.x + stage.x, mouse.y + stage.y, DesktopFiles.desktopMenu())
                        return
                    }
                    backdrop.startX = mouse.x
                    backdrop.startY = mouse.y
                    backdrop.baseSelection = (mouse.modifiers & Qt.ControlModifier) ? DesktopFiles.selection.slice() : []
                    if (!(mouse.modifiers & Qt.ControlModifier)) DesktopFiles.clearSelection()
                }
                onPositionChanged: function(mouse) {
                    if (!pressed || pressedButtons !== Qt.LeftButton) return
                    if (!backdrop.banding && Math.abs(mouse.x - backdrop.startX) + Math.abs(mouse.y - backdrop.startY) < 6) return
                    backdrop.banding = true
                    backdrop.updateBand(mouse)
                }
                onReleased: backdrop.banding = false
            }

            Repeater {
                model: DesktopFiles.model

                delegate: DesktopIcon {
                    id: icon

                    required property var fileSize
                    required property var fileModified

                    readonly property var shownCell: (!icon.selected && stage.preview[icon.fileName]) ? stage.preview[icon.fileName] : (stage.iconCells[icon.fileName] || ({ col: 0, row: 0 }))

                    cellX: stage.cellX(icon.shownCell.col)
                    cellY: stage.cellY(icon.shownCell.row)
                    cellWidth: stage.iconW
                    cellHeight: stage.iconH
                    instant: icon.selected && stage.groupDragging
                    followX: icon.selected && !icon.dragActive && stage.groupDragging ? stage.groupDX : 0
                    followY: icon.selected && !icon.dragActive && stage.groupDragging ? stage.groupDY : 0

                    onDragMoved: function(dx, dy) {
                        stage.groupDragging = true
                        stage.groupDX = dx
                        stage.groupDY = dy
                        stage.preview = stage.computeDrop(icon.fileName, icon.cellX + dx + icon.width / 2, icon.cellY + dy + icon.height / 2)
                    }
                    onDropped: function(centerX, centerY) { stage.dropIcon(icon.fileName, centerX, centerY) }
                    onContextRequested: function(x, y) {
                        if (!icon.selected) DesktopFiles.selectOnly(icon.filePath)
                        menu.target = {
                            kind: "icon",
                            path: icon.filePath,
                            name: icon.fileName,
                            isDir: icon.fileIsDir,
                            size: icon.fileSize,
                            modified: icon.fileModified
                        }
                        var p = stage.mapToItem(menu, x, y)
                        menu.openAt(p.x, p.y, DesktopFiles.fileMenu(DesktopFiles.selection.length))
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
                id: band
                visible: backdrop.banding
                color: "#30ffffff"
                border.width: 1
                border.color: "#80ffffff"
                radius: 3
                z: 50
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
                    var overrides = {}
                    for (var i = 0; i < names.length; i++) {
                        var baseCol = Math.min(stage.iconCols - 1, Math.max(0, Math.round((stage.width - stage.iconPad - drop.x) / stage.iconW - 0.5)))
                        var baseRow = Math.min(stage.iconRows - 1, Math.max(0, Math.round((drop.y - stage.iconPad - stage.iconH / 2) / stage.iconH)))
                        var skipNew = {}
                        skipNew[names[i]] = true
                        var spot = stage.nearestFreeCell(skipNew, baseCol, baseRow, taken)
                        taken.push(spot)
                        overrides[names[i]] = spot
                    }
                    stage.commitCells(overrides)
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/plain"]

                function parse(drag) {
                    if (!drag.hasText || drag.text.indexOf("widget:") !== 0) return null
                    var parts = drag.text.split(":")
                    return { type: parts[1], size: parts[2], variant: parts[3] || "", theme: parts[4] || "glass" }
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
                    WidgetState.addWidgetAt("desktop", spec.type, spec.size, spec.variant, dropGuide.gx, dropGuide.gy, spec.theme)
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
