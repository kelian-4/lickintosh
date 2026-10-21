import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components.glass
import qs.components
import qs.services

Scope {
    id: root

    property bool failed: false
    property string errorString: ""
    property bool dismissing: false

    function dismiss() {
        root.dismissing = true
        _unload.restart()
    }

    Timer {
        id: _unload
        interval: ShellMotion.effects()
        onTriggered: popupLoader.active = false
    }

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            _unload.stop()
            root.dismissing = false
            root.failed = false
            popupLoader.active = false
            popupLoader.active = true
        }

        function onReloadFailed(error) {
            _unload.stop()
            root.dismissing = false
            popupLoader.active = false
            root.failed = true
            root.errorString = error
            popupLoader.active = true
        }
    }

    LazyLoader {
        id: popupLoader

        PanelWindow {
            id: popupWindow
            property bool entered: false
            Component.onCompleted: popupWindow.entered = true

            WlrLayershell.namespace: "quickshell:reload-popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: -1
            color: "transparent"

            anchors {
                top: true
            }
            margins.top: 40

            implicitWidth: _content.implicitWidth + 32
            implicitHeight: _content.implicitHeight + 20

            Timer {
                running: !root.failed
                interval: 2500
                onTriggered: root.dismiss()
            }

            BoxGlass {
                anchors.fill: parent
                opacity: (popupWindow.entered && !root.dismissing) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: ShellMotion.effects(0.7); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                radius: 14
                color: root.failed ? "#30ff4444" : "#18000000"
                light: "#20ffffff"
                rimStrength: 1.0

                RowLayout {
                    id: _content
                    anchors.centerIn: parent
                    spacing: 10

                    CFVI {
                        icon: root.failed ? "notch/alert.svg" : "check.svg"
                        size: 18
                        color: root.failed ? "#FF6B6B" : "#4CD964"
                    }

                    Column {
                        spacing: 2

                        CFText {
                            text: root.failed ? "Erreur de rechargement" : "Shell rechargé"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "#fff"
                        }

                        CFText {
                            text: root.errorString
                            font.pixelSize: 11
                            gray: true
                            visible: root.failed && root.errorString.length > 0
                            wrapMode: Text.WordWrap
                            width: 280
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: root.failed
                onClicked: root.dismiss()
            }
        }
    }
}
