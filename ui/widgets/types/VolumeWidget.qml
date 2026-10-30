import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components

Item {
    id: root

    property string size: "s"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink !== null && root.sink.audio !== null
    readonly property real level: root.ready ? Number(root.sink.audio.volume) : 0
    readonly property bool muted: root.ready && root.sink.audio.muted

    PwObjectTracker {
        objects: [root.sink]
    }

    function setLevel(value) {
        if (!root.ready) return
        root.sink.audio.muted = false
        root.sink.audio.volume = Math.max(0, Math.min(1, value))
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Volume"
                color: "#0a84ff"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.muted ? "Muted" : Math.round(root.level * 100) + "%"
                color: "#ffffff"
                font.pixelSize: 13
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.size === "m" && root.ready
            text: root.sink.description !== "" ? root.sink.description : root.sink.name
            elide: Text.ElideRight
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 12
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28

                CFVI {
                    anchors.centerIn: parent
                    size: 22
                    icon: root.muted ? "notch/volume-x.svg" : "notch/volume-2.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.ready) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Qt.rgba(1, 1, 1, 0.14)

                Rectangle {
                    width: track.width * (root.muted ? 0 : Math.max(0, Math.min(1, root.level)))
                    height: track.height
                    radius: 5
                    color: "#0a84ff"
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    onPressed: function(mouse) { root.setLevel(mouse.x / track.width) }
                    onPositionChanged: function(mouse) {
                        if (pressed) root.setLevel(mouse.x / track.width)
                    }
                }
            }
        }
    }
}
