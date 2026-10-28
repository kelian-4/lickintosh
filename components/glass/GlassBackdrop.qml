import QtQuick
import Quickshell
import qs.services

LiquidGlassBackdrop {
    id: root

    readonly property var win: QsWindow.window
    readonly property var scr: win ? win.screen : null

    function computePosition() {
        if (!win)
            return Qt.point(0, 0)
        var a = win.anchors
        var m = win.margins
        var sw = screenSize.width
        var sh = screenSize.height
        var x = a.left ? m.left : (a.right ? sw - win.width - m.right : (sw - win.width) / 2)
        var y = a.top ? m.top : (a.bottom ? sh - win.height - m.bottom : (sh - win.height) / 2)
        return Qt.point(x, y)
    }

    onWinChanged: {
        if (win)
            GlassRegistry.register(win, root)
    }
    Component.onCompleted: {
        if (win)
            GlassRegistry.register(win, root)
    }
    Component.onDestruction: GlassRegistry.unregister(root)

    wallpaperPath: GlassWallpaper.path
    screenSize: scr ? Qt.size(scr.width, scr.height) : Qt.size(1, 1)
    monitorName: scr ? scr.name : ""
    windowPosition: computePosition()
    captureWindows: ShellConfig.options.glass.captureWindows
    windowOpacity: ShellConfig.options.glass.windowOpacity
    blurRadius: 1.0
}
