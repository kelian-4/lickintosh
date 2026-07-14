import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import Quickshell.Services.Pipewire

RowLayout {
    id: root
    spacing: 6

    signal toggleVolume(int xPos)

    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [sink]
    }
    readonly property real volume: {
        const v = sink && sink.audio ? Number(sink.audio.volume) : 0
        return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0
    }
    readonly property bool muted: {
        return !!(sink && sink.audio && sink.audio.muted)
    }
    function volumeIconName() {
        if (muted) return "audio-volume-0.svg"
        if (volume < 0.33) return "audio-volume-1.svg"
        if (volume < 0.66) return "audio-volume-2.svg"
        return "audio-volume-3.svg"
    }

    Item {
        id: _volBtn
        width: 16
        height: 16
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
            onClicked: root.toggleVolume(_volBtn.mapToItem(null, _volBtn.width / 2, 0).x)
        }
    }

    Text {
        text: Math.round(root.volume * 100) + "%"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        visible: Pipewire.ready && !root.muted && root.volume > 0
        Layout.alignment: Qt.AlignVCenter
    }
}
