import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import Quickshell.Services.Pipewire
import qs.ui.primitives

Item {
    id: root
    signal closeRequested()
    property bool needsKeyboard: false
    implicitHeight: content.implicitHeight + 24

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var outputs: {
        var list = []
        var nodes = Pipewire.nodes.values
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n.audio && !n.isStream && n.isSink) {
                list.push(n)
            }
        }
        return list
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property real volume: {
        const v = root.sink && root.sink.audio ? Number(root.sink.audio.volume) : 0
        return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0
    }
    readonly property bool muted: {
        return !!(root.sink && root.sink.audio && root.sink.audio.muted)
    }

    function volumeIconName() {
        if (root.muted || root.volume === 0) return "audio-volume-0.svg"
        if (root.volume < 0.33) return "audio-volume-1.svg"
        if (root.volume < 0.66) return "audio-volume-2.svg"
        return "audio-volume-3.svg"
    }

    function toggleMute() {
        if (root.sink && root.sink.audio) {
            root.sink.audio.muted = !root.sink.audio.muted
        }
    }

    function setVolume(v) {
        if (root.sink && root.sink.audio) {
            root.sink.audio.muted = false
            root.sink.audio.volume = v
        }
    }

    function setDefaultOutput(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function outputLabel(node) {
        if (node.description && node.description.length > 0) return node.description
        if (node.nickname && node.nickname.length > 0) return node.nickname
        return node.name
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 12

        CFText {
            text: "Sound"
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                width: 18
                height: 18
                Layout.alignment: Qt.AlignVCenter

                VectorImage {
                    anchors.fill: parent
                    source: "../../../../assets/icons/volume/" + root.volumeIconName()
                    preferredRendererType: VectorImage.CurveRenderer
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }

            CFSlider {
                id: volSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                value: root.volume
                onMoved: root.setVolume(value)
            }

            Item {
                width: 18
                height: 18
                Layout.alignment: Qt.AlignVCenter

                VectorImage {
                    anchors.fill: parent
                    source: "../../../../assets/icons/volume/audio-volume-3.svg"
                    preferredRendererType: VectorImage.CurveRenderer
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Output"
                gray: true
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.outputs

                    Rectangle {
                        id: outputRow
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: outputMouse.containsMouse ? "#14ffffff" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        readonly property bool isActive: root.sink && modelData.id === root.sink.id

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: outputRow.isActive ? "#1C7AFF" : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                VectorImage {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: "../../../../assets/icons/volume/audio-volume-3.svg"
                                    preferredRendererType: VectorImage.CurveRenderer
                                }
                            }

                            CFText {
                                text: root.outputLabel(modelData)
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: outputMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setDefaultOutput(modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        MouseArea {
            Layout.fillWidth: true
            height: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()

            CFText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Sound Settings..."
                font.pixelSize: 13
            }
        }
    }
}
