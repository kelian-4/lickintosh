pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "iconResolver"

    readonly property var imageExtensions: ({
        png: true, jpg: true, jpeg: true, jfif: true, gif: true, bmp: true,
        webp: true, avif: true, heic: true, heif: true, tiff: true, tif: true,
        ico: true, svg: true, svgz: true, psd: true, xcf: true, kra: true, ora: true
    })

    function extensionOf(name) {
        return name.indexOf(".") > 0 ? name.split(".").pop().toLowerCase() : ""
    }

    function isImageFile(name) {
        return root.imageExtensions[root.extensionOf(name)] === true
    }

    function fileIconName(name) {
        var ext = root.extensionOf(name)
        if (ext === "pdf") return "application-pdf"
        if (root.imageExtensions[ext] === true) return "image-x-generic"
        if (ext === "mp4" || ext === "mkv") return "video-x-generic"
        if (ext === "mp3" || ext === "flac") return "audio-x-generic"
        return "text-x-generic"
    }

    function byName(name) {
        return name ? Quickshell.iconPath(name, true) : ""
    }

    function forApp(entry) {
        return entry && entry.icon ? root.byName(entry.icon) : ""
    }

    function forAppId(appId) {
        return appId ? root.forApp(DesktopEntries.heuristicLookup(appId)) : ""
    }

    function forFile(name) {
        return root.byName(root.fileIconName(name))
    }

    function forFolder() {
        var path = root.byName("folder")
        return path !== "" ? path : root.byName("inode-directory")
    }

    function generic() {
        var names = ["application-x-executable", "application-x-executable-symbolic", "unknown"]
        for (var i = 0; i < names.length; i++) {
            var path = root.byName(names[i])
            if (path !== "") return path
        }
        return Quickshell.iconPath("image-missing")
    }

    function resolve(source) {
        if (!source) return ""
        if (source.indexOf("file://") === 0 || source.indexOf("image://") === 0) return source
        if (source.charAt(0) === "/") return "file://" + source
        return root.byName(source)
    }
}
