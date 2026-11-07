pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components.glass
import qs.services

Scope {
    id: root

    readonly property alias locked: lock.locked

    signal lockRequested
    signal unlockRequested

    property var controlCenter: null
    property bool lockPending: false

    property real lockRequestedAt: 0

    function imageIsSettled(img) {
        return img.status === Image.Ready || img.status === Image.Error
    }

    readonly property bool wallpaperPreloadReady: root.imageIsSettled(wallpaperPreloader) && lockContext.wallpaperCacheAttempted
    readonly property bool avatarPreloadReady: lockContext.avatarDetectionDone
        && (lockContext.avatarUrl.toString().length === 0 || root.imageIsSettled(avatarPreloader))
    readonly property bool readyForLock: wallpaperPreloadReady && avatarPreloadReady

    onReadyForLockChanged: {
        if (root.lockPending && root.readyForLock) {
            root.commitLock()
        }
    }

    function lock() {
        root.lockRequestedAt = Date.now()

        if (lock.locked || root.lockPending) {
            return
        }
        lockContext.checkFprintAvailable()

        if (root.readyForLock) {
            root.commitLock()
        } else {
            root.lockPending = true
            lockTimeoutTimer.restart()
        }
    }

    function commitLock() {
        root.lockPending = false
        lockTimeoutTimer.stop()
        lock.locked = true
    }

    Timer {
        id: lockTimeoutTimer

        interval: 1500
        onTriggered: {
            if (root.lockPending) {
                root.commitLock()
            }
        }
    }

    LockContext {
        id: lockContext

        onUnlocking: unlockCloseTimer.restart()
        onUnlocked: {
            lock.locked = false
        }
    }

    readonly property var primaryScreen: Quickshell.screens[0] ?? null

    onPrimaryScreenChanged: {
        if (root.primaryScreen) {
            lockContext.setWallpaperTargetSize(root.primaryScreen.width, root.primaryScreen.height)
        }
    }
    Component.onCompleted: {
        if (root.primaryScreen) {
            lockContext.setWallpaperTargetSize(root.primaryScreen.width, root.primaryScreen.height)
        }
    }

    Image {
        id: wallpaperPreloader
        visible: false
        asynchronous: true
        cache: true
        source: lockContext.wallpaperSource
        sourceSize: root.primaryScreen
            ? Qt.size(root.primaryScreen.width * (root.primaryScreen.devicePixelRatio ?? 1),
                       root.primaryScreen.height * (root.primaryScreen.devicePixelRatio ?? 1))
            : undefined
    }

    Image {
        id: avatarPreloader
        visible: false
        asynchronous: true
        cache: true
        source: lockContext.avatarUrl
        sourceSize: root.primaryScreen
            ? Qt.size(56 * (root.primaryScreen.devicePixelRatio ?? 1), 56 * (root.primaryScreen.devicePixelRatio ?? 1))
            : undefined
    }

    Timer {
        id: unlockCloseTimer
        interval: lockContext.unlockAnimDuration
        onTriggered: lockContext.unlocked()
    }

    Binding {
        target: GlassTracker
        property: "sessionLocked"
        value: lock.locked
    }

    WlSessionLock {
        id: lock

        onLockedChanged: {
            if (locked) {
                root.lockRequested()
            } else {
                lockContext.reset()
                root.unlockRequested()
            }
        }

        LockSurface {
            lock: lock
            context: lockContext
            controlCenter: root.controlCenter
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock()
        }

        function isLocked(): bool {
            return lock.locked
        }
    }

    GlobalShortcut {
        appid: "lickintosh"
        name: "lock"
        description: I18n.tr("Verrouille la session")
        onPressed: root.lock()
    }
}
