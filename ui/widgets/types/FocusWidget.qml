import QtQuick
import qs.services
import qs.ui.widgets

Item {
    id: root

    property var look: null

    property string size: "s"

    readonly property bool fullBleed: true
    readonly property bool isSmall: root.size === "s"
    readonly property bool isMedium: root.size === "m"
    readonly property bool isLarge: root.size === "l"
    readonly property bool dark: root.look ? !root.look.light : true
    readonly property string fam: "SF Pro Text"

    readonly property real k: root.isSmall ? root.width / 202 : (root.isMedium ? root.height / 202 : root.width / 446)
    readonly property real wr: root.width / root.k
    readonly property real hr: root.height / root.k
    readonly property real mx: 23

    function fa(a) { return root.dark ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a) }
    readonly property color fg: root.fa(root.dark ? 0.90 : 0.86)
    readonly property color fg2: root.fa(root.dark ? 0.52 : 0.50)
    readonly property color fgBtn: root.fa(root.dark ? 0.78 : 0.72)
    readonly property color trackCol: root.fa(root.dark ? 0.16 : 0.10)

    readonly property bool working: PomodoroState.phase === "work"
    readonly property color phaseColor: root.working ? "#ff453a" : "#30d158"
    readonly property string phaseText: root.working ? I18n.tr("Focus") : I18n.tr("Break")
    readonly property real phaseMs: PomodoroState._phaseDurationMs(PomodoroState.phase)
    readonly property real elapsed: root.phaseMs > 0 ? Math.max(0, Math.min(1, 1 - PomodoroState.remainingMs / root.phaseMs)) : 0
    readonly property string cycleText: I18n.tr("Cycle %1 of %2").replace("%1", (PomodoroState.cyclesCompleted % PomodoroState.cyclesBeforeLongBreak) + 1).replace("%2", PomodoroState.cyclesBeforeLongBreak)
    readonly property string remainingText: TimerState.formatRemaining(PomodoroState.remainingMs)

    readonly property real ringSize: root.isSmall ? 112 : (root.isMedium ? 136 : 250)
    readonly property real ringX: root.isSmall ? (root.wr - root.ringSize) / 2 : (root.isMedium ? root.mx : (root.wr - root.ringSize) / 2)
    readonly property real ringY: root.isSmall ? 16 : (root.isMedium ? (root.hr - root.ringSize) / 2 : 36)

    ExtraARing {
        x: root.ringX * root.k
        y: root.ringY * root.k
        width: root.ringSize * root.k
        height: width
        percent: root.elapsed * 100
        tint: root.phaseColor
        trackColor: root.trackCol
        lineWidth: (root.isLarge ? 10 : 7) * root.k
        showValue: false
        fam: root.fam
    }

    Text {
        x: (root.ringX + root.ringSize * 0.12) * root.k
        y: (root.ringY + root.ringSize * 0.5 - (root.isLarge ? 54 : (root.isMedium ? 36 : 30))) * root.k
        width: root.ringSize * 0.76 * root.k
        height: (root.isLarge ? 28 : 20) * root.k
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.phaseText
        elide: Text.ElideRight
        color: root.phaseColor
        font.family: root.fam
        font.pixelSize: (root.isLarge ? 21 : 14) * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        x: (root.ringX + root.ringSize * 0.1) * root.k
        y: (root.ringY + root.ringSize * 0.5 - (root.isLarge ? 24 : (root.isMedium ? 14 : 10))) * root.k
        width: root.ringSize * 0.8 * root.k
        height: (root.isLarge ? 66 : (root.isMedium ? 40 : 34)) * root.k
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.remainingText
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: (root.isLarge ? 58 : (root.isMedium ? 34 : 28)) * root.k
        font.weight: Font.Light
        renderType: Text.NativeRendering
    }

    Text {
        visible: !root.isSmall
        x: (root.isMedium ? root.ringX + root.ringSize + 26 : root.mx) * root.k
        y: (root.isMedium ? 30 : 308) * root.k
        width: (root.isMedium ? root.wr - root.mx - (root.ringX + root.ringSize + 26) : root.wr - 2 * root.mx) * root.k
        height: 24 * root.k
        horizontalAlignment: root.isMedium ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.cycleText
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 16 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    ExtraABtn {
        id: playBtn
        x: (root.isSmall ? root.wr / 2 - 52 : (root.isMedium ? root.ringX + root.ringSize + 26 : root.wr / 2 - 112)) * root.k
        y: (root.isSmall ? 142 : (root.isMedium ? 100 : 350)) * root.k
        width: (root.isLarge ? 64 : 46) * root.k
        height: width
        fillColor: Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, root.dark ? 0.30 : 0.22)
        col: root.phaseColor
        glyph: PomodoroState.running ? "pause" : "play"
        gw: (root.isLarge ? 26 : 19) * root.k
        gh: (root.isLarge ? 30 : 22) * root.k
        onClicked: PomodoroState.running ? PomodoroState.pause() : PomodoroState.start()
    }

    ExtraABtn {
        visible: !root.isSmall
        x: playBtn.x + playBtn.width + 16 * root.k
        y: playBtn.y + (playBtn.height - height) / 2
        width: (root.isLarge ? 64 : 46) * root.k
        height: width
        fillColor: root.fa(root.dark ? 0.12 : 0.08)
        col: root.fgBtn
        glyph: "next"
        gw: (root.isLarge ? 28 : 20) * root.k
        gh: (root.isLarge ? 24 : 18) * root.k
        onClicked: PomodoroState.skip()
    }

    ExtraABtn {
        x: (root.isSmall ? playBtn.x / root.k + 46 + 16 : playBtn.x / root.k + (root.isLarge ? 64 + 16 + 64 + 16 : 46 + 16 + 46 + 16)) * root.k
        y: playBtn.y + (playBtn.height - height) / 2
        width: (root.isLarge ? 64 : 46) * root.k
        height: width
        fillColor: root.fa(root.dark ? 0.12 : 0.08)
        col: root.fgBtn
        xglyph: "reset"
        gw: (root.isLarge ? 28 : 20) * root.k
        gh: gw
        onClicked: PomodoroState.reset()
    }
}
