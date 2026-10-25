pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    reloadableId: "desktopFiles"

    property string dir: Quickshell.env("HOME") + "/Desktop"
    property alias model: folderModel
    property string selected: ""
    property string renaming: ""
    property var infoTarget: null

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
        showHidden: WidgetState.showHidden
        showDotAndDotDot: false
        sortField: root.sortFieldFor(WidgetState.desktopSort)
        sortReversed: WidgetState.desktopSort === "date" || WidgetState.desktopSort === "size"
    }

    function sortFieldFor(key) {
        if (key === "kind") return FolderListModel.Type
        if (key === "date") return FolderListModel.Time
        if (key === "size") return FolderListModel.Size
        return FolderListModel.Name
    }

    function run(script, args) {
        Quickshell.execDetached(["sh", "-c", script, "sh"].concat(args))
    }

    function isImage(name) {
        return /\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(name)
    }

    function extensionOf(name) {
        return name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
    }

    function entryFor(name) {
        if (!name.endsWith(".desktop")) return null
        return DesktopEntries.byId(name.slice(0, -8))
    }

    // First name of `names` that exists in the icon theme, or the theme's
    // "missing" icon when none does. Avoids the missing-texture checkerboard
    // when a theme lacks the generic file icons (MacTahoe-dark ships only the
    // symbolic ones unless the base MacTahoe theme is installed next to it).
    function firstThemeIcon(names) {
        for (var i = 0; i < names.length; i++) {
            if (!names[i]) continue
            var p = Quickshell.iconPath(names[i], true)
            if (p !== "") return p
        }
        return Quickshell.iconPath("image-missing")
    }

    // Icon hints for the files of the desktop, filled by one shell pass over
    // the directory: { "<file name>": { kind: "icon" | "mime", value } }.
    //  - "icon": the Icon= value of a .desktop file. Launchers saved on the
    //    desktop (Bottles, ...) are not registered applications, so
    //    DesktopEntries does not know them.
    //  - "mime": the mime type of any other file, to pick a specific icon
    //    (package, script, ...) instead of the generic document.
    property var fileHints: ({})

    function scanHints() {
        hintDebounce.restart()
    }

    Timer {
        id: hintDebounce
        interval: 300
        onTriggered: hintScan.running = true
    }

    Process {
        id: hintScan
        running: true
        command: ["sh", "-c",
            'for f in "$1"/* "$1"/.[!.]*; do [ -f "$f" ] || continue; n=${f##*/}; ' +
            'case "$n" in *.desktop) k=icon; v=$(sed -n "s/^Icon=//p" "$f" | head -n 1);; ' +
            '*) k=mime; v=$(xdg-mime query filetype "$f" 2>/dev/null);; esac; ' +
            'printf "%s\\t%s\\t%s\\n" "$n" "$k" "$v"; done',
            "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                var hints = {}
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t")
                    if (parts.length >= 3 && parts[2].trim() !== "")
                        hints[parts[0]] = { kind: parts[1], value: parts[2].trim() }
                }
                root.fileHints = hints
            }
        }
    }

    onDirChanged: root.scanHints()

    Connections {
        target: folderModel
        function onCountChanged() { root.scanHints() }
    }

    // Icon naming spec: "image/png" -> "image-png", then "<media>-x-generic".
    function mimeIconNames(mime) {
        return [mime.replace("/", "-"), mime.split("/")[0] + "-x-generic"]
    }

    function iconPathFor(name, isDir) {
        if (isDir) return Quickshell.iconPath("folder", "inode-directory")
        var hint = root.fileHints[name]
        var names = []
        var entry = root.entryFor(name)
        if (entry && entry.icon !== "") names.push(entry.icon)
        if (hint && hint.kind === "icon") names.push(hint.value)
        if (names.length > 0)
            return root.firstThemeIcon(names.concat(["application-x-executable", "application-x-executable-symbolic", "unknown"]))
        if (hint && hint.kind === "mime") names = root.mimeIconNames(hint.value)
        return root.firstThemeIcon(names.concat(["text-x-generic", "text-x-generic-symbolic", "application-x-executable", "unknown"]))
    }

    function labelFor(name) {
        if (!name.endsWith(".desktop")) return name
        var entry = root.entryFor(name)
        return entry ? entry.name : name.slice(0, -8)
    }

    function kindFor(name, isDir) {
        if (isDir) return "Folder"
        if (name.endsWith(".desktop")) return "Application"
        var ext = root.extensionOf(name)
        return ext === "" ? "Document" : ext.toUpperCase() + " file"
    }

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + " B"
        var units = ["KB", "MB", "GB", "TB"]
        var value = bytes / 1024
        var i = 0
        while (value >= 1024 && i < units.length - 1) {
            value /= 1024
            i++
        }
        return value.toFixed(value < 10 ? 1 : 0) + " " + units[i]
    }

    function open(path, name) {
        var entry = root.entryFor(name)
        if (entry) {
            entry.execute()
            return
        }
        Quickshell.execDetached(["xdg-open", path])
    }

    function newFolder() {
        root.run('d="$1/untitled folder"; n=2; while [ -e "$d" ]; do d="$1/untitled folder $n"; n=$((n+1)); done; mkdir -- "$d"', [root.dir])
    }

    function newFile() {
        root.run('d="$1/untitled file"; n=2; while [ -e "$d" ]; do d="$1/untitled file $n"; n=$((n+1)); done; : > "$d"', [root.dir])
    }

    function duplicate(path) {
        root.run('d="$1 copy"; n=2; while [ -e "$d" ]; do d="$1 copy $n"; n=$((n+1)); done; cp -a -- "$1" "$d"', [path])
    }

    function compress(path) {
        root.run('cd "$(dirname "$1")" && tar -czf "$(basename "$1").tar.gz" -- "$(basename "$1")"', [path])
    }

    function trash(path) {
        root.run('gio trash -- "$1" || trash-put -- "$1"', [path])
    }

    function copyPath(path) {
        Quickshell.execDetached(["wl-copy", path])
    }

    function reveal(path) {
        Quickshell.execDetached(["xdg-open", path.slice(0, path.lastIndexOf("/"))])
    }

    function rename(path, newName) {
        var name = newName.trim()
        if (name === "" || name.indexOf("/") >= 0) return
        root.run('mv -n -- "$1" "$2"', [path, path.slice(0, path.lastIndexOf("/") + 1) + name])
    }

    function cleanUp() {
        WidgetState.iconPositions = []
    }

    function setSort(key) {
        WidgetState.desktopSort = key
        root.cleanUp()
    }

    function openSettings() {
        Quickshell.execDetached(["quickshell", "-p", Quickshell.shellDir + "/settings.qml"])
    }

    function desktopMenu() {
        var s = WidgetState.desktopSort
        return [
            { label: "New Folder", action: "new-folder" },
            { label: "New File", action: "new-file" },
            { separator: true },
            { label: "Change Wallpaper…", action: "wallpaper" },
            { separator: true },
            { label: "Sort By", children: [
                { label: "Name", action: "sort:name", checkable: true, checked: s === "name" },
                { label: "Kind", action: "sort:kind", checkable: true, checked: s === "kind" },
                { label: "Date Modified", action: "sort:date", checkable: true, checked: s === "date" },
                { label: "Size", action: "sort:size", checkable: true, checked: s === "size" }
            ] },
            { label: "Clean Up", action: "cleanup" },
            { label: "Show Hidden Files", action: "hidden", checkable: true, checked: WidgetState.showHidden },
            { separator: true },
            { label: "Edit Widgets…", action: "edit" }
        ]
    }

    function fileMenu() {
        return [
            { label: "Open", action: "open" },
            { label: "Show in File Manager", action: "reveal" },
            { separator: true },
            { label: "Rename", action: "rename" },
            { label: "Duplicate", action: "duplicate" },
            { label: "Compress", action: "compress" },
            { label: "Get Info", action: "info" },
            { separator: true },
            { label: "Copy Path", action: "copy-path" },
            { separator: true },
            { label: "Move to Trash", action: "trash", danger: true }
        ]
    }

    function handle(action, target) {
        if (action === "new-folder") root.newFolder()
        else if (action === "new-file") root.newFile()
        else if (action === "wallpaper") root.openSettings()
        else if (action === "cleanup") root.cleanUp()
        else if (action === "hidden") WidgetState.showHidden = !WidgetState.showHidden
        else if (action === "edit") WidgetState.openGallery("desktop")
        else if (action.indexOf("sort:") === 0) root.setSort(action.slice(5))
        else if (action === "open") root.open(target.path, target.name)
        else if (action === "reveal") root.reveal(target.path)
        else if (action === "rename") root.renaming = target.path
        else if (action === "duplicate") root.duplicate(target.path)
        else if (action === "compress") root.compress(target.path)
        else if (action === "info") root.infoTarget = target
        else if (action === "copy-path") root.copyPath(target.path)
        else if (action === "trash") root.trash(target.path)
    }
}
