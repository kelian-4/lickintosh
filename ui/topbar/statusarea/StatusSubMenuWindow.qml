import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components.glass
import qs.components
import qs.services

Scope {
    id: root
    property bool opened: false
    property alias contentComponent: loader.sourceComponent
    property int xPos: 0
    property bool needsKeyboard: false
    signal closeRequested()

    Presence { id: presence; wanted: root.opened }

    Loader {
        id: loader
        active: presence.present
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
        active: presence.present
        sourceComponent: Component {
            PanelWindow {
                id: panel
                property bool entered: false
                Component.onCompleted: panel.entered = true

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
                    opacity:         (root.opened && panel.entered) ? 1 : 0
                    scale:           (root.opened && panel.entered) ? 1 : 0.95
                    transformOrigin: Item.Top
                    Behavior on opacity { NumberAnimation { duration: ShellMotion.effects(0.7); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                    Behavior on scale { NumberAnimation { duration: ShellMotion.effects(0.7); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

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
