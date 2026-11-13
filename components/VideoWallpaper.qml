import QtQuick
import QtMultimedia
import qs.components.glass

Item {
    id: root

    property string source: ""
    property bool paused: false

    readonly property bool run: !root.paused
    readonly property bool ready: output.visible && player.position > 0

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

    function grabFrame() {
        if (!output.visible || output.width <= 0) return
        output.grabToImage(function(result) {
            GlassWallpaper.videoGrab = result
            GlassWallpaper.videoUrl = result.url.toString()
        }, Qt.size(Math.min(1920, output.width), Math.min(1080, output.height)))
    }

    onSourceChanged: {
        GlassWallpaper.videoUrl = ""
        grabTimer.restart()
    }

    Timer {
        id: grabTimer
        interval: 900
        repeat: false
        onTriggered: root.grabFrame()
    }

    Connections {
        target: player
        function onPlaybackStateChanged() { if (player.playbackState === MediaPlayer.PlayingState) grabTimer.restart() }
    }

    Component.onDestruction: GlassWallpaper.videoUrl = ""

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: player.playbackState !== MediaPlayer.StoppedState && player.hasVideo
    }
}
