pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    property string preview: ""
    property string videoUrl: ""
    property var videoGrab: null

    function pairOf(p, kind) {
        var m = /^(.*macOS Tahoe 26 )(Light|Dark)( Wallpaper\.[a-z]+)$/.exec(p)
        return m ? m[1] + kind + m[3] : p
    }

    readonly property string modePath: Theme.isDark ? ShellConfig.options.wallpaper.pathDark
        : (Theme.isLight ? ShellConfig.options.wallpaper.pathLight : "")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string hourlyPath: {
        if (!ShellConfig.options.wallpaper.hourlyEnabled) return ""
        var hour = clock.hours
        for (var k = 0; k < 24; k++) {
            var p = ShellConfig.options.wallpaper.hourly["h" + ((hour - k + 24) % 24)]
            if (p !== "") return p
        }
        return ""
    }

    readonly property bool videoActive: preview === "" && ShellConfig.options.wallpaper.videoPath !== "" && modePath === "" && hourlyPath === ""

    readonly property string basePath: ShellConfig.options.wallpaper.path

    readonly property string stillPath: {
        if (preview !== "") return preview
        if (hourlyPath !== "") return hourlyPath
        if (Theme.isDark) {
            var dark = ShellConfig.options.wallpaper.pathDark
            return dark !== "" ? dark : pairOf(basePath, "Dark")
        }
        if (Theme.isLight) {
            var light = ShellConfig.options.wallpaper.pathLight
            return light !== "" ? light : pairOf(basePath, "Light")
        }
        return basePath
    }

    property string settled: ""

    readonly property string path: videoActive && videoUrl !== ""
        ? videoUrl : (settled !== "" ? settled : stillPath)

    function settle(p) {
        if (p !== stillPath) return
        settleTimer.stop()
        settled = p
    }

    onStillPathChanged: if (settled !== "" && settled !== stillPath) settleTimer.restart()

    Timer {
        id: settleTimer
        interval: 2000
        onTriggered: GlassWallpaper.settled = GlassWallpaper.stillPath
    }

    function sourceUrl(p) {
        if (p === "") return ""
        return (p.indexOf("image://") === 0 || p.indexOf("itemgrabber") === 0) ? p : "file://" + p
    }
}
