pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// API vérifiée contre le vrai code source Quickshell
// (src/services/mpris/player.hpp, watcher.hpp) : Mpris.players est un
// UntypedObjectModel exposant .values ; MprisPlayer expose bien
// isPlaying, canTogglePlaying, canGoNext/Previous directement.
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

    function togglePlaying() { if (root.activePlayer) root.activePlayer.togglePlaying() }
    function next()          { if (root.activePlayer) root.activePlayer.next() }
    function previous()      { if (root.activePlayer) root.activePlayer.previous() }
    function seek(pos)       { if (root.activePlayer) root.activePlayer.position = pos }
}
