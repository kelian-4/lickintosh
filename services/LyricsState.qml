pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "lyricsState"

    property int watchers: 0
    readonly property bool wanted: root.watchers > 0

    property var lines: []
    property bool synced: false
    property string status: "idle"
    property string reqKey: ""
    property string qTitle: ""
    property string qArtist: ""
    property string qAlbum: ""
    property string qDuration: ""

    readonly property string trackKey: MprisState.hasPlayer
        ? (MprisState.trackTitle + "|" + MprisState.trackArtist + "|" + MprisState.trackAlbum + "|" + Math.round(MprisState.length))
        : ""

    function watch(on) {
        root.watchers = Math.max(0, root.watchers + (on ? 1 : -1))
        MprisState.fastWatchers = Math.max(0, MprisState.fastWatchers + (on ? 1 : -1))
    }

    onTrackKeyChanged: {
        root.lines = []
        root.synced = false
        root.status = "idle"
        if (root.wanted) soon.restart()
    }

    onWantedChanged: if (root.wanted && root.status === "idle") soon.restart()

    Timer {
        id: soon
        interval: 500
        onTriggered: root.fetch()
    }

    function fetch() {
        if (!root.wanted || !MprisState.hasPlayer || MprisState.trackTitle === "") return
        if (proc.running) return
        root.reqKey = root.trackKey
        root.qTitle = MprisState.trackTitle
        root.qArtist = MprisState.trackArtist
        root.qAlbum = MprisState.trackAlbum
        root.qDuration = String(Math.round(MprisState.length))
        root.status = "loading"
        proc.running = true
    }

    function parseLrc(txt) {
        var out = []
        var rows = String(txt).split(/\r?\n/)
        for (var i = 0; i < rows.length; i++) {
            var re = /\[(\d+):(\d+(?:\.\d+)?)\]/g
            var times = []
            var m
            while ((m = re.exec(rows[i])) !== null) times.push(parseInt(m[1]) * 60 + parseFloat(m[2]))
            if (times.length === 0) continue
            var text = rows[i].replace(/\[[^\]]*\]/g, "").trim()
            for (var j = 0; j < times.length; j++) out.push({ t: times[j], text: text })
        }
        out.sort(function (a, b) { return a.t - b.t })
        return out
    }

    function apply(raw) {
        var o = null
        try { o = JSON.parse(raw) } catch (e) {}
        if (Array.isArray(o)) {
            var pick = null
            for (var i = 0; i < o.length; i++) {
                if (o[i].syncedLyrics) { pick = o[i]; break }
                if (!pick && o[i].plainLyrics) pick = o[i]
            }
            o = pick
        }
        if (!o || o.instrumental) {
            root.lines = []
            root.synced = false
            root.status = "none"
            return
        }
        if (o.syncedLyrics) {
            var l = root.parseLrc(o.syncedLyrics)
            if (l.length > 0) {
                root.lines = l
                root.synced = true
                root.status = "ok"
                return
            }
        }
        if (o.plainLyrics) {
            var parts = String(o.plainLyrics).split(/\r?\n/)
            var pl = []
            for (var k = 0; k < parts.length; k++) if (parts[k].trim() !== "") pl.push({ t: -1, text: parts[k].trim() })
            if (pl.length > 0) {
                root.lines = pl
                root.synced = false
                root.status = "ok"
                return
            }
        }
        root.lines = []
        root.synced = false
        root.status = "none"
    }

    function indexAt(pos) {
        if (!root.synced) return -1
        var idx = -1
        for (var i = 0; i < root.lines.length; i++) {
            if (root.lines[i].t <= pos + 0.2) idx = i
            else break
        }
        return idx
    }

    Process {
        id: proc

        command: ["sh", "-c",
            "UA='lickintosh (quickshell)'; "
            + "curl -fsS --max-time 8 -A \"$UA\" -G https://lrclib.net/api/get --data-urlencode \"track_name=$1\" --data-urlencode \"artist_name=$2\" --data-urlencode \"album_name=$3\" -d \"duration=$4\" 2>/dev/null "
            + "|| curl -fsS --max-time 8 -A \"$UA\" -G https://lrclib.net/api/search --data-urlencode \"q=$2 $1\" 2>/dev/null "
            + "|| printf '{}'",
            "sh", root.qTitle, root.qArtist, root.qAlbum, root.qDuration]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.reqKey !== root.trackKey) {
                    root.status = "idle"
                    Qt.callLater(root.fetch)
                    return
                }
                root.apply(text)
            }
        }
    }
}
