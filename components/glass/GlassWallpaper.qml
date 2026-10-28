pragma Singleton
import Quickshell
import qs.services

Singleton {
    property string preview: ""
    readonly property string path: preview !== "" ? preview : ShellConfig.options.wallpaper.path
}
