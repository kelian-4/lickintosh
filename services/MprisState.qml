pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    reloadableId: "mprisState"

    readonly property var players: Mpris.players.values

    readonly property MprisPlayer activePlayer: {
        for (var i = 0; i < root.players.length; i++) {
            if (root.players[i].isPlaying) return root.players[i]
        }
        return root.players.length > 0 ? root.players[0] : null
    }

    readonly property bool hasPlayer: root.activePlayer !== null
    readonly property bool isPlaying: root.activePlayer !== null && root.activePlayer.isPlaying

    readonly property string trackTitle:  root.activePlayer ? (root.activePlayer.trackTitle  || "") : ""
    readonly property string trackArtist: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
    readonly property string trackAlbum:  root.activePlayer ? (root.activePlayer.trackAlbum  || "") : ""
    readonly property string artUrl:      root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
    readonly property string identity:    root.activePlayer ? (root.activePlayer.identity     || "") : ""

    readonly property real position: root.activePlayer ? root.activePlayer.position : 0
    readonly property real length:   root.activePlayer ? root.activePlayer.length   : 0

    readonly property bool canGoNext:       root.activePlayer ? root.activePlayer.canGoNext       : false
    readonly property bool canGoPrevious:   root.activePlayer ? root.activePlayer.canGoPrevious   : false
    readonly property bool canTogglePlaying: root.activePlayer ? root.activePlayer.canTogglePlaying : false
    readonly property bool canSeek:          root.activePlayer ? (root.activePlayer.canSeek && root.activePlayer.positionSupported && root.activePlayer.lengthSupported) : false

    readonly property bool shuffleSupported: root.activePlayer ? (root.activePlayer.shuffleSupported && root.activePlayer.canControl) : false
    readonly property bool shuffle:          root.activePlayer ? root.activePlayer.shuffle : false
    readonly property bool loopSupported:    root.activePlayer ? (root.activePlayer.loopSupported && root.activePlayer.canControl) : false
    readonly property bool loopActive:       root.activePlayer ? root.activePlayer.loopState !== MprisLoopState.None : false
    readonly property bool loopTrack:        root.activePlayer ? root.activePlayer.loopState === MprisLoopState.Track : false

    property int positionWatchers: 0

    Timer {
        interval: 1000
        repeat: true
        running: root.positionWatchers > 0 && root.isPlaying && root.activePlayer !== null && root.activePlayer.positionSupported
        onTriggered: root.activePlayer.positionChanged()
    }

    function watchPosition(on) { root.positionWatchers = Math.max(0, root.positionWatchers + (on ? 1 : -1)) }

    function togglePlaying() { if (root.activePlayer) root.activePlayer.togglePlaying() }
    function next()          { if (root.activePlayer) root.activePlayer.next() }
    function previous()      { if (root.activePlayer) root.activePlayer.previous() }
    function seek(pos)       { if (root.activePlayer && root.canSeek) root.activePlayer.position = pos }
    function toggleShuffle() { if (root.shuffleSupported) root.activePlayer.shuffle = !root.activePlayer.shuffle }

    function cycleLoop() {
        if (!root.loopSupported) return
        var next = root.activePlayer.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                 : root.activePlayer.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                 : MprisLoopState.None
        root.activePlayer.loopState = next
    }
}
