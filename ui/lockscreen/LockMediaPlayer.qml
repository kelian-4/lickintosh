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
    implicitHeight: visible ? 150 : 0

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
    Component.onDestruction: if (root.visible) MprisState.watchPosition(false)

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
            x: 16
            y: 16
            width: 58
            height: 58
            r: 11
            source: root.fileUrl(MprisState.artUrl)
        }

        Column {
            x: 87
            y: 16 + (58 - height) / 2
            width: pill.width - x - 18
            spacing: 2

            Text {
                width: parent.width
                text: MprisState.trackTitle.length > 0 ? MprisState.trackTitle : I18n.tr("Not Playing")
                elide: Text.ElideRight
                color: "white"
                font.family: root.fam
                font.pixelSize: 15
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            MarqueeText {
                width: parent.width
                text: MprisState.trackArtist.length > 0 ? MprisState.trackArtist : MprisState.identity
                color: Qt.rgba(1, 1, 1, 0.66)
                fam: root.fam
                pixelSize: 13
                weight: Font.Normal
                fade: 14
                animate: MprisState.isPlaying
            }
        }

        Item {
            id: scrub
            x: 18
            y: 88
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
    }
}
