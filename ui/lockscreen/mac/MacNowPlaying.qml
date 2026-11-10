import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services

Item {
    id: ls
    anchors.fill: parent

    required property Item sceneParent
    required property Item clock
    required property Item login
    property bool isPrimary: true
    property bool shown: true
    property bool leaving: false
    readonly property real u: Math.max(0.85, Math.min(1, height / 900))
    readonly property string fam: "SF Pro Text"
    readonly property string famDisplay: "SF Pro Display"

    readonly property QtObject st: QtObject {
        property string npMode: ""
        property bool artBg: true
        property string mediaSlot: "bottom"
        property bool engaged: false
        function poke() {}
        function setMediaSlot(v) { mediaSlot = v }
    }

        Item {
            id: artBg
            parent: ls.sceneParent
            anchors.fill: parent
            opacity: ls.st.artBg ? ls.clamp01(ls.artT) : 0
            visible: opacity > 0.003
            Rectangle { anchors.fill: parent; color: "#0c0c10" }

            // Animated Canvas Video (Spotify supported music)
            Loader {
                id: canvasLoader
                anchors.fill: parent
                active: ls.canvasVideo !== "" && ls.artT > 0.01
                sourceComponent: Item {
                    anchors.fill: parent
                    MediaPlayer {
                        id: canvasMp
                        source: "file://" + ls.canvasVideo
                        loops: MediaPlayer.Infinite
                        videoOutput: canvasVo
                        Component.onCompleted: play()
                    }
                    VideoOutput {
                        id: canvasVo
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                    }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: canvasLoader.active ? canvasLoader : null
                visible: canvasLoader.active
                scale: 1.15
                blurEnabled: true; blurMax: 48; blur: 0.55
                saturation: 0.35
                brightness: -0.15
            }

            // old and new album, each blurred; the new one fades in over the old one during a hand-over
            Repeater {
                model: canvasLoader.active ? 0 : 2
                delegate: MultiEffect {
                    required property int index
                    readonly property Item img: index === 0 ? ls.coverOld : ls.coverNew
                    anchors.fill: parent
                    scale: 1.25                            // pushes the blur's soft edges off-screen
                    source: img
                    autoPaddingEnabled: false
                    blurEnabled: true; blurMax: 64; blur: 1.0
                    saturation: 0.25
                    brightness: -0.16
                    // new: fades in with the hand-over; old: only there while it's being covered
                    opacity: index === 1 ? ls.bgProg : (ls.bgProg < 1 ? 1 : 0)
                    visible: img.status === Image.Ready && opacity > 0.003
                    z: index
                }
            }
        }

    // shared, pre-blurred copy of the scene that every glass slab (and the clock) refracts
    ShaderEffectSource {
        id: sceneTex
        sourceItem: ls.sceneParent
        // with a video wallpaper the scene changes every frame: the glass copy refreshes at 12 fps instead
        // (blur + every glass shader re-running 30-60x a second was the main GPU cost on the lock screen)
        live: !canvasLoader.active
        visible: false
        textureSize: Qt.size(Math.max(1, Math.round(ls.width / 2)), Math.max(1, Math.round(ls.height / 2)))
    }
    Timer {
        interval: 83; repeat: true
        running: canvasLoader.active && ls.shown && !ls.leaving
        onTriggered: sceneTex.scheduleUpdate()
    }
    MultiEffect {
        id: sceneBlurFx
        source: sceneTex
        width: sceneTex.textureSize.width; height: sceneTex.textureSize.height
        blurEnabled: true
        blurMax: 32
        blur: 0.35
        autoPaddingEnabled: false
        visible: false
    }
    ShaderEffectSource {
        id: glassTex
        sourceItem: sceneBlurFx
        live: true
        mipmap: true
        visible: false
    }

    // ═════════════ COVER HAND-OVER ═════════════
    // Two picture slots. A new cover loads into the back slot; once it's there (or after 1.5 s) the bubble's cover
    // "burns" over to it (burn.frag) and the blurred album background cross-fades, both in step.
    readonly property string coverUrl: media.pl && media.pl.trackArtUrl ? media.pl.trackArtUrl : ""
    property int coverIdx: 0
    property real coverProg: 1
    property real coverSeed: 0
    property bool coverPending: false
    onCoverUrlChanged: {
        if (coverUrl === "" || !ls.isPrimary) return;
        var cur = coverIdx === 0 ? coverA : coverB;
        if (cur.source.toString() === coverUrl) return;
        if (cur.source.toString() === "") { cur.source = coverUrl; return; }     // first cover: just show it
        (coverIdx === 0 ? coverB : coverA).source = coverUrl;
        coverPending = true;
        coverWait.restart();
        coverTry();
    }
    function coverTry() {
        if (!coverPending) return;
        var t = coverIdx === 0 ? coverB : coverA;
        if (t.status === Image.Loading && coverWait.running) return;
        coverPending = false;
        coverWait.stop();
        coverIdx = 1 - coverIdx;
        coverSeed = Math.random();
        coverAnim.restart();
        bgAnim.restart();
    }
    Timer { id: coverWait; interval: 1500; onTriggered: ls.coverTry() }
    NumberAnimation { id: coverAnim; target: ls; property: "coverProg"; from: 0; to: 1; duration: 1100; easing.type: Easing.InOutCubic }
    // the blurred album background: its own, quicker hand-over (0.65 s ease-out)
    property real bgProg: 1
    NumberAnimation { id: bgAnim; target: ls; property: "bgProg"; from: 0; to: 1; duration: 650; easing.type: Easing.OutCubic }
    Image { id: coverA; visible: false; width: 600; height: 600; fillMode: Image.PreserveAspectCrop; asynchronous: true; mipmap: true; sourceSize: Qt.size(600, 600); onStatusChanged: ls.coverTry() }
    Image { id: coverB; visible: false; width: 600; height: 600; fillMode: Image.PreserveAspectCrop; asynchronous: true; mipmap: true; sourceSize: Qt.size(600, 600); onStatusChanged: ls.coverTry() }
    readonly property Item coverNew: coverIdx === 0 ? coverA : coverB
    readonly property Item coverOld: coverIdx === 0 ? coverB : coverA

    // ═════════════ NOW PLAYING ═════════════
    readonly property var player: {
        var ps = Mpris.players.values, best = null;
        for (var i = 0; i < ps.length; i++) {
            if (ps[i].isPlaying) return ps[i];
            if (!best && ps[i].trackTitle) best = ps[i];
        }
        return best;
    }
    readonly property bool hasMedia: player !== null && player !== undefined && (player.trackTitle || "") !== ""
    // Apple "artwork mode" (tap the cover: it leaves the bubble, as wide as the bubble) and Apple Music style lyrics
    // (lyrics button). Only one at a time.
    // npMode: "" | "art" | "lyrics" | "artlyrics" (big cover on the left, lyrics on the right — Apple Music full screen)
    readonly property bool artMode: (ls.st.npMode === "art" || ls.st.npMode === "artlyrics") && hasMedia && isPrimary && !leaving
    readonly property bool lyricsMode: (ls.st.npMode === "lyrics" || ls.st.npMode === "artlyrics") && hasMedia && isPrimary && !leaving
    readonly property bool sideMode: ls.st.npMode === "artlyrics" && hasMedia && isPrimary && !leaving
    // 0 → 1: cover + bubble slide left, the lyrics move beside them
    property real sideT: sideMode ? 1 : 0
    Behavior on sideT { NumberAnimation { id: sideAnim; duration: 650; easing.type: Easing.OutQuint } }
    readonly property real sideGap: 32 * u
    readonly property real sideLyrW: Math.min(560 * u, width - 372 * u - sideGap - 96 * u)
    // 0 → 1 springs; the cover, the bubble, the lyrics and the clock all follow them, so they move as one
    property real artT: artMode ? 1 : 0
    Behavior on artT { NumberAnimation { id: artAnim; duration: 650; easing.type: Easing.OutQuint } }
    property real lyrT: lyricsMode ? 1 : 0
    Behavior on lyrT { NumberAnimation { id: lyrAnim; duration: 650; easing.type: Easing.OutQuint } }
    readonly property bool npAnimating: artAnim.running || lyrAnim.running || sideAnim.running
    function clamp01(v) { return Math.max(0, Math.min(1, v)); }
    // how much the clock gives way (follows the cover / lyrics ease-out)
    readonly property real squash: Math.max(artT, lyrT)
    readonly property real lyricsH: Math.min(ls.height * 0.42, 440 * ls.u)
    // vertical room above the bubble: the cover, the lyrics, or (side by side) the taller of the two
    // lyrics go UNDER the bubble when it sits in the top spot (the bubble stays put), above it in the bottom spot
    readonly property bool lyricsBelow: ls.st.mediaSlot !== "bottom"
    readonly property real panelRoom: Math.max(Math.max(0, artT) * (media.width + 24 * ls.u), lyricsBelow ? 0 : Math.max(0, lyrT) * (1 - sideT) * (lyricsH + 24 * ls.u))
    readonly property int springMs: 650
    readonly property real notifBottom: (media.on && ls.st.mediaSlot === "bottom") ? Math.min(login.y, media.y - ls.panelRoom) : login.y
    // how far the dragged bubble is pressed past its top / bottom spot (px), 0 when not dragging
    readonly property real pressTop: media.dragging ? Math.max(0, media.slotTop - (media.base + media.dragOff)) : 0
    readonly property real pressBottom: media.dragging ? Math.max(0, (media.base + media.dragOff) - media.slotBottom) : 0
    function squishK(px) { return Math.min(1, px / (70 * u)); }

    Item {
        id: media
        visible: ls.isPrimary && opacity > 0.002
        readonly property bool expanded: ls.artMode
        readonly property real bigArt: width
        width: 372 * ls.u
        height: (150 * ls.u) + ((138 * ls.u) - (150 * ls.u)) * ls.artT
        x: (ls.width - width) / 2 - ls.sideT * (ls.sideLyrW + ls.sideGap) / 2
        readonly property bool on: ls.shown && !ls.leaving && ls.hasMedia
        onOnChanged: if (!on) ls.st.npMode = ""
        // two fixed spots: under the clock, or just above the password field. Drag the card between them.
        // with the cover floating, the top spot leaves room for it between the clock and the bubble
        // computed from where the clock and the login column END UP, not where they are mid-animation
        readonly property real slotTop: 0.075 * ls.height + clock.height + 22 * ls.u + ls.panelRoom
        readonly property real slotBottom: login.y - height - 26 * ls.u
        readonly property real base: ls.st.mediaSlot === "bottom" ? slotBottom : slotTop
        property real dragOff: 0
        property bool settling: false
        readonly property bool dragging: mediaDrag.active
        y: base + dragOff
        // y only animates for real moves (cover / lyrics opening, slot changes), never while the lock appears
        property bool settled: false
        Timer { running: ls.shown; interval: 900; onTriggered: media.settled = true }
        opacity: on ? 1 : 0
        scale: !on ? 0.94 : (dragging ? 1.04 : 1)
        // the bubble squashes too where it presses into the clock / the login
        transform: Scale {
            origin.x: media.width / 2; origin.y: ls.pressTop > 0 ? 0 : media.height
            xScale: 1 + 0.05 * ls.squishK(Math.max(ls.pressTop, ls.pressBottom))
            yScale: 1 - 0.10 * ls.squishK(Math.max(ls.pressTop, ls.pressBottom))
            Behavior on xScale { enabled: !media.dragging; NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
            Behavior on yScale { enabled: !media.dragging; NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
        }
        z: dragging ? 10 : 0
        Behavior on y { enabled: media.settled && !media.dragging && !media.settling && !ls.npAnimating; NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }

        DragHandler {
            id: mediaDrag
            target: null
            xAxis.enabled: false
            cursorShape: Qt.ClosedHandCursor
            onTranslationChanged: {
                if (!active) return;
                // follow the pointer, with rubber-banding past the two spots
                var lo = media.slotTop - media.base, hi = media.slotBottom - media.base, t = translation.y;
                if (t < lo) t = lo - Math.sqrt(lo - t) * 7;
                else if (t > hi) t = hi + Math.sqrt(t - hi) * 7;
                media.dragOff = t;
            }
            onActiveChanged: {
                ls.st.poke();
                if (active) { settleAnim.stop(); return; }
                // snap to the nearer spot and remember it
                var cur = media.base + media.dragOff;
                var slot = Math.abs(cur - media.slotBottom) < Math.abs(cur - media.slotTop) ? "bottom" : "top";
                media.settling = true;
                var newBase = slot === "bottom" ? media.slotBottom : media.slotTop;
                media.dragOff = cur - newBase;
                ls.st.setMediaSlot(slot);
                settleAnim.restart();
            }
        }
        NumberAnimation {
            id: settleAnim
            target: media; property: "dragOff"; to: 0
            duration: 650; easing.type: Easing.OutQuint
            onFinished: media.settling = false
        }
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
        Behavior on scale { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }

        // keep the latest track info while fading out, so the card doesn't go blank mid-animation
        property var pl: null
        Connections { target: ls; function onPlayerChanged() { if (ls.player) media.pl = ls.player; } }
        Component.onCompleted: pl = ls.player

        Glass {
            anchors.fill: parent
            src: glassTex; frame: ls
            cornerR: 28 * ls.u; thickness: 26; tint: 0.48; shadowAmt: 0.55
        }
        HoverHandler { id: mediaHover }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6 * ls.u
            width: 34 * ls.u; height: 4 * ls.u; radius: height / 2
            color: "white"
            opacity: media.dragging ? 0.7 : (mediaHover.hovered ? 0.35 : 0)
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        // cover art
        Item {
            id: art
            // the cover leaves the glass bubble: it is drawn on the screen itself, above the bubble
            parent: ls
            z: media.z + 1
            visible: media.visible
            opacity: media.opacity
            readonly property real r: (11 * ls.u) + ((28 * ls.u) - (11 * ls.u)) * ls.artT
            x: (media.x + 16 * ls.u) + ((media.x) - (media.x + 16 * ls.u)) * ls.artT
            y: (media.y + 16 * ls.u) + ((media.y - media.bigArt - 24 * ls.u) - (media.y + 16 * ls.u)) * ls.artT
            width: (58 * ls.u) + ((media.bigArt) - (58 * ls.u)) * ls.artT
            height: width
            RectangularShadow {
                anchors.fill: parent
                radius: art.r
                blur: 40 * ls.u; spread: 0
                offset.y: 14 * ls.u
                color: Qt.rgba(0, 0, 0, 0.55)
                opacity: Math.max(0, Math.min(1, ls.artT))
            }
            Rectangle { anchors.fill: parent; radius: art.r; color: Qt.rgba(1, 1, 1, 0.12) }
            TapHandler {
                // cover tap: bubble ↔ big cover; with lyrics open the cover joins them on the left (and leaves again)
                onTapped: {
                    var m = ls.st.npMode;
                    ls.st.npMode = m === "" ? "art" : m === "art" ? "" : m === "lyrics" ? "artlyrics" : "lyrics";
                    ls.st.poke();
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            Glyph {
                visible: artImg.status !== Image.Ready
                anchors.centerIn: parent; width: 24 * ls.u; height: 24 * ls.u
                kind: "note"; color: Qt.rgba(1, 1, 1, 0.6)
            }
            ShaderEffectSource { id: covOldSrc; sourceItem: ls.coverOld; visible: false; smooth: true; mipmap: true }
            ShaderEffectSource { id: covNewSrc; sourceItem: ls.coverNew; visible: false; smooth: true; mipmap: true }
            ShaderEffect {
                id: artImg
                anchors.fill: parent
                readonly property int status: ls.coverNew.status
                visible: ls.coverUrl !== ""
                opacity: ls.coverNew.status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                fragmentShader: Qt.resolvedUrl("burn.frag.qsb")
                property variant oldTex: covOldSrc
                property variant newTex: covNewSrc
                property real progress: ls.coverProg
                property vector2d itemSize: Qt.vector2d(width, height)
                property real radius: art.r
                property real seed: ls.coverSeed
            }
            Rectangle {
                anchors.fill: parent; radius: art.r; color: "transparent"
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
            }
        }

        Column {
            id: txtCol
            x: (87 * ls.u) + ((18 * ls.u) - (87 * ls.u)) * ls.artT
            y: (16 * ls.u + (58 * ls.u - height) / 2) + ((16 * ls.u) - (16 * ls.u + (58 * ls.u - height) / 2)) * ls.artT
            width: media.width - x - 18 * ls.u
            spacing: 2 * ls.u
            MorphText {
                width: parent.width; elide: Text.ElideRight
                text: media.pl ? (media.pl.trackTitle || "") : ""
                horizontalAlignment: media.expanded ? Text.AlignHCenter : Text.AlignLeft
                color: "white"; font.family: ls.fam; font.pixelSize: 15 * ls.u; font.weight: Font.DemiBold; animateWidth: false
            }
            MorphText {
                width: parent.width; elide: Text.ElideRight
                text: media.pl ? (media.pl.trackArtist || media.pl.identity || "") : ""
                horizontalAlignment: media.expanded ? Text.AlignHCenter : Text.AlignLeft
                color: Qt.rgba(1, 1, 1, 0.66); font.family: ls.fam; font.pixelSize: 13 * ls.u; animateWidth: false
            }
        }

        // scrubber
        Item {
            id: scrub
            x: 18 * ls.u; width: parent.width - 36 * ls.u
            y: (88 * ls.u) + ((txtCol.y + txtCol.height + 10 * ls.u) - (88 * ls.u)) * ls.artT
            height: 16 * ls.u
            readonly property real len: media.pl && media.pl.lengthSupported ? media.pl.length : 0
            property real pos: 0
            readonly property real frac: len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
            function fmt(s) { s = Math.max(0, Math.floor(s)); var m = Math.floor(s / 60), r = s % 60; return m + ":" + (r < 10 ? "0" : "") + r; }
            Timer {
                interval: 500; repeat: true; triggeredOnStart: true
                running: media.visible && media.pl !== null
                onTriggered: {
                    if (!media.pl) return;
                    if (media.pl.positionSupported) {
                        media.pl.positionChanged(); scrub.pos = media.pl.position;
                        ls.posBase = scrub.pos; ls.posAt = Date.now(); ls.posPlaying = media.pl.isPlaying;
                    }
                }
            }
            Text {
                id: tL
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: scrub.fmt(scrub.pos)
                color: Qt.rgba(1, 1, 1, 0.6); font.family: ls.fam; font.pixelSize: 11 * ls.u; font.features: { "tnum": 1 }
            }
            Text {
                id: tR
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: scrub.len > 0 ? "-" + scrub.fmt(scrub.len - scrub.pos) : "--:--"
                color: Qt.rgba(1, 1, 1, 0.6); font.family: ls.fam; font.pixelSize: 11 * ls.u; font.features: { "tnum": 1 }
            }
            Item {
                id: bar
                anchors.left: tL.right; anchors.right: tR.left
                anchors.leftMargin: 10 * ls.u; anchors.rightMargin: 10 * ls.u
                anchors.verticalCenter: parent.verticalCenter
                height: (barMa.containsMouse || barMa.pressed ? 8 : 5) * ls.u
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
                Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.22) }
                Rectangle {
                    height: parent.height; radius: height / 2
                    width: Math.max(height, parent.width * scrub.frac)
                    color: Qt.rgba(1, 1, 1, 0.88)
                    Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.Linear } }
                }
                MouseArea {
                    id: barMa
                    anchors.fill: parent; anchors.margins: -8
                    hoverEnabled: true
                    enabled: media.pl !== null && media.pl.canSeek && scrub.len > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        var f = Math.max(0, Math.min(1, (mouse.x - 8) / bar.width));
                        media.pl.position = f * scrub.len;
                        scrub.pos = f * scrub.len;
                        ls.posBase = scrub.pos; ls.posAt = Date.now();
                    }
                }
            }
        }

        // lyrics button (Apple's quote bubble), right of the controls
        Item {
            id: lyrBtn
            x: media.width - 16 * ls.u - width
            y: scrub.y + scrub.height + 6 * ls.u
            width: 32 * ls.u; height: 34 * ls.u
            readonly property bool active: ls.st.npMode === "lyrics" || ls.st.npMode === "artlyrics"
            opacity: ls.lyrStatus === "none" || ls.lyrStatus === "instrumental" ? 0.4 : 1
            Rectangle {
                anchors.centerIn: parent
                width: 30 * ls.u; height: width; radius: 9 * ls.u
                color: lyrBtn.active ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(1, 1, 1, lyrMa.containsMouse ? 0.14 : 0)
                scale: lyrMa.pressed ? 0.88 : 1
                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
                Canvas {
                    id: quoteIcon
                    anchors.centerIn: parent
                    width: 18 * ls.u; height: width
                    property color ink: lyrBtn.active ? "#1c1c1e" : "white"
                    onInkChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var c = getContext("2d"); c.reset();
                        var s = width / 18; c.scale(s, s);
                        c.fillStyle = ink; c.strokeStyle = ink; c.lineWidth = 1.5; c.lineJoin = "round";
                        // speech bubble
                        c.beginPath();
                        c.moveTo(4.5, 2.5); c.lineTo(13.5, 2.5); c.arcTo(16, 2.5, 16, 5, 2.5); c.lineTo(16, 10.5); c.arcTo(16, 13, 13.5, 13, 2.5);
                        c.lineTo(8, 13); c.lineTo(4.6, 15.8); c.lineTo(4.6, 13); c.arcTo(2, 13, 2, 10.5, 2.5); c.lineTo(2, 5); c.arcTo(2, 2.5, 4.5, 2.5, 2.5);
                        c.closePath(); c.stroke();
                        // quote marks
                        function q(x) { c.beginPath(); c.arc(x, 7, 1.35, 0, Math.PI * 2); c.fill(); c.beginPath(); c.moveTo(x + 1.2, 7); c.quadraticCurveTo(x + 1.3, 9.6, x - 0.6, 10.4); c.stroke(); }
                        q(6.6); q(10.8);
                    }
                }
            }
            MouseArea {
                id: lyrMa
                anchors.fill: parent; anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // lyrics button: with the cover enlarged the cover slides left and the lyrics appear beside it
                    var m = ls.st.npMode;
                    ls.st.npMode = m === "" ? "artlyrics" : m === "lyrics" || m === "artlyrics" ? "" : "artlyrics";
                    if (ls.lyricsMode && (ls.lyrStatus === "idle" || ls.lyrStatus === "none")) ls.fetchLyrics();
                    ls.st.poke();
                }
            }
        }

        // transport controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: scrub.y + scrub.height + 6 * ls.u
            spacing: 26 * ls.u
            Repeater {
                model: ["prev", "play", "next"]
                delegate: Item {
                    id: tb
                    required property string modelData
                    readonly property bool big: modelData === "play"
                    width: (big ? 38 : 32) * ls.u; height: 34 * ls.u
                    readonly property bool can: media.pl !== null && (modelData === "prev" ? media.pl.canGoPrevious
                                                : modelData === "next" ? media.pl.canGoNext : media.pl.canTogglePlaying)
                    opacity: can ? 1 : 0.35
                    // glass halo on hover
                    Rectangle {
                        anchors.centerIn: parent
                        width: 40 * ls.u; height: width; radius: width / 2
                        color: Qt.rgba(1, 1, 1, tma.pressed ? 0.20 : 0.12)
                        opacity: tma.containsMouse ? 1 : 0
                        scale: tma.containsMouse ? 1 : 0.6
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
                    }
                    MorphGlyph {
                        anchors.centerIn: parent
                        width: (tb.big ? 26 : 22) * ls.u; height: width
                        kind: tb.modelData === "play" ? (media.pl && media.pl.isPlaying ? "pause" : "play") : tb.modelData
                        color: "white"
                        scale: tma.pressed ? 0.84 : 1
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
                    }
                    MouseArea {
                        id: tma
                        anchors.fill: parent; anchors.margins: -4
                        hoverEnabled: true
                        enabled: tb.can
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tb.modelData === "prev") media.pl.previous();
                            else if (tb.modelData === "next") media.pl.next();
                            else media.pl.togglePlaying();
                        }
                    }
                }
            }
        }
    }

    // ═════════════ LYRICS (Apple Music style) ═════════════
    // estimated playback position: MPRIS is polled twice a second, the lyrics need it smooth
    property real posBase: 0
    property real posAt: 0
    property bool posPlaying: false
    property real estPos: 0
    Timer {
        interval: 50; repeat: true
        running: ls.lyricsMode || ls.lyrT > 0.01
        onTriggered: ls.estPos = ls.posBase + (ls.posPlaying ? (Date.now() - ls.posAt) / 1000 : 0)
    }

    // Spotify Canvas: short looping video artwork for supported tracks
    property string canvasVideo: ""
    readonly property string spotifyTrackId: {
        if (!media.pl) return "";
        // MPRIS trackId is often a generic D-Bus object path; do not let it mask the Spotify URL.
        // Quickshell's MprisPlayer has no trackId / url property: the raw MPRIS fields live in `metadata`
        var md = media.pl.metadata || {};
        var candidates = [String(md["xesam:url"] || ""), String(md["mpris:trackid"] || ""), String(media.pl.uniqueId || "")];
        for (var i = 0; i < candidates.length; i++) {
            var m = candidates[i].match(/(?:spotify:track:|open\.spotify\.com\/track\/|\/com\/spotify\/track\/)([a-zA-Z0-9]{22})/i);
            if (m) return m[1];
        }
        return "";
    }
    onTrackKeyChanged: { lyrFetchDelay.restart(); canvasDelay.restart(); }
    Timer {
        id: canvasDelay; interval: 500
        onTriggered: {
            ls.canvasVideo = "";
            if (media.pl && (ls.spotifyTrackId !== "" || (media.pl.identity || "").toLowerCase().indexOf("spotify") >= 0)) {
                canvasProc.running = false;
                var arg = ls.spotifyTrackId !== "" ? ls.spotifyTrackId : ((media.pl.trackArtist || "") + " " + (media.pl.trackTitle || ""));
                canvasProc.command = ["python3", Quickshell.shellDir + "/assets/lockscreen/spotify-canvas.py", arg];
                canvasProc.running = true;
            }
        }
    }
    Process {
        id: canvasProc
        stdout: StdioCollector {
            onStreamFinished: {
                var p = (text || "").trim();
                if (p.length > 0) ls.canvasVideo = p;
            }
        }
    }

    // lyrics for the current track: NetEase, LRCLIB, and Genius, cached in ~/.cache/lickintosh/lyrics
    property var lyrLines: []              // [{ t: seconds (-1 = unsynced), text }]
    property string lyrStatus: "idle"      // idle | loading | synced | plain | none
    readonly property string trackKey: media.pl ? (media.pl.trackArtist || "") + "\u0001" + (media.pl.trackTitle || "") : ""
    Timer { id: lyrFetchDelay; interval: 400; onTriggered: { ls.lyrTries = 0; ls.fetchLyrics(); } }
    property int lyrTries: 0
    Timer { id: lyrRetry; interval: 12000; onTriggered: ls.fetchLyrics() }
    function fetchLyrics() {
        if (!ls.isPrimary || !media.pl || !(media.pl.trackTitle || "")) { lyrLines = []; lyrStatus = "idle"; return; }
        lyrLines = []; lyrStatus = "loading";
        var len = media.pl.lengthSupported ? Math.round(media.pl.length) : 0;
        lyrProc.running = false;
        lyrProc.command = ["sh", "-c", ls.lyrScript, "sh", media.pl.trackArtist || "", media.pl.trackTitle || "", media.pl.trackAlbum || "", len > 0 ? String(len) : ""];
        lyrProc.running = true;
    }
    readonly property string lyrScript: [
        'a="$1"; t="$2"; al="$3"; d="${4:-0}"; c="$HOME/.cache/lickintosh/lyrics"; mkdir -p "$c"',
        'k=$(printf "%s|%s" "$a" "$t" | md5sum | cut -c1-16); f="$c/$k.json"',
        '[ -s "$f" ] && { cat "$f"; exit 0; }',
        'tmp=$(mktemp); answered=0; r=""',
        // titles like "Song (feat. X)" / "Song - Remastered 2011": also try the bare title
        'bare=$(printf "%s" "$t" | sed -E "s/ *[(\\[][^)\\]]*[)\\]]//g; s/ +- +(.*[Rr]emaster.*|[Ll]ive.*|[Rr]adio [Ee]dit.*)$//")',
        // ── 1. NetEase Cloud Music: fast, not rate-limited. Same title + same length (±4 s) or it doesn't count.
        'ne() { code=$(curl -s --max-time 6 -A "Mozilla/5.0" -o "$tmp" -w "%{http_code}" -G "https://music.163.com/api/search/get" --data-urlencode "s=$1" -d type=1 -d limit=10); [ "$code" = 200 ] || return 1; answered=1',
        '  id=$(jq -r --arg t "$bare" --argjson d "$d" \'def n: ascii_downcase | gsub("[^\\\\p{L}\\\\p{N}]"; ""); ($t | n) as $q | [.result.songs[]? | select((.name | n) as $nm | ($nm == $q) or ($nm | startswith($q)) or ($q | startswith($nm))) | select($d == 0 or (((.duration / 1000) - $d) | fabs) <= 4)][0].id // empty\' "$tmp")',
        '  [ -n "$id" ] || return 1',
        '  curl -s --max-time 6 -A "Mozilla/5.0" -o "$tmp" "https://music.163.com/api/song/lyric?id=$id&lv=1" || return 1',
        '  l=$(jq -r ".lrc.lyric // empty" "$tmp"); case "$l" in *"[0"*|*"[1"*) ;; *) return 1;; esac',
        '  r=$(jq -nc --arg l "$l" "{syncedLyrics: \\$l}"); }',
        'ne "$a $bare" || ne "$bare"',
        // ── 2. LRCLIB (rate-limited per second: wait and retry briefly), length-checked too
        'ua="lickintosh/1.0 (https://github.com/kelian-4/lickintosh)"; api=https://lrclib.net/api',
        'req() { n=0; while [ $n -lt 2 ]; do code=$(curl -s --max-time 8 -A "$ua" -o "$tmp" -w "%{http_code}" -G "$@"); case "$code" in 200) answered=1; return 0;; 404) answered=1; return 1;; 429) n=$((n+1)); sleep 1.5;; *) return 1;; esac; done; return 1; }',
        'pick=\'[.[] | select(.syncedLyrics != null or .plainLyrics != null) | select($d == 0 or (((.duration // 0) - $d) | fabs) <= 4)] | ([.[] | select(.syncedLyrics != null)][0] // .[0]) // empty\'',
        'lsearch() { req "$api/search" "$@" && r=$(jq -c --argjson d "$d" "$pick" "$tmp"); }',
        '[ -z "$r" ] && lsearch --data-urlencode "track_name=$t" --data-urlencode "artist_name=$a"',
        '[ -z "$r" ] && [ "$bare" != "$t" ] && lsearch --data-urlencode "track_name=$bare" --data-urlencode "artist_name=$a"',
        '[ -z "$r" ] && lsearch --data-urlencode "q=$a $bare"',
        'rm -f "$tmp"',
        // ── 3. Genius: token-free, rich lyrics source
        'if [ -z "$r" ] || [ "$(printf "%s" "$r" | jq -r ".syncedLyrics // empty" 2>/dev/null)" = "" ]; then',
        '  g=$(python3 "' + Quickshell.shellDir + '/assets/lockscreen/genius-lyrics.py" "$a" "$bare" "$c" 2>/dev/null || true)',
        '  if [ -n "$g" ] && [ "$g" != "{}" ]; then',
        '    gp=$(printf "%s" "$g" | jq -r ".plain // empty" 2>/dev/null)',
        '    if [ -n "$gp" ]; then r=$(jq -nc --arg p "$gp" "{plainLyrics: \\$p}"); answered=1; fi',
        '  fi',
        'fi',
        'if [ -n "$r" ]; then printf "%s" "$r" | jq -c "{synced: .syncedLyrics, plain: .plainLyrics, instrumental: .instrumental}" | tee "$f"',
        // a source really answered and nobody has it: remember; otherwise (offline / still limited) let the UI retry
        'elif [ "$answered" = 1 ]; then echo "{}" | tee "$f"',
        'else echo "{\\"retry\\":true}"; fi'
    ].join("\n")
    Process {
        id: lyrProc
        stdout: StdioCollector {
            onStreamFinished: {
                var o = {};
                try { o = JSON.parse(text || "{}"); } catch (e) { o = {}; }
                var out = [], i, m;
                if (o.synced) {
                    var ls2 = o.synced.split("\n");
                    for (i = 0; i < ls2.length; i++) {
                        var line = ls2[i], tags = [], re = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
                        while ((m = re.exec(line)) !== null) tags.push(parseInt(m[1]) * 60 + parseFloat(m[2]));
                        var txt = line.replace(/\[[^\]]*\]/g, "").trim();
                        if (/^(制作人|作词|作曲|编曲|混音|母带|制作|和声|吉他|贝斯|鼓|录音|监制|出品|发行|OP|SP|Producer|Lyricist|Composer|Lyrics|Composed|Written)\s*[:：]/i.test(txt)) continue;
                        for (var j = 0; j < tags.length; j++) out.push({ t: tags[j], text: txt });
                    }
                    out.sort(function (a, b) { return a.t - b.t; });
                    ls.lyrLines = out; ls.lyrStatus = out.length > 0 ? "synced" : "none";
                } else if (o.plain) {
                    var pl = o.plain.split("\n");
                    for (i = 0; i < pl.length; i++) out.push({ t: -1, text: pl[i].trim() });
                    ls.lyrLines = out; ls.lyrStatus = "plain";
                } else if (o.retry) {
                    // rate-limited / offline: try again shortly (a few times)
                    if (ls.lyrTries < 4) { ls.lyrTries++; ls.lyrStatus = "loading"; lyrRetry.restart(); }
                    else { ls.lyrLines = []; ls.lyrStatus = "offline"; }
                } else if (o.instrumental) {
                    ls.lyrLines = []; ls.lyrStatus = "instrumental";
                } else {
                    ls.lyrLines = []; ls.lyrStatus = "none";
                }
            }
        }
    }

    // current line (a hair early, like Apple Music)
    readonly property int lyrCur: {
        if (lyrStatus !== "synced") return -1;
        var p = estPos + 0.25, c = -1;
        for (var i = 0; i < lyrLines.length; i++) { if (lyrLines[i].t <= p) c = i; else break; }
        return c;
    }

    Item {
        id: lyr
        visible: ls.lyrT > 0.01 && media.visible
        // lines past the feathered edges are cut off for real: not drawn and not clickable (they used to sit invisibly
        // over the media controls and swallow clicks)
        clip: true
        z: media.z + 1
        readonly property real wTop: Math.min(ls.width - 80 * ls.u, 620 * ls.u)
        readonly property real hSide: media.width + 24 * ls.u + media.height
        // lyrics-only: below the bubble (top spot, filling the room down to the password field) or above it (bottom spot)
        readonly property real belowY: media.y + media.height + 24 * ls.u
        readonly property real belowH: Math.max(140 * ls.u, Math.min(ls.lyricsH, (login.y - 24 * ls.u) - belowY))
        readonly property real soloH: ls.lyricsBelow ? belowH : ls.lyricsH
        readonly property real soloY: ls.lyricsBelow ? belowY : media.y - ls.lyricsH - 24 * ls.u
        readonly property real sideY: media.y - media.width - 24 * ls.u
        width: wTop + (ls.sideLyrW - wTop) * ls.sideT
        height: soloH + (hSide - soloH) * ls.sideT
        x: (ls.width - wTop) / 2 + ((media.x + media.width + ls.sideGap) - (ls.width - wTop) / 2) * ls.sideT
        y: soloY + (sideY - soloY) * ls.sideT
        opacity: ls.clamp01(ls.lyrT) * media.opacity
        scale: 0.94 + 0.06 * ls.lyrT
        transformOrigin: ls.sideMode ? Item.Left : (ls.lyricsBelow ? Item.Top : Item.Bottom)

        // manual scroll (wheel); synced lyrics snap back to the current line a few seconds later
        property real manual: 0
        Timer { id: manualReset; interval: 3500; onTriggered: if (ls.lyrStatus === "synced") lyr.manual = 0 }
        WheelHandler {
            onWheel: ev => { lyr.manual = Math.max(-200 * ls.u, lyr.manual - ev.angleDelta.y * 0.6); manualReset.restart(); ls.st.poke(); }
        }
        Behavior on manual { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }

        // where the column scrolls to: the current line sits about a third of the way down
        readonly property real target: {
            var it = ls.lyrCur >= 0 ? lyrRep.itemAt(ls.lyrCur) : null;
            var base = it ? it.y - height * 0.30 : -height * 0.30;
            return base + manual;
        }

        // the lines, faded out at the top and bottom edges
        Item {
            id: lyrView
            anchors.fill: parent
            clip: true
            layer.enabled: true
            layer.effect: ShaderEffect {
                fragmentShader: Qt.resolvedUrl("fade.frag.qsb")
                property real fadeTop: 0.24
                property real fadeBottom: 0.30
            }
            Column {
                id: lyrCol
                width: parent.width
                spacing: 20 * ls.u
                Repeater {
                    id: lyrRep
                    model: ls.lyrLines
                    delegate: Item {
                        id: ln
                        required property var modelData
                        required property int index
                        readonly property int rel: ls.lyrCur < 0 ? 0 : index - ls.lyrCur
                        readonly property bool cur: ls.lyrStatus === "synced" && index === ls.lyrCur
                        readonly property bool gap: (modelData.text || "") === ""
                        width: lyrCol.width
                        height: gap ? 34 * ls.u : lt.implicitHeight
                        // Apple Music's wave: every line follows the scroll on its own spring, lines further down a little later
                        transform: Translate {
                            id: lnTr
                            y: -lyr.target
                            Behavior on y { NumberAnimation { duration: 500 + Math.max(0, Math.min(8, ln.rel)) * 20; easing.type: Easing.OutQuint } }
                        }
                        opacity: ls.lyrStatus !== "synced" ? 0.9 : (cur ? 1 : (Math.abs(rel) === 1 ? 0.42 : 0.26))
                        Behavior on opacity { NumberAnimation { duration: 380 } }
                        Text {
                            id: lt
                            visible: !ln.gap
                            width: parent.width
                            text: ln.modelData.text
                            wrapMode: Text.WordWrap
                            color: "white"
                            font.family: ls.fam; font.pixelSize: 31 * ls.u; font.weight: Font.Bold
                            lineHeight: 1.08
                            transformOrigin: Item.Left
                            scale: ln.cur || ls.lyrStatus !== "synced" ? 1 : 0.965
                            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
                            // lines away from the current one go soft, like Apple Music (only near lines get a blur layer)
                            layer.enabled: ls.lyrStatus === "synced" && !ln.cur && Math.abs(ln.rel) <= 6
                            layer.effect: MultiEffect { blurEnabled: true; blurMax: 16; blur: Math.min(0.55, 0.14 * Math.abs(ln.rel)) }
                        }
                        // instrumental break: three breathing dots
                        Row {
                            visible: ln.gap
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 9 * ls.u
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    width: 11 * ls.u; height: width; radius: width / 2
                                    color: "white"
                                    opacity: ln.cur ? 0.95 : 0.35
                                    SequentialAnimation on scale {
                                        running: ln.cur; loops: Animation.Infinite
                                        PauseAnimation { duration: index * 160 }
                                        NumberAnimation { from: 0.7; to: 1.15; duration: 520; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 1.15; to: 0.7; duration: 520; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                        // tap a line to jump there
                        // where this line is on screen right now (after the scroll), to ignore lines in / past the feather
                        readonly property real shownY: y + lnTr.y
                        readonly property bool inBand: shownY + height > lyr.height * 0.20 && shownY < lyr.height * 0.74
                        TapHandler {
                            enabled: ln.inBand && ls.lyrStatus === "synced" && media.pl && media.pl.canSeek
                            onTapped: {
                                media.pl.position = ln.modelData.t;
                                ls.posBase = ln.modelData.t; ls.posAt = Date.now(); scrub.pos = ln.modelData.t;
                                lyr.manual = 0; ls.st.poke();
                            }
                        }
                        HoverHandler { enabled: ln.inBand && ls.lyrStatus === "synced"; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
        MorphText {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            visible: ls.lyrStatus === "loading" || ls.lyrStatus === "none" || ls.lyrStatus === "instrumental" || ls.lyrStatus === "offline"
            text: ls.lyrStatus === "loading" ? I18n.tr("Loading lyrics…") : (ls.lyrStatus === "instrumental" ? I18n.tr("Instrumental")
                  : (ls.lyrStatus === "offline" ? "Lyrics are unavailable right now" : "No lyrics for this song"))
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: ls.fam; font.pixelSize: 20 * ls.u; font.weight: Font.DemiBold
        }
    }
}
