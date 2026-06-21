import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool opened: false
    signal closeRequested()
    signal openAbout()

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
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
                    opened: root.opened
                    onCloseRequested: root.closeRequested()
                    onOpenAbout: root.openAbout()
                }
            }
        }
    }
}