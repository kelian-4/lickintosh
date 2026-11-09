pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.components.glass
import qs.services

Item {
    id: root

    property Item glassBackdrop: null

    readonly property bool hasPlayer: MprisState.hasPlayer
    visible: root.hasPlayer
    implicitWidth: 372

    property real screenW: 1920
    property real lyricsH: 360
    property real maxArt: 244
    readonly property real bigArt: Math.max(96, Math.min(244, root.maxArt))
    readonly property real artGap: 22
    readonly property real sideGap: 32
    readonly property real sideLyrW: Math.max(260, Math.min(560, root.screenW - 372 - root.sideGap - 96))

    property string mode: "bubble"
    readonly property bool artMode: root.mode === "art" || root.mode === "artlyrics"
    readonly property bool lyricsMode: root.mode === "lyrics" || root.mode === "artlyrics"
    readonly property bool sideMode: root.mode === "artlyrics"

    property real artT: root.artMode ? 1 : 0
    Behavior on artT { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
    property real lyrT: root.lyricsMode ? 1 : 0
    Behavior on lyrT { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
    property real sideT: root.sideMode ? 1 : 0
    Behavior on sideT { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }

    readonly property real scrubY: root.artMode ? 76 : 88
    readonly property real pillH: root.scrubY + 62
    implicitHeight: root.visible ? root.pillH + (root.artMode ? root.bigArt + root.artGap : (root.lyricsMode ? root.lyricsH + 24 : 0)) : 0
    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    transform: Translate { x: -root.sideT * (root.sideLyrW + root.sideGap) / 2 }

    function nextOnCover() {
        var m = root.mode
        root.mode = m === "bubble" ? "art" : m === "art" ? "bubble" : m === "lyrics" ? "artlyrics" : "lyrics"
    }

    function nextOnLyrics() {
        var m = root.mode
        root.mode = m === "bubble" ? "lyrics" : m === "lyrics" ? "bubble" : m === "art" ? "artlyrics" : "art"
    }

    onHasPlayerChanged: if (!root.hasPlayer) root.mode = "bubble"

    readonly property bool wantLyrics: root.lyricsMode && root.visible
    onWantLyricsChanged: LyricsState.watch(root.wantLyrics)

    opacity: root.hasPlayer ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    readonly property string fam: "SF Pro Text"
    readonly property real length: MprisState.length
    readonly property real position: MprisState.position
    readonly property real progress: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0

    property bool seeking: false
    property bool seekHold: false
    property real seekFrac: 0
    readonly property bool seekShown: root.seeking || root.seekHold
    readonly property real shownFrac: root.seekShown ? root.seekFrac : root.progress
    readonly property real shownPos: root.seekShown ? root.seekFrac * root.length : root.position

    function fmt(sec) {
        var s = Math.max(0, Math.floor(sec)), m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    function fileUrl(p) {
        if (!p) return ""
        if (p.indexOf("/") === 0) return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
        return p
    }

    onVisibleChanged: MprisState.watchPosition(root.visible)
    Component.onCompleted: if (root.visible) MprisState.watchPosition(true)
    Component.onDestruction: {
        if (root.visible) MprisState.watchPosition(false)
        if (root.wantLyrics) LyricsState.watch(false)
    }

    Timer {
        id: seekHoldTimer
        interval: 900
        onTriggered: root.seekHold = false
    }

    Item {
        id: cover
        readonly property real pillTop: root.height - root.pillH
        readonly property real t: root.artT
        x: 16 + (Math.round((root.width - width) / 2) - 16) * t
        y: pillTop + 16 + ((pillTop - root.artGap - root.bigArt) - (pillTop + 16)) * t
        width: 58 + (root.bigArt - 58) * t
        height: width
        z: 5
        opacity: root.hasPlayer ? 1 : 0

        RectangularShadow {
            anchors.fill: parent
            radius: art.r
            blur: 40
            spread: 0
            offset.y: 14
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: Math.max(0, Math.min(1, cover.t))
        }

        PlayerArt {
            id: art
            anchors.fill: parent
            r: 11 + 17 * cover.t
            source: root.fileUrl(MprisState.artUrl)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextOnCover()
            }
        }
    }

    Item {
        id: lyr
        visible: root.lyrT > 0.01
        clip: true
        z: 4
        readonly property real wTop: Math.min(root.screenW - 80, 620)
        readonly property real soloH: root.lyricsH
        readonly property real sideH: root.bigArt + root.artGap + root.pillH
        readonly property real bottomEdge: (root.height - root.pillH - 24) + (root.pillH + 24) * root.sideT
        width: wTop + (root.sideLyrW - wTop) * root.sideT
        height: soloH + (sideH - soloH) * root.sideT
        x: (root.width - wTop) / 2 + ((root.width + root.sideGap) - (root.width - wTop) / 2) * root.sideT
        y: bottomEdge - height
        opacity: Math.max(0, Math.min(1, root.lyrT))
        scale: 0.94 + 0.06 * root.lyrT
        transformOrigin: root.sideMode ? Item.Left : Item.Bottom

        property real manual: 0
        Behavior on manual { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
        Timer {
            id: manualReset
            interval: 3500
            onTriggered: if (LyricsState.synced) lyr.manual = 0
        }
        WheelHandler {
            onWheel: function(ev) {
                lyr.manual = Math.max(-200, lyr.manual - ev.angleDelta.y * 0.6)
                manualReset.restart()
            }
        }

        readonly property int cur: LyricsState.indexAt(MprisState.position)
        readonly property bool ready: LyricsState.status === "ok"

        readonly property real scrollTo: {
            var it = lyr.cur >= 0 ? rep.itemAt(lyr.cur) : null
            var base = it ? it.y - lyr.height * 0.30 : -lyr.height * 0.30
            return base + lyr.manual
        }

        Item {
            anchors.fill: parent
            clip: true
            visible: lyr.ready
            layer.enabled: true
            layer.effect: ShaderEffect {
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/lyricsfade/fade.frag.qsb")
                property real fadeTop: 0.24
                property real fadeBottom: 0.30
            }

            Column {
                id: col
                width: parent.width
                spacing: 20

                Repeater {
                    id: rep
                    model: LyricsState.lines

                    delegate: Item {
                        id: ln
                        required property var modelData
                        required property int index
                        readonly property int rel: lyr.cur < 0 ? 0 : ln.index - lyr.cur
                        readonly property bool isCur: LyricsState.synced && ln.index === lyr.cur
                        readonly property bool gap: (ln.modelData.text || "") === ""
                        width: col.width
                        height: ln.gap ? 34 : lt.implicitHeight

                        transform: Translate {
                            id: tr
                            y: -lyr.scrollTo
                            Behavior on y { NumberAnimation { duration: 500 + Math.max(0, Math.min(8, ln.rel)) * 20; easing.type: Easing.OutQuint } }
                        }

                        opacity: !LyricsState.synced ? 0.9 : (ln.isCur ? 1 : (Math.abs(ln.rel) === 1 ? 0.42 : 0.26))
                        Behavior on opacity { NumberAnimation { duration: 380 } }

                        Text {
                            id: lt
                            visible: !ln.gap
                            width: parent.width
                            text: ln.modelData.text
                            wrapMode: Text.WordWrap
                            color: "white"
                            font.family: root.fam
                            font.pixelSize: 31
                            font.weight: Font.Bold
                            lineHeight: 1.08
                            renderType: Text.NativeRendering
                            transformOrigin: Item.Left
                            scale: ln.isCur || !LyricsState.synced ? 1 : 0.965
                            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
                            layer.enabled: LyricsState.synced && !ln.isCur && Math.abs(ln.rel) <= 6
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blurMax: 16
                                blur: Math.min(0.55, 0.14 * Math.abs(ln.rel))
                            }
                        }

                        Row {
                            visible: ln.gap
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 9

                            Repeater {
                                model: 3

                                delegate: Rectangle {
                                    required property int index
                                    width: 11
                                    height: 11
                                    radius: 5.5
                                    color: "white"
                                    opacity: ln.isCur ? 0.95 : 0.35

                                    SequentialAnimation on scale {
                                        running: ln.isCur
                                        loops: Animation.Infinite
                                        PauseAnimation { duration: index * 160 }
                                        NumberAnimation { from: 0.7; to: 1.15; duration: 520; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 1.15; to: 0.7; duration: 520; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }

                        readonly property real shownY: ln.y + tr.y
                        readonly property bool inBand: ln.shownY + ln.height > lyr.height * 0.20 && ln.shownY < lyr.height * 0.74

                        TapHandler {
                            enabled: ln.inBand && LyricsState.synced && MprisState.canSeek
                            onTapped: {
                                MprisState.seek(ln.modelData.t)
                                lyr.manual = 0
                            }
                        }

                        HoverHandler {
                            enabled: ln.inBand && LyricsState.synced
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !lyr.ready
            horizontalAlignment: Text.AlignHCenter
            text: LyricsState.status === "loading" || LyricsState.status === "idle" ? I18n.tr("Loading lyrics…") : I18n.tr("No lyrics found")
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: root.fam
            font.pixelSize: 20
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    CFClippingRect {
        id: pill
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.pillH
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        radius: 28

        BoxGlass {
            anchors.fill: parent
            backdrop: root.glassBackdrop
            radius: pill.radius
            color: Qt.rgba(1, 1, 1, 0.10)
            light: Qt.rgba(1, 1, 1, 0.28)
            rimStrength: 0.7
            highlightEnabled: true
        }

        Column {
            x: root.artMode ? 20 : 87
            y: 16 + (58 - height) / 2
            visible: true
            width: pill.width - x - 18
            spacing: 2

            Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            Text {
                width: parent.width
                text: MprisState.trackTitle.length > 0 ? MprisState.trackTitle : I18n.tr("Not Playing")
                elide: Text.ElideRight
                color: "white"
                font.family: root.fam
                font.pixelSize: root.artMode ? 17 : 15
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            MarqueeText {
                width: parent.width
                text: MprisState.trackArtist.length > 0 ? MprisState.trackArtist : MprisState.identity
                color: Qt.rgba(1, 1, 1, 0.66)
                fam: root.fam
                pixelSize: root.artMode ? 14 : 13
                weight: Font.Normal
                fade: 14
                animate: MprisState.isPlaying
            }
        }

        Item {
            id: scrub
            x: 18
            y: root.scrubY
            Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            width: pill.width - 36
            height: 16

            Text {
                id: timeL
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.shownPos)
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fam
                font.pixelSize: 11
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
            }

            Text {
                id: timeR
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.length > 0 ? "-" + root.fmt(root.length - root.shownPos) : "--:--"
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fam
                font.pixelSize: 11
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
            }

            Item {
                id: bar
                anchors.left: timeL.right
                anchors.right: timeR.left
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: barMa.containsMouse || barMa.pressed ? 8 : 5
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.22)
                }

                Rectangle {
                    height: parent.height
                    radius: height / 2
                    width: root.length > 0 ? Math.max(height, parent.width * root.shownFrac) : 0
                    color: Qt.rgba(1, 1, 1, 0.88)
                }

                MouseArea {
                    id: barMa
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    hoverEnabled: true
                    preventStealing: true
                    enabled: MprisState.canSeek && root.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    function frac(mx) { return Math.max(0, Math.min(1, mx / bar.width)) }

                    onPressed: function(mouse) {
                        seekHoldTimer.stop()
                        root.seekHold = false
                        root.seekFrac = frac(mouse.x)
                        root.seeking = true
                    }
                    onPositionChanged: function(mouse) { if (pressed) root.seekFrac = frac(mouse.x) }
                    onReleased: {
                        root.seeking = false
                        root.seekHold = true
                        seekHoldTimer.restart()
                        MprisState.seek(root.seekFrac * root.length)
                    }
                    onCanceled: root.seeking = false
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: scrub.y + scrub.height + 6
            spacing: 26

            PlayerBtn {
                width: 32
                height: 34
                dark: true
                hasPlayer: root.hasPlayer
                kind: "prev"
                col: "white"
                gw: 26
                gh: 15
                enabledBtn: MprisState.canGoPrevious
                onClicked: MprisState.previous()
            }

            PlayerBtn {
                width: 38
                height: 34
                dark: true
                hasPlayer: root.hasPlayer
                kind: MprisState.isPlaying ? "pause" : "play"
                col: "white"
                gw: MprisState.isPlaying ? 18 : 20
                gh: 24
                enabledBtn: MprisState.canTogglePlaying
                onClicked: MprisState.togglePlaying()
            }

            PlayerBtn {
                width: 32
                height: 34
                dark: true
                hasPlayer: root.hasPlayer
                kind: "next"
                col: "white"
                gw: 26
                gh: 15
                enabledBtn: MprisState.canGoNext
                onClicked: MprisState.next()
            }
        }

        PlayerBtn {
            x: pill.width - 18 - width
            y: scrub.y + scrub.height + 6
            width: 32
            height: 34
            dark: true
            hasPlayer: root.hasPlayer
            kind: "lyrics"
            col: root.lyricsMode ? "white" : Qt.rgba(1, 1, 1, 0.55)
            gw: 22
            gh: 18
            on: root.lyricsMode
            enabledBtn: true
            onClicked: root.nextOnLyrics()
        }
    }
}
