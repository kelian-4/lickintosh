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

            readonly property int iconW: 96
            readonly property int iconH: 104
            readonly property int iconRows: Math.max(1, Math.floor(stage.height / stage.iconH))
            readonly property int iconCols: Math.max(1, Math.floor(stage.width / stage.iconW))
            readonly property real gridX: stage.width - stage.iconCols * stage.iconW
            readonly property var iconCells: stage.computeCells(DesktopFiles.model.count, WidgetState.iconPositions, stage.iconRows, stage.iconCols)

            function cellOf(x, y) {
                return {
                    col: Math.max(0, Math.min(stage.iconCols - 1, Math.round((x - stage.gridX) / stage.iconW))),
                    row: Math.max(0, Math.min(stage.iconRows - 1, Math.round(y / stage.iconH)))
                }
            }

            function computeCells(count, saved, rows, cols) {
                var names = []
                for (var i = 0; i < count; i++) names.push(DesktopFiles.model.get(i, "fileName"))
                var cells = {}
                var occupied = {}
                names.forEach(function(name) {
                    for (var j = 0; j < saved.length; j++) {
                        if (saved[j].name !== name) continue
                        var cell = stage.cellOf(saved[j].x, saved[j].y)
                        if (!occupied[cell.col + "," + cell.row]) {
                            occupied[cell.col + "," + cell.row] = true
                            cells[name] = cell
                        }
                        return
                    }
                })
                var col = cols - 1
                var row = 0
                names.forEach(function(name) {
                    if (cells[name]) return
                    while (col > 0 && occupied[col + "," + row]) {
                        row++
                        if (row >= rows) {
                            row = 0
                            col--
                        }
                    }
                    occupied[col + "," + row] = true
                    cells[name] = { col: col, row: row }
                })
                return cells
            }

            function nearestFreeCell(name, col, row, extra) {
                var occupied = {}
                for (var other in stage.iconCells) {
                    if (other === name) continue
                    occupied[stage.iconCells[other].col + "," + stage.iconCells[other].row] = true
                }
                for (var k = 0; k < extra.length; k++) occupied[extra[k].col + "," + extra[k].row] = true
                var best = { col: col, row: row }
                var bestDist = 1e9
                for (var c = 0; c < stage.iconCols; c++) {
                    for (var r = 0; r < stage.iconRows; r++) {
                        if (occupied[c + "," + r]) continue
                        var dist = (c - col) * (c - col) + (r - row) * (r - row)
                        if (dist < bestDist) {
                            bestDist = dist
                            best = { col: c, row: r }
                        }
                    }
                }
                return best
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

                delegate: Item {
                    id: iconSlot

                    required property int index
                    required property string fileName
                    required property string filePath
                    required property bool fileIsDir
                    required property var fileSize
                    required property var fileModified

                    readonly property var cell: stage.iconCells[iconSlot.fileName]

                    property bool dragging: false
                    property real dragDX: 0
                    property real dragDY: 0

                    x: stage.gridX + (iconSlot.cell ? iconSlot.cell.col * stage.iconW : 0) + iconSlot.dragDX
                    y: (iconSlot.cell ? iconSlot.cell.row * stage.iconH : 0) + iconSlot.dragDY
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
                                var target = stage.cellOf(iconSlot.x, iconSlot.y)
                                var spot = stage.nearestFreeCell(iconSlot.fileName, target.col, target.row, [])
                                iconSlot.dragging = false
                                iconSlot.dragDX = 0
                                iconSlot.dragDY = 0
                                WidgetState.setIconPosition(iconSlot.fileName, stage.gridX + spot.col * stage.iconW, spot.row * stage.iconH)
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
                        var base = stage.cellOf(drop.x - stage.iconW / 2, drop.y - stage.iconH / 2)
                        var spot = stage.nearestFreeCell(names[i], base.col, base.row, taken)
                        taken.push(spot)
                        WidgetState.setIconPosition(names[i], stage.gridX + spot.col * stage.iconW, spot.row * stage.iconH)
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
