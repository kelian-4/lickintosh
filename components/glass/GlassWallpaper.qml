pragma Singleton
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

    readonly property bool videoActive: preview === "" && ShellConfig.options.wallpaper.videoPath !== "" && modePath === ""

    readonly property string basePath: ShellConfig.options.wallpaper.path

    readonly property string stillPath: {
        if (preview !== "") return preview
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

    readonly property string path: videoActive && videoUrl !== ""
        ? videoUrl : stillPath

    function sourceUrl(p) {
        if (p === "") return ""
        return (p.indexOf("image://") === 0 || p.indexOf("itemgrabber") === 0) ? p : "file://" + p
    }
}
