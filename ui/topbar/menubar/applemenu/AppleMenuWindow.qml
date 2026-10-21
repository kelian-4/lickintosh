import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components

Scope {
    id: root
    property bool opened: false
    signal closeRequested()
    signal openAbout()
    signal lockRequested()

    Presence { id: presence; wanted: root.opened }

    Loader {
        active: presence.present
        sourceComponent: Component {
            PanelWindow {
                id: panel
                property bool entered: false
                Component.onCompleted: panel.entered = true

                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: screen.height
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:applemenu"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    onClicked: root.closeRequested()
                }

                AppleMenu {
                    id: appleMenu
                    x: 12
                    y: 36
                    z: 1
                    opened: root.opened && panel.entered
                    onCloseRequested: root.closeRequested()
                    onOpenAbout: root.openAbout()
                    onLockRequested: root.lockRequested()
                }
            }
        }
    }
}
