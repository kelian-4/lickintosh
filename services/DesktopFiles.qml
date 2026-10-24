pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "desktopFiles"

    property string dir: Quickshell.env("HOME") + "/Desktop"
    property alias model: folderModel
    property string selected: ""

    Process {
        running: true
        command: ["xdg-user-dir", "DESKTOP"]
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim()
                if (path !== "" && path !== Quickshell.env("HOME")) root.dir = path
            }
        }
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.dir
        showDirs: true
        showDirsFirst: true
        showHidden: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    function isImage(name) {
        return /\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(name)
    }

    function entryFor(name) {
        if (!name.endsWith(".desktop")) return null
        return DesktopEntries.byId(name.slice(0, -8))
    }

    function iconPathFor(name, isDir) {
        if (isDir) return Quickshell.iconPath("folder", "inode-directory")
        var entry = root.entryFor(name)
        if (entry && entry.icon !== "") return Quickshell.iconPath(entry.icon, "application-x-executable")
        return Quickshell.iconPath("text-x-generic", "application-x-executable")
    }

    function labelFor(name) {
        if (!name.endsWith(".desktop")) return name
        var entry = root.entryFor(name)
        return entry ? entry.name : name.slice(0, -8)
    }

    function open(path, name) {
        var entry = root.entryFor(name)
        if (entry) {
            entry.execute()
            return
        }
        Quickshell.execDetached(["xdg-open", path])
    }
}
