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
        onSourceChanged: if (root.run && source != "") player.play()
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia && root.run) player.play()
        onErrorOccurred: function(error, errorString) { console.warn("[wallpaper video] " + errorString) }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: player.playbackState !== MediaPlayer.StoppedState && player.hasVideo
    }
}
