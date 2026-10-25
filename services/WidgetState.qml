pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "widgetState"

    readonly property string filePath: Quickshell.env("HOME") + "/.config/quickshell/core/widgets.json"

    property alias desktop: widgetsAdapter.desktop
    property alias notifCenter: widgetsAdapter.notifCenter
    property alias iconPositions: widgetsAdapter.iconPositions
    property alias desktopSort: widgetsAdapter.desktopSort
    property alias showHidden: widgetsAdapter.showHidden

    property string galleryZone: ""
    property bool typing: false
    property int areaWidth: 1280
    property int areaHeight: 720

    readonly property int cell: 153
    readonly property int gap: 14
    readonly property int step: root.cell + root.gap
    readonly property int desktopOffsetX: 16
    readonly property int desktopOffsetY: 44

    FileView {
        id: widgetsFile
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: widgetsAdapter
            property list<var> desktop: []
            property list<var> notifCenter: [
                { "id": "w_default_weather", "type": "weather", "size": "m", "x": 0, "y": 0 }
            ]
            property list<var> iconPositions: []
            property string desktopSort: "name"
            property bool showHidden: false
        }
    }

    function sizeOf(size) {
        var wide = root.cell * 2 + root.gap
        if (size === "m") return { w: wide, h: root.cell }
        if (size === "l") return { w: wide, h: wide }
        return { w: root.cell, h: root.cell }
    }

    function listOf(zone) {
        return zone === "desktop" ? root.desktop.slice() : root.notifCenter.slice()
    }

    function setList(zone, list) {
        if (zone === "desktop") root.desktop = list
        else root.notifCenter = list
    }

    function indexOfId(list, id) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) return i
        }
        return -1
    }

    function collides(list, skipId, x, y, w, h) {
        for (var i = 0; i < list.length; i++) {
            var o = list[i]
            if (o.id === skipId) continue
            var d = root.sizeOf(o.size)
            if (x < o.x + d.w && x + w > o.x && y < o.y + d.h && y + h > o.y) return true
        }
        return false
    }

    function freeSlot(list, skipId, size) {
        var d = root.sizeOf(size)
        var cols = Math.max(1, Math.floor(root.areaWidth / root.step))
        var rows = Math.max(1, Math.floor(root.areaHeight / root.step))
        for (var c = 0; c < cols; c++) {
            for (var r = 0; r < rows; r++) {
                var x = c * root.step
                var y = r * root.step
                if (x + d.w > root.areaWidth || y + d.h > root.areaHeight) continue
                if (!root.collides(list, skipId, x, y, d.w, d.h)) return { x: x, y: y }
            }
        }
        return { x: 0, y: 0 }
    }

    function addWidget(zone, type, size, variant) {
        var list = root.listOf(zone)
        var entry = { id: "w_" + Date.now(), type: type, variant: variant || "", size: size, x: 0, y: 0 }
        if (zone === "desktop") {
            var p = root.freeSlot(list, "", size)
            entry.x = p.x
            entry.y = p.y
        }
        list.push(entry)
        root.setList(zone, list)
    }

    function snap(size, x, y) {
        var list = root.listOf("desktop")
        var d = root.sizeOf(size)
        var nx = Math.max(0, Math.min(Math.round(x / root.step) * root.step, root.areaWidth - d.w))
        var ny = Math.max(0, Math.min(Math.round(y / root.step) * root.step, root.areaHeight - d.h))
        if (root.collides(list, "", nx, ny, d.w, d.h)) return root.freeSlot(list, "", size)
        return { x: nx, y: ny }
    }

    function addWidgetAt(zone, type, size, variant, x, y) {
        if (zone !== "desktop") {
            root.addWidget(zone, type, size, variant)
            return
        }
        var list = root.listOf("desktop")
        var p = root.snap(size, x, y)
        list.push({ id: "w_" + Date.now(), type: type, variant: variant || "", size: size, x: p.x, y: p.y })
        root.setList("desktop", list)
    }

    function entryOf(zone, id) {
        var list = zone === "desktop" ? root.desktop : root.notifCenter
        var i = root.indexOfId(list, id)
        return i < 0 ? null : list[i]
    }

    function removeWidget(zone, id) {
        root.setList(zone, root.listOf(zone).filter(function(w) { return w.id !== id }))
    }

    function moveWidget(id, x, y) {
        var list = root.listOf("desktop")
        var i = root.indexOfId(list, id)
        if (i < 0) return
        var d = root.sizeOf(list[i].size)
        var nx = Math.round(x / root.step) * root.step
        var ny = Math.round(y / root.step) * root.step
        nx = Math.max(0, Math.min(nx, root.areaWidth - d.w))
        ny = Math.max(0, Math.min(ny, root.areaHeight - d.h))
        if (root.collides(list, id, nx, ny, d.w, d.h)) return
        list[i] = Object.assign({}, list[i], { x: nx, y: ny })
        root.setList("desktop", list)
    }

    function resizeWidget(zone, id, size) {
        var list = root.listOf(zone)
        var i = root.indexOfId(list, id)
        if (i < 0) return
        var next = Object.assign({}, list[i], { size: size })
        if (zone === "desktop") {
            var d = root.sizeOf(size)
            if (next.x + d.w > root.areaWidth || next.y + d.h > root.areaHeight
                    || root.collides(list, id, next.x, next.y, d.w, d.h)) {
                var p = root.freeSlot(list, id, size)
                next.x = p.x
                next.y = p.y
            }
        }
        list[i] = next
        root.setList(zone, list)
    }

    function shiftWidget(zone, id, delta) {
        var list = root.listOf(zone)
        var i = root.indexOfId(list, id)
        var j = i + delta
        if (i < 0 || j < 0 || j >= list.length) return
        var tmp = list[i]
        list[i] = list[j]
        list[j] = tmp
        root.setList(zone, list)
    }

    function openGallery(zone) {
        root.galleryZone = zone
    }

    function closeGallery() {
        root.galleryZone = ""
    }

    function menuEntries(zone, widget) {
        var entries = []
        if (widget) {
            entries.push({ label: "Remove Widget", action: "remove" })
            var sizes = WidgetRegistry.sizesOf(WidgetRegistry.resolve(widget).type, WidgetRegistry.resolve(widget).variant)
            if (sizes.length > 1) {
                for (var i = 0; i < sizes.length; i++) {
                    entries.push({
                        label: (widget.size === sizes[i] ? "✓ " : "    ") + WidgetRegistry.sizeLabels[sizes[i]],
                        action: "size:" + sizes[i]
                    })
                }
            }
            if (zone === "notifCenter") {
                entries.push({ label: "Move Up", action: "up" })
                entries.push({ label: "Move Down", action: "down" })
            }
        }
        entries.push({ label: "Edit Widgets…", action: "edit" })
        return entries
    }

    function applyAction(zone, id, action) {
        if (action === "edit") root.openGallery(zone)
        else if (action === "remove") root.removeWidget(zone, id)
        else if (action === "up") root.shiftWidget(zone, id, -1)
        else if (action === "down") root.shiftWidget(zone, id, 1)
        else if (action.indexOf("size:") === 0) root.resizeWidget(zone, id, action.slice(5))
    }

    function iconPosition(name) {
        for (var i = 0; i < root.iconPositions.length; i++) {
            if (root.iconPositions[i].name === name) return root.iconPositions[i]
        }
        return null
    }

    function setIconPosition(name, x, y) {
        var list = root.iconPositions.filter(function(p) { return p.name !== name })
        list.push({ name: name, x: x, y: y })
        root.iconPositions = list
    }
}
