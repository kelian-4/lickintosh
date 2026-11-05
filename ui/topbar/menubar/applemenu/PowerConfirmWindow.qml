import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import qs.components.glass
import qs.components
import qs.services

Scope {
    id: root

    property string action: ""
    readonly property bool opened: root.action !== ""
    signal confirmed(string action)
    signal cancelled()

    readonly property var texts: ({
        poweroff: {
            title: "Voulez-vous vraiment éteindre l'ordinateur maintenant ?",
            detail: "Si vous ne faites rien, l'ordinateur s'éteindra automatiquement dans",
            button: "Éteindre",
            icon: "dropdown/power.svg"
        },
        reboot: {
            title: "Voulez-vous vraiment redémarrer l'ordinateur maintenant ?",
            detail: "Si vous ne faites rien, l'ordinateur redémarrera automatiquement dans",
            button: "Redémarrer",
            icon: "dropdown/reload.svg"
        },
        logout: {
            title: "Voulez-vous vraiment fermer la session maintenant ?",
            detail: "Si vous ne faites rien, la session se fermera automatiquement dans",
            button: "Fermer la session",
            icon: "notch/log-out.svg"
        }
    })

    readonly property var current: root.texts[root.action] || null
    property int remaining: 60

    onActionChanged: root.remaining = 60

    Timer {
        interval: 1000
        repeat: true
        running: root.opened
        onTriggered: {
            root.remaining -= 1
            if (root.remaining <= 0)
                root.confirmed(root.action)
        }
    }

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
                    bottom: true
                }
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:power"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                Rectangle {
                    anchors.fill: parent
                    color: "#40000000"
                    opacity: root.opened && panel.entered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade() } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.cancelled()
                    }
                }

                Item {
                    id: win
                    width: 380
                    height: _content.implicitHeight + 40
                    anchors.centerIn: parent
                    focus: true
                    opacity: root.opened && panel.entered ? 1 : 0
                    scale: root.opened && panel.entered ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
                    Behavior on scale { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

                    Keys.onEscapePressed: root.cancelled()
                    Keys.onReturnPressed: root.confirmed(root.action)
                    Keys.onEnterPressed: root.confirmed(root.action)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(e) { e.accepted = true }
                    }

                    BoxGlass {
                        anchors.fill: parent
                        radius: 18
                        color: Qt.rgba(0.10, 0.10, 0.12, 0.72)
                        light: Qt.rgba(1, 1, 1, 0.22)
                        rimStrength: 1.4
                    }

                    Column {
                        id: _content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 14

                        VectorImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            source: root.current ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + root.current.icon) : ""
                            preferredRendererType: VectorImage.CurveRenderer
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: "#FFFFFF"
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.current ? root.current.title : ""
                            color: "#FFFFFF"
                            font.family: "SF Pro Text"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.current ? root.current.detail + " " + root.remaining + " secondes." : ""
                            color: Qt.rgba(1, 1, 1, 0.65)
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                width: 150
                                height: 32
                                radius: 16
                                color: _cancelArea.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.18)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Annuler"
                                    color: "#FFFFFF"
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: _cancelArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.cancelled()
                                }
                            }

                            Rectangle {
                                width: 150
                                height: 32
                                radius: 16
                                color: Theme.accent
                                opacity: _okArea.containsMouse ? 0.85 : 1

                                Text {
                                    anchors.centerIn: parent
                                    text: root.current ? root.current.button : ""
                                    color: Theme.onAccent
                                    font.family: "SF Pro Text"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: _okArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.confirmed(root.action)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
