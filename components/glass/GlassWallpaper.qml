pragma Singleton
import Quickshell
import qs.services

Singleton {
    property string preview: ""
    readonly property string path: preview !== "" ? preview
        : (Theme.isDark && ShellConfig.options.wallpaper.pathDark !== "" ? ShellConfig.options.wallpaper.pathDark : ShellConfig.options.wallpaper.path)
}
