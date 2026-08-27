import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property bool locked: false

    function lock() {
        root.locked = true
    }

    LockContext {
        id: lockContext
        onUnlocked: root.locked = false
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        WlSessionLockSurface {
            color: "transparent"

            LockSurface {
                id: locksur
                anchors.fill: parent
                context: lockContext

                Connections {
                    target: lockContext
                    function onUnlocking() {
                        locksur.unlock()
                    }
                }

                onUnlockAnimationFinished: lockContext.unlocked()
            }
        }
    }
}
