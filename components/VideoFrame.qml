import QtQuick
import QtMultimedia

Item {
    id: root

    property string source: ""

    MediaPlayer {
        id: player
        source: root.source !== "" ? "file://" + root.source : ""
        videoOutput: output
        audioOutput: null
        onMediaStatusChanged: if (player.mediaStatus === MediaPlayer.LoadedMedia) player.play()
        onPositionChanged: if (player.position > 0 && player.playbackState === MediaPlayer.PlayingState) player.pause()
        onErrorOccurred: function(error, errorString) { console.warn("[video preview] " + errorString) }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
