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

    property bool gateEnabled: true
    property int gateTimeout: 400
    property bool revealed: !gateEnabled
    readonly property bool glassReady: ready && captureSettled

    instantReveal: gateEnabled

    onGlassReadyChanged: {
        if (glassReady)
            revealed = true
    }

    onWinChanged: {
        if (win)
            GlassRegistry.register(win, root)
    }
    Component.onCompleted: {
        if (win)
            GlassRegistry.register(win, root)
        if (glassReady)
            revealed = true
    }

    Timer {
        interval: root.gateTimeout
        running: root.gateEnabled && !root.revealed
        onTriggered: root.revealed = true
    }

    Binding {
        target: root.win ? root.win.contentItem : null
        property: "opacity"
        value: root.revealed ? 1 : 0
        when: root.gateEnabled && root.win !== null && root.win !== undefined
    }
    Component.onDestruction: GlassRegistry.unregister(root)

    wallpaperPath: GlassWallpaper.path
    screenSize: scr ? Qt.size(scr.width, scr.height) : Qt.size(1, 1)
    monitorName: scr ? scr.name : ""
    windowPosition: computePosition()
    captureWindows: ShellConfig.options.glass.captureWindows
    windowOpacity: ShellConfig.options.glass.windowOpacity
    windowOpacityByClass: ShellConfig.options.glass.windowOpacityByClass
    blurRadius: 1.0
}
