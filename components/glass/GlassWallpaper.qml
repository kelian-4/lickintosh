pragma Singleton
import Quickshell
import qs.services

Singleton {
    property string preview: ""
    property string videoUrl: ""
    property var videoGrab: null

    readonly property string stillPath: preview !== "" ? preview
        : (Theme.isDark && ShellConfig.options.wallpaper.pathDark !== "" ? ShellConfig.options.wallpaper.pathDark : ShellConfig.options.wallpaper.path)

    readonly property string path: preview === "" && ShellConfig.options.wallpaper.videoPath !== "" && videoUrl !== ""
        ? videoUrl : stillPath

    function sourceUrl(p) {
        if (p === "") return ""
        return (p.indexOf("image://") === 0 || p.indexOf("itemgrabber") === 0) ? p : "file://" + p
    }
}
