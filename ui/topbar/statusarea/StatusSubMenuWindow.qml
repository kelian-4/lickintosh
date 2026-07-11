import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.ui.glass

Scope {
    id: root
    property bool opened: false
    property alias contentComponent: loader.sourceComponent
    property int xPos: 0
    property bool needsKeyboard: false
    signal closeRequested()

    Loader {
        id: loader
        active: root.opened
        sourceComponent: null
        onLoaded: {
            if (item) {
                item.closeRequested.connect(root.closeRequested)
                if (item.hasOwnProperty("needsKeyboard")) {
                    root.needsKeyboard = Qt.binding(function() { return item.needsKeyboard })
                }
            }
        }
        onItemChanged: {
            if (!item) root.needsKeyboard = false
        }
    }

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                anchors {
                    top:   true
                    left:  true
                    right: true
                }
                implicitHeight: screen.height
                color:          "transparent"
                exclusiveZone:  -1

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.namespace:     "quickshell:statusmenu"
                WlrLayershell.keyboardFocus: root.needsKeyboard
                                             ? WlrKeyboardFocus.OnDemand
                                             : WlrKeyboardFocus.None

                MouseArea {
                    anchors.fill: parent
                    z:            0
                    onClicked:    root.closeRequested()
                }

                BoxGlass {
                    id: menuContainer
                    x:      Math.min(Math.max(root.xPos - 20, 10), screen.width - width - 10)
                    y:      36
                    width:  320
                    height: loader.item ? loader.item.implicitHeight : 0
                    z:      1
                    radius:      12
                    color:       Qt.rgba(0.08, 0.08, 0.08, 0.75)
                    rimStrength: 1.7
                    light:       "#20ffffff"

                    Binding {
                        target:   loader.item
                        property: "parent"
                        value:    menuContainer
                    }
                    Binding {
                        target:   loader.item
                        property: "width"
                        value:    menuContainer.width
                    }
                }
            }
        }
    }
}
