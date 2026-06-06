import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.VectorImage
import "../glass"

Scope {
    id: root
    property bool opened: false
    signal closeRequested()

    readonly property int winWidth:  340
    readonly property int winHeight: 520

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                // Fond assombri — PAS de namespace glass ici
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeRequested()
                    }
                }

                // Fenêtre centrée
                Item {
                    id: win
                    width: root.winWidth
                    height: root.winHeight
                    anchors.centerIn: parent

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(e) { e.accepted = true }
                    }

                    // Glass uniquement sur la fenêtre
                    BoxGlass {
                        anchors.fill: parent
                        radius: 14
                        color: Qt.rgba(0.10, 0.10, 0.12, 0.72)
                        light: Qt.rgba(1, 1, 1, 0.22)
                        rimStrength: 0.55
                        highlightEnabled: true
                        lightDir: Qt.vector2d(0.5, -1.0)
                    }

                    // ── Boutons traffic light ────────────────────
                    Row {
                        x: 14
                        y: 14
                        spacing: 8

                        Rectangle {
                            id: _btnClose
                            width: 13
                            height: 13
                            radius: 7
                            color: _hovAll ? "#ff5f57" : "#a03a39"
                            border.color: Qt.rgba(0,0,0,0.2)
                            border.width: 0.5
                            property bool _hovAll: _maClose.containsMouse

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 7
                                color: Qt.rgba(0,0,0,0.75)
                                visible: _maClose.containsMouse
                                renderType: Text.NativeRendering
                            }
                            MouseArea {
                                id: _maClose
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.closeRequested()
                            }
                        }

                        Rectangle {
                            width: 13
                            height: 13
                            radius: 7
                            color: "#a0282828"
                            border.color: Qt.rgba(0,0,0,0.2)
                            border.width: 0.5
                        }

                        Rectangle {
                            width: 13
                            height: 13
                            radius: 7
                            color: "#a0282828"
                            border.color: Qt.rgba(0,0,0,0.2)
                            border.width: 0.5
                        }
                    }

                    // ── Titre barre ──────────────────────────────
                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "About This PC"
                        color: Qt.rgba(1, 1, 1, 0.80)
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }

                    // ── Image laptop ─────────────────────────────
                    VectorImage {
                        id: _deviceImg
                        anchors.top: parent.top
                        anchors.topMargin: 52
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 160
                        height: 110
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/devices/laptop.svg")
                        preferredRendererType: VectorImage.CurveRenderer
                    }

                    // ── Nom OS ───────────────────────────────────
                    Text {
                        id: _osName
                        anchors.top: _deviceImg.bottom
                        anchors.topMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: _procOS.result !== "" ? _procOS.result : "NixOS"
                        color: "#ffffff"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.family: "SF Pro Display"
                        renderType: Text.NativeRendering
                    }

                    // ── Séparateur ───────────────────────────────
                    Rectangle {
                        id: _sep
                        anchors.top: _osName.bottom
                        anchors.topMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.winWidth - 40
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.10)
                    }

                    // ── Grille infos ─────────────────────────────
                    Column {
                        id: _infoCol
                        anchors.top: _sep.bottom
                        anchors.topMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        width: root.winWidth - 40

                        Repeater {
                            model: [
                                { k: "Processor", v: _procCPU.result    },
                                { k: "Graphics",  v: _procGPU.result    },
                                { k: "Memory",    v: _procRAM.result    },
                                { k: "Kernel",    v: _procKernel.result }
                            ]
                            delegate: Row {
                                required property var modelData
                                spacing: 0
                                width: root.winWidth - 40

                                Text {
                                    width: 80
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.k
                                    color: Qt.rgba(1, 1, 1, 0.40)
                                    font.pixelSize: 12
                                    font.family: "SF Pro Display"
                                    renderType: Text.NativeRendering
                                }
                                Item { width: 12; height: 1 }
                                Text {
                                    width: root.winWidth - 40 - 80 - 12
                                    text: modelData.v !== "" ? modelData.v : "…"
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.family: "SF Pro Display"
                                    renderType: Text.NativeRendering
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                            }
                        }
                    }

                    // ── Bouton More Info ─────────────────────────
                    Rectangle {
                        id: _moreBtn
                        anchors.top: _infoCol.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 110
                        height: 28
                        radius: 14
                        color: _maMore.containsMouse
                            ? Qt.rgba(1,1,1,0.18)
                            : Qt.rgba(1,1,1,0.10)
                        border.color: Qt.rgba(1,1,1,0.18)
                        border.width: 0.8

                        Text {
                            anchors.centerIn: parent
                            text: "More Info…"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.family: "SF Pro Display"
                            renderType: Text.NativeRendering
                        }
                        MouseArea {
                            id: _maMore
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally("https://nixos.org")
                        }
                    }
                }

                // ── Processus système ────────────────────────────
                Process {
                    id: _procOS
                    property string result: ""
                    command: ["sh", "-c", "grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: _procOS.result = text.trim() }
                }
                Process {
                    id: _procKernel
                    property string result: ""
                    command: ["sh", "-c", "uname -r"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: _procKernel.result = text.trim() }
                }
                Process {
                    id: _procCPU
                    property string result: ""
                    command: ["sh", "-c", "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: _procCPU.result = text.trim() }
                }
                Process {
                    id: _procGPU
                    property string result: ""
                    command: ["sh", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //' | sed 's/ (rev [0-9a-f]*//'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: _procGPU.result = text.trim() }
                }
                Process {
                    id: _procRAM
                    property string result: ""
                    command: ["sh", "-c", "free -h | awk '/^Mem:/{print $2}'"]
                    running: true
                    stdout: StdioCollector { onStreamFinished: _procRAM.result = text.trim() }
                }
            }
        }
    }
}