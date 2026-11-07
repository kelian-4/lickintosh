pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services

Scope {
    id: root

    signal unlocked
    signal unlocking
    signal failed

    readonly property int unlockAnimDuration: 320

    function toFileUrl(path) {
        return Qt.url("file://" + encodeURI(path))
    }

    readonly property string wallpaperRawPath: {
        const configured = ShellConfig.options.wallpaper.lockscreenPath
        if (configured.length > 0) return configured
        return Quickshell.shellDir + "/assets/wallpapers/macOS Tahoe 26 Dark Wallpaper.png"
    }

    readonly property string wallpaperCacheDir: (Quickshell.env("HOME") || "") + "/.cache/quickshell/lockscreen-wallpaper"

    property int wallpaperTargetWidth: 0
    property int wallpaperTargetHeight: 0

    function setWallpaperTargetSize(w, h) {
        const iw = Math.round(w)
        const ih = Math.round(h)
        if (iw === root.wallpaperTargetWidth && ih === root.wallpaperTargetHeight) return
        root.wallpaperTargetWidth = iw
        root.wallpaperTargetHeight = ih
    }

    function simpleHash(str) {
        let h = 0
        for (let i = 0; i < str.length; i++) {
            h = ((h << 5) - h + str.charCodeAt(i)) | 0
        }
        return (h >>> 0).toString(16)
    }

    readonly property string wallpaperCacheFileName: root.wallpaperTargetWidth > 0
        ? root.simpleHash(root.wallpaperRawPath + "|" + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight) + ".png"
        : ""
    readonly property string wallpaperCachePath: root.wallpaperCacheFileName.length > 0
        ? root.wallpaperCacheDir + "/" + root.wallpaperCacheFileName
        : ""

    property bool wallpaperCacheReady: false

    property bool wallpaperCacheAttempted: false

    property string wallpaperCacheMtime: ""

    onWallpaperCachePathChanged: {
        root.wallpaperCacheReady = false
        root.wallpaperCacheAttempted = false
        root.triggerWallpaperCache()
    }

    function triggerWallpaperCache() {
        if (root.wallpaperCachePath.length === 0) return

        Qt.callLater(root.startWallpaperCheck)
    }

    function startWallpaperCheck() {
        if (root.wallpaperCachePath.length === 0) return
        wallpaperCacheCheckProc.running = true
    }

    Process {
        id: wallpaperCacheCheckProc
        command: ["sh", "-c",
            "mkdir -p '" + root.wallpaperCacheDir.replace(/'/g, "'\\''") + "'; " +
            "F='" + root.wallpaperCachePath.replace(/'/g, "'\\''") + "'; " +
            "echo \"$F\"; if [ -f \"$F\" ]; then echo exists; stat -c %Y \"$F\"; else echo missing; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const checkedPath = lines[0]
                const state = lines.length > 1 ? lines[1] : ""
                if (checkedPath !== root.wallpaperCachePath) {
                    Qt.callLater(root.startWallpaperCheck)
                    return
                }
                if (state === "exists") {
                    root.wallpaperCacheMtime = lines.length > 2 ? lines[2] : ""
                    root.wallpaperCacheReady = true
                    root.wallpaperCacheAttempted = true
                } else {
                    wallpaperConvertProc.running = true
                }
            }
        }
    }

    Process {
        id: wallpaperConvertProc
        command: ["sh", "-c",
            "SRC=" + JSON.stringify(root.wallpaperRawPath) + "; " +
            "DST=" + JSON.stringify(root.wallpaperCachePath) + "; " +
            "echo \"$DST\"; " +
            "TMP=\"$DST.tmp.$$\"; " +
            "if command -v magick >/dev/null 2>&1; then " +
            "  magick \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "elif command -v convert >/dev/null 2>&1; then " +
            "  convert \"$SRC\" -resize " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + "^ -gravity center -extent " + root.wallpaperTargetWidth + "x" + root.wallpaperTargetHeight + " \"$TMP\" && mv \"$TMP\" \"$DST\"; " +
            "else " +
            "  echo 'NO_IMAGEMAGICK' >&2; exit 42; " +
            "fi; " +
            "[ -f \"$DST\" ] && stat -c %Y \"$DST\""]
        stdout: StdioCollector { id: wallpaperConvertOut }
        onExited: code => {
            const out = wallpaperConvertOut.text.trim().split("\n")
            const convertedPath = out[0]

            if (convertedPath !== root.wallpaperCachePath) {
                return
            }

            if (code === 0) {
                root.wallpaperCacheMtime = out.length > 1 ? out[1] : ""
            }
            root.wallpaperCacheReady = (code === 0)
            root.wallpaperCacheAttempted = true
        }
    }

    readonly property url wallpaperSource: root.wallpaperCacheReady && root.wallpaperCachePath.length > 0
        ? Qt.url(root.toFileUrl(root.wallpaperCachePath) + (root.wallpaperCacheMtime.length > 0 ? "#" + root.wallpaperCacheMtime : ""))
        : root.toFileUrl(root.wallpaperRawPath)

    property string avatarSource: ""
    readonly property url avatarUrl: root.avatarSource.length > 0 ? root.toFileUrl(root.avatarSource) : ""

    property bool avatarDetectionDone: false

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _user: Quickshell.env("USER") || ""

    Component.onCompleted: {
        if (root._home.length === 0) root.avatarDetectionDone = true
    }

    Process {
        id: avatarDetectProc
        running: root._home.length > 0
        command: ["sh", "-c",
            "for f in " +
            "\"" + root._home + "/.face\" " +
            "\"" + root._home + "/.face.icon\" " +
            "\"/var/lib/AccountsService/icons/" + root._user + "\"" +
            "; do [ -r \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length > 0) root.avatarSource = path
                root.avatarDetectionDone = true
            }
        }
    }

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    property string lockMessage: ""

    property int failCount: 0

    property bool fprintEnabled: true
    readonly property int fprintMaxTries: 3

    property bool fprintAvailable: false
    readonly property bool fprintActive: fprint.active
    property int fprintTries: 0
    readonly property bool fprintCanAttempt: root.fprintEnabled
        && root.fprintAvailable
        && root.fprintTries < root.fprintMaxTries
        && !root.unlockInProgress

    function updateText(text) {
        root.currentText = text
        root.showFailure = false
        if (text.length > 0) root.abortFprint()
    }

    function tryUnlock() {
        if (root.unlockInProgress) return
        if (root.currentText.length === 0) return

        root.abortFprint()
        root.unlockInProgress = true
        pam.start()
    }

    function checkFprintAvailable() {
        if (!root.fprintEnabled) return
        fprintAvailProc.running = true
    }

    function startFprint() {
        if (!root.fprintCanAttempt) return
        if (fprint.active) return
        fprint.start()
    }

    function abortFprint() {
        if (fprint.active) fprint.abort()
    }

    function reset() {
        pam.abort()
        root.abortFprint()
        root.currentText = ""
        root.showFailure = false
        root.unlockInProgress = false
        root.lockMessage = ""
        root.fprintTries = 0
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellDir + "/ui/lockscreen/pam.d"
        config: "lickintosh-lock"

        onMessageChanged: {
            if (message.length > 0) root.lockMessage = message
        }

        onResponseRequiredChanged: {
            if (!responseRequired) return
            respond(root.currentText)
        }

        onCompleted: result => {
            root.unlockInProgress = false

            if (result === PamResult.Success) {
                root.failCount = 0
                root.currentText = ""
                root.lockMessage = ""
                root.unlocking()
                return
            }

            root.failCount += 1
            root.showFailure = true
            root.currentText = ""
            root.failed()
        }
    }

    Process {
        id: fprintAvailProc
        command: ["sh", "-c", "fprintd-list \"$USER\""]
        onExited: code => {
            root.fprintAvailable = (code === 0)
            if (root.fprintAvailable) root.startFprint()
        }
    }

    PamContext {
        id: fprint

        configDirectory: Quickshell.shellDir + "/ui/lockscreen/pam.d"
        config: "lickintosh-lock-fprint"

        onResponseRequiredChanged: {
            if (responseRequired) respond("")
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.fprintTries = 0
                root.unlocking()
                return
            }

            root.fprintTries += 1
            if (root.fprintCanAttempt) {
                fprintRetryTimer.restart()
            }
        }
    }

    Timer {
        id: fprintRetryTimer
        interval: 600
        onTriggered: root.startFprint()
    }
}
