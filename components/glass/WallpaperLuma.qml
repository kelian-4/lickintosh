pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property int cols: 32
    readonly property int rows: {
        var s = Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        return s && s.width > 0 ? Math.max(8, Math.round(root.cols * s.height / s.width)) : 18
    }

    property var grid: []
    property int gridCols: 0
    property int gridRows: 0

    readonly property string source: GlassWallpaper.videoActive ? "" : GlassWallpaper.stillPath
    onSourceChanged: debounce.restart()

    function regionLuma(x, y, w, h, sw, sh) {
        if (root.gridCols <= 0 || root.gridRows <= 0 || root.grid.length !== root.gridCols * root.gridRows || sw <= 0 || sh <= 0)
            return 0
        var c0 = Math.max(0, Math.min(root.gridCols - 1, Math.floor(x / sw * root.gridCols)))
        var c1 = Math.max(c0, Math.min(root.gridCols - 1, Math.floor((x + w) / sw * root.gridCols)))
        var r0 = Math.max(0, Math.min(root.gridRows - 1, Math.floor(y / sh * root.gridRows)))
        var r1 = Math.max(r0, Math.min(root.gridRows - 1, Math.floor((y + h) / sh * root.gridRows)))
        var sum = 0
        var n = 0
        for (var r = r0; r <= r1; r++) {
            for (var c = c0; c <= c1; c++) {
                sum += root.grid[r * root.gridCols + c]
                n++
            }
        }
        return n > 0 ? sum / n : 0
    }

    function darkAmount(x, y, w, h, sw, sh) {
        var opts = ShellConfig.options.appearance
        if (!opts.glassAutoDarken)
            return 0
        var luma = root.regionLuma(x, y, w, h, sw, sh)
        var t = Math.min(0.98, Math.max(0, opts.glassDarkenThreshold))
        var k = Math.max(0, Math.min(1, (luma - t) / (1 - t)))
        return k * Math.max(0, Math.min(1, opts.glassDarkenStrength))
    }

    Timer {
        id: debounce
        interval: 250
        onTriggered: {
            proc.running = false
            if (root.source === "" || root.source.indexOf("itemgrabber") === 0 || root.source.indexOf("image://") === 0) {
                root.grid = []
                return
            }
            proc.command = ["sh", "-c",
                "if command -v magick >/dev/null 2>&1; then c=magick; else c=convert; fi; " +
                "\"$c\" \"$1[0]\" -resize \"$2x$3^\" -gravity center -extent \"$2x$3\" -colorspace Rec709Luma -depth 8 -compress none pgm:- 2>/dev/null",
                "sh", root.source, String(root.cols), String(root.rows)]
            proc.cols = root.cols
            proc.rows = root.rows
            proc.running = true
        }
    }

    Process {
        id: proc
        property int cols: 0
        property int rows: 0
        running: false
        stdout: StdioCollector { id: out }
        onExited: {
            var tokens = String(out.text).trim().split(/\s+/)
            if (tokens.length < 4 + proc.cols * proc.rows || tokens[0] !== "P2") {
                root.grid = []
                return
            }
            var values = []
            for (var i = 4; i < 4 + proc.cols * proc.rows; i++)
                values.push(Number(tokens[i]) / 255)
            root.gridCols = proc.cols
            root.gridRows = proc.rows
            root.grid = values
        }
    }

    Component.onCompleted: debounce.restart()
}
