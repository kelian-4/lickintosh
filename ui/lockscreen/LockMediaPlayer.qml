pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.glass
import qs.services

Item {
    id: root

    property Item glassBackdrop: null

    readonly property bool hasPlayer: MprisState.hasPlayer
    visible: root.hasPlayer
    implicitWidth: 372

    property string mode: "bubble"
    readonly property bool artMode: root.mode === "art"
    readonly property bool lyricsMode: root.mode === "lyrics"
    readonly property real artSize: root.artMode ? 220 : 58
    readonly property real scrubY: root.artMode ? 300 : (root.lyricsMode ? 252 : 88)
    implicitHeight: root.visible ? root.scrubY + 62 : 0
    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
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

    CFClippingRect {
        id: pill
        anchors.fill: parent
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

        PlayerArt {
            id: art
            x: root.artMode ? Math.round((pill.width - width) / 2) : 16
            y: 16
            width: root.artSize
            height: root.artSize
            r: root.artMode ? 16 : 11
            source: root.fileUrl(MprisState.artUrl)

            Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on r { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            GlassRim {
                anchors.fill: parent
                radius: art.r
                baseColor: "transparent"
                glowColor: Qt.rgba(1, 1, 1, 0.5)
                glowEdgeBand: 0.025
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mode = root.artMode ? "bubble" : "art"
            }
        }

        Column {
            x: root.artMode ? 20 : 87
            y: root.artMode ? 16 + root.artSize + 14 : 16 + (58 - height) / 2
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
                font.pixelSize: root.artMode ? 18 : 15
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            MarqueeText {
                width: parent.width
                text: MprisState.trackArtist.length > 0 ? MprisState.trackArtist : MprisState.identity
                color: Qt.rgba(1, 1, 1, 0.66)
                fam: root.fam
                pixelSize: root.artMode ? 15 : 13
                weight: Font.Normal
                fade: 14
                animate: MprisState.isPlaying
            }
        }

        ListView {
            id: lv
            x: 18
            y: 84
            width: pill.width - 36
            height: 160
            clip: true
            visible: opacity > 0
            opacity: root.lyricsMode && LyricsState.status === "ok" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 240 } }
            model: LyricsState.lines
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            interactive: !LyricsState.synced
            highlightRangeMode: LyricsState.synced ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
            preferredHighlightBegin: height / 2 - 22
            preferredHighlightEnd: height / 2 + 22
            highlightMoveDuration: 380
            currentIndex: LyricsState.synced ? Math.max(0, lv.cur) : 0

            readonly property int cur: LyricsState.indexAt(MprisState.position)

            delegate: Text {
                id: ln
                required property var modelData
                required property int index
                width: lv.width - 6
                wrapMode: Text.WordWrap
                text: ln.modelData.text !== "" ? ln.modelData.text : "\u266a"
                color: "white"
                opacity: !LyricsState.synced ? 0.9 : (ln.index === lv.cur ? 1 : 0.35)
                font.family: root.fam
                font.pixelSize: 19
                font.weight: Font.Bold
                renderType: Text.NativeRendering
                Behavior on opacity { NumberAnimation { duration: 260 } }

                MouseArea {
                    anchors.fill: parent
                    enabled: LyricsState.synced && MprisState.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: MprisState.seek(ln.modelData.t)
                }
            }
        }

        Text {
            visible: root.lyricsMode && LyricsState.status !== "ok"
            x: 18
            y: 84
            width: pill.width - 36
            height: 160
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: LyricsState.status === "loading" ? I18n.tr("Loading lyrics…") : I18n.tr("No lyrics found")
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: root.fam
            font.pixelSize: 15
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
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
            onClicked: root.mode = root.lyricsMode ? "bubble" : "lyrics"
        }
    }
}
