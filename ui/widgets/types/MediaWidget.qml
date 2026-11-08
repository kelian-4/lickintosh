import QtQuick
import qs.components
import qs.services

Item {
    id: w

    property var look: null
    property string size: "s"

    readonly property bool fullBleed: true
    readonly property bool isSmall: w.size === "s"
    readonly property bool isMedium: w.size === "m"
    readonly property bool isLarge: w.size === "l"

    readonly property bool dark: w.look ? !w.look.light : true
    readonly property bool hasPlayer: MprisState.hasPlayer
    readonly property bool playing: MprisState.isPlaying
    readonly property string fam: "SF Pro Text"

    readonly property real k: w.isSmall ? w.width / 202 : (w.isMedium ? w.height / 202 : w.width / 446)
    readonly property real wr: w.width / w.k
    readonly property real hr: w.height / w.k

    function fileUrl(p) {
        if (!p) return ""
        if (p.indexOf("/") === 0) return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
        return p
    }
    readonly property url artSrc: w.fileUrl(MprisState.artUrl)

    function fa(a) { return w.dark ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a) }
    readonly property color fg: w.fa(w.dark ? 0.90 : 0.86)
    readonly property color fg2: w.fa(w.dark ? 0.52 : 0.50)
    readonly property color fgBtn: w.fa(w.dark ? 0.78 : 0.72)
    readonly property color fgDim: w.fa(w.dark ? 0.52 : 0.48)
    readonly property color trackCol: w.fa(w.dark ? 0.14 : 0.10)
    readonly property color fillCol: w.fa(w.dark ? 0.58 : 0.50)

    property bool tintKnown: false
    property real tintH: 0
    property real tintS: 0
    readonly property bool faceTint: w.tintKnown && w.hasPlayer && w.look !== null && !w.look.glass
    function tintFace(l, satMul) { return Qt.hsla(w.tintH, Math.min(0.7, w.tintS * satMul), l, 1) }

    Component.onCompleted: MprisState.watchPosition(true)
    Component.onDestruction: MprisState.watchPosition(false)

    Canvas {
        id: tintSampler
        width: 16
        height: 16
        visible: false
        renderTarget: Canvas.Image

        property url want: w.artSrc
        property url loaded: ""
        property int tries: 0

        function startLoad() {
            if (loaded != "") {
                try { unloadImage(loaded) } catch (e) {}
                loaded = ""
            }
            if (want == "") {
                w.tintKnown = false
                retry.stop()
                return
            }
            loaded = want
            if (isImageLoaded(want)) requestPaint()
            else {
                loadImage(want)
                retry.restart()
            }
        }

        onWantChanged: {
            w.tintKnown = false
            tries = 0
            retry.stop()
            startLoad()
        }
        Component.onCompleted: startLoad()
        onImageLoaded: {
            retry.stop()
            requestPaint()
        }

        Timer {
            id: retry
            interval: 600
            onTriggered: {
                if (tintSampler.loaded != "" && !tintSampler.isImageLoaded(tintSampler.loaded) && ++tintSampler.tries <= 8)
                    tintSampler.startLoad()
            }
        }

        onPaint: {
            if (want == "" || loaded != want || !isImageLoaded(want)) return
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, 16, 16)
            ctx.drawImage(want, 0, 0, 16, 16)
            var d = ctx.getImageData(0, 0, 16, 16).data
            var sr = 0, sg = 0, sb = 0, sw = 0
            for (var i = 0; i < d.length; i += 4) {
                var r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255
                var mx = Math.max(r, g, b), mn = Math.min(r, g, b)
                var wt = 0.05 + (mx - mn) * (mx - mn) * 4
                sr += r * wt
                sg += g * wt
                sb += b * wt
                sw += wt
            }
            if (sw <= 0) {
                w.tintKnown = false
                return
            }
            var c = Qt.rgba(sr / sw, sg / sw, sb / sw, 1)
            w.tintH = c.hslHue < 0 ? 0 : c.hslHue
            w.tintS = c.hslSaturation
            w.tintKnown = true
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: w.look !== null && !w.look.glass
        radius: 22
        border.width: 1
        border.color: w.look ? w.look.rim : "transparent"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: w.faceTint ? (w.dark ? w.tintFace(0.29, 0.75) : w.tintFace(0.92, 0.85)) : (w.dark ? "#38393D" : "#E9EAEB")
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            GradientStop {
                position: 0.55
                color: w.faceTint ? (w.dark ? w.tintFace(0.23, 0.75) : w.tintFace(0.88, 0.85)) : (w.dark ? "#303135" : "#DFE0E2")
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            GradientStop {
                position: 1.0
                color: w.faceTint ? (w.dark ? w.tintFace(0.15, 0.75) : w.tintFace(0.83, 0.85)) : (w.dark ? "#242529" : "#D6D7DA")
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }
    }

    function fmt(sec) {
        var s = Math.max(0, Math.floor(sec)), m = Math.floor(s / 60)
        return m + ":" + ("0" + (s % 60)).slice(-2)
    }

    readonly property real length: MprisState.length
    readonly property real position: MprisState.position
    readonly property real progress: w.length > 0 ? Math.max(0, Math.min(1, w.position / w.length)) : 0

    property bool seeking: false
    property bool seekHold: false
    property real seekFrac: 0
    readonly property bool seekShown: w.seeking || w.seekHold
    readonly property real shownFrac: w.seekShown ? w.seekFrac : w.progress
    readonly property real shownPos: w.seekShown ? w.seekFrac * w.length : w.position
    Timer {
        id: seekHoldTimer
        interval: 900
        onTriggered: w.seekHold = false
    }

    readonly property string shownTitle: w.hasPlayer ? (MprisState.trackTitle !== "" ? MprisState.trackTitle : I18n.tr("Unknown Title")) : I18n.tr("Not Playing")
    readonly property string shownSub: w.hasPlayer
        ? (MprisState.trackArtist !== "" ? (MprisState.trackAlbum !== "" ? MprisState.trackArtist + " — " + MprisState.trackAlbum : MprisState.trackArtist) : MprisState.trackAlbum)
        : I18n.tr("Open a music app")

    readonly property real mx: 23
    readonly property real artY: 23
    readonly property real artS: w.isSmall ? 110 : (w.isMedium ? w.hr - 142 : w.hr - 218)
    readonly property real artX: w.isLarge ? (w.wr - w.artS) / 2 : w.mx
    readonly property real textX: w.isSmall ? w.mx : (w.isMedium ? w.mx + w.artS + 18 : w.mx)
    readonly property real titleCY: w.isSmall ? w.hr - 60 : (w.isMedium ? w.artY + w.artS / 2 - 16 : w.hr - 165)
    readonly property real subCY: w.isSmall ? w.hr - 31 : (w.isMedium ? w.artY + w.artS / 2 + 16 : w.hr - 137.5)
    readonly property real barCY: w.hr - 95.5
    readonly property real timeCY: w.hr - 75.2
    readonly property real ctlCY: w.hr - 44

    PlayerArt {
        x: w.artX * w.k
        y: w.artY * w.k
        width: w.artS * w.k
        height: width
        r: 11 * w.k
        source: w.artSrc
    }

    Text {
        x: w.textX * w.k
        y: w.titleCY * w.k - height / 2
        width: (w.wr - w.textX - w.mx - (w.isMedium ? 50 : 0)) * w.k
        height: 30 * w.k
        verticalAlignment: Text.AlignVCenter
        text: w.shownTitle
        elide: Text.ElideRight
        color: w.fg
        font.family: w.fam
        font.pixelSize: (w.isSmall ? 21 : 24) * w.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    MarqueeText {
        x: (w.textX - 17) * w.k
        y: w.subCY * w.k - height / 2
        width: (w.wr - (w.textX - 17) - (w.mx - 17) - (w.isMedium ? 50 : 0)) * w.k
        text: w.shownSub
        color: w.fg2
        fam: w.fam
        pixelSize: (w.isSmall ? 18 : 21) * w.k
        weight: Font.Medium
        fade: 20 * w.k
        startPad: 17 * w.k
        animate: true
    }

    PlayerBtn {
        visible: w.isSmall
        x: (w.wr - w.mx - 46) * w.k
        y: 23 * w.k
        width: 46 * w.k
        height: width
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: w.playing ? "pause" : "play"
        col: w.fgBtn
        gw: 22 * w.k
        gh: 26 * w.k
        enabledBtn: MprisState.canTogglePlaying
        onClicked: MprisState.togglePlaying()
    }

    Rectangle {
        id: bar
        visible: !w.isSmall
        x: w.mx * w.k
        y: w.barCY * w.k - height / 2
        width: (w.wr - 2 * w.mx) * w.k
        height: (seekMa.pressed || seekMa.containsMouse ? 11 : 7) * w.k
        radius: height / 2
        color: w.trackCol
        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            width: w.hasPlayer && w.length > 0 ? Math.max(parent.height, parent.width * w.shownFrac) : 0
            height: parent.height
            radius: height / 2
            color: seekMa.pressed || seekMa.containsMouse ? w.fa(w.dark ? 0.78 : 0.66) : w.fillCol
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: seekMa
            anchors.fill: parent
            anchors.topMargin: -14 * w.k
            anchors.bottomMargin: -14 * w.k
            hoverEnabled: true
            preventStealing: true
            enabled: w.hasPlayer && MprisState.canSeek && w.length > 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            function frac(mx) { return Math.max(0, Math.min(1, mapToItem(bar, mx, 0).x / bar.width)) }

            onPressed: function(mouse) {
                seekHoldTimer.stop()
                w.seekHold = false
                w.seekFrac = frac(mouse.x)
                w.seeking = true
            }
            onPositionChanged: function(mouse) { if (pressed) w.seekFrac = frac(mouse.x) }
            onReleased: {
                w.seeking = false
                w.seekHold = true
                seekHoldTimer.restart()
                MprisState.seek(w.seekFrac * w.length)
            }
            onCanceled: w.seeking = false
        }
    }

    Text {
        visible: !w.isSmall
        x: w.mx * w.k
        y: w.timeCY * w.k - height / 2
        height: 18 * w.k
        verticalAlignment: Text.AlignVCenter
        text: w.hasPlayer ? w.fmt(w.shownPos) : ""
        color: w.fg2
        font.family: w.fam
        font.pixelSize: 13 * w.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Text {
        id: timeR
        visible: !w.isSmall && w.length > 0
        x: (w.wr - w.mx) * w.k - width
        y: w.timeCY * w.k - height / 2
        height: 18 * w.k
        verticalAlignment: Text.AlignVCenter
        text: "−" + w.fmt(Math.max(0, w.length - w.shownPos))
        color: w.fg2
        font.family: w.fam
        font.pixelSize: 13 * w.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    PlayerBtn {
        visible: !w.isSmall
        x: 25 * w.k
        y: w.ctlCY * w.k - height / 2
        width: 44 * w.k
        height: width
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: "shuffle"
        col: MprisState.shuffle ? w.fgBtn : w.fgDim
        gw: 26 * w.k
        gh: 21 * w.k
        on: MprisState.shuffle
        enabledBtn: MprisState.shuffleSupported
        onClicked: MprisState.toggleShuffle()
    }

    PlayerBtn {
        visible: !w.isSmall
        x: 0.30 * w.width - width / 2
        y: w.ctlCY * w.k - height / 2
        width: 56 * w.k
        height: 44 * w.k
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: "prev"
        col: w.fgBtn
        gw: 44 * w.k
        gh: 25 * w.k
        enabledBtn: MprisState.canGoPrevious
        onClicked: MprisState.previous()
    }

    PlayerBtn {
        visible: !w.isSmall
        x: 0.50 * w.width - width / 2
        y: w.ctlCY * w.k - height / 2
        width: 56 * w.k
        height: 52 * w.k
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: w.playing ? "pause" : "play"
        col: w.fa(w.dark ? 0.84 : 0.78)
        gw: (w.playing ? 30 : 32) * w.k
        gh: 38 * w.k
        enabledBtn: MprisState.canTogglePlaying
        onClicked: MprisState.togglePlaying()
    }

    PlayerBtn {
        visible: !w.isSmall
        x: 0.70 * w.width - width / 2
        y: w.ctlCY * w.k - height / 2
        width: 56 * w.k
        height: 44 * w.k
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: "next"
        col: w.fgBtn
        gw: 44 * w.k
        gh: 25 * w.k
        enabledBtn: MprisState.canGoNext
        onClicked: MprisState.next()
    }

    PlayerBtn {
        visible: !w.isSmall
        x: (w.wr - 25 - 44) * w.k
        y: w.ctlCY * w.k - height / 2
        width: 44 * w.k
        height: width
        dark: w.dark
        hasPlayer: w.hasPlayer
        fam: w.fam
        kind: "repeat"
        col: MprisState.loopActive ? w.fgBtn : w.fgDim
        gw: 26 * w.k
        gh: 22 * w.k
        on: MprisState.loopActive
        badge: MprisState.loopTrack ? "1" : ""
        enabledBtn: MprisState.loopSupported
        onClicked: MprisState.cycleLoop()
    }
}
