import QtQuick
import QtMultimedia

Item {
    id: root

    property string source: ""
    property bool paused: false

    readonly property bool run: !root.paused

    onRunChanged: {
        if (root.run) player.play()
        else player.pause()
    }

    MediaPlayer {
        id: player
        source: root.source !== "" ? "file://" + root.source : ""
        loops: MediaPlayer.Infinite
        videoOutput: output
        audioOutput: null
        Component.onCompleted: if (root.run) player.play()
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: player.playbackState !== MediaPlayer.StoppedState && player.hasVideo
    }
}
