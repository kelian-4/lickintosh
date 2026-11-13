import QtQuick
import Quickshell.Services.Pipewire
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
    readonly property color trackCol: root.fa(root.dark ? 0.14 : 0.10)
    readonly property color fillCol: root.fa(root.dark ? 0.58 : 0.50)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink !== null && root.sink.audio !== null
    readonly property real level: root.ready ? Number(root.sink.audio.volume) : 0
    readonly property bool muted: root.ready && root.sink.audio.muted
    readonly property real shownLevel: root.muted ? 0 : Math.max(0, Math.min(1, root.level))
    readonly property int speakerLevel: root.shownLevel <= 0 ? 0 : (root.shownLevel < 0.5 ? 1 : 2)
    readonly property string deviceName: root.ready ? (root.sink.description !== "" ? root.sink.description : root.sink.name) : ""
    readonly property string valueText: root.muted ? I18n.tr("Muted") : Math.round(root.level * 100) + "%"

    PwObjectTracker {
        objects: [root.sink]
    }

    function setLevel(value) {
        if (!root.ready) return
        root.sink.audio.muted = false
        root.sink.audio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (root.ready) root.sink.audio.muted = !root.sink.audio.muted
    }

    ExtraABtn {
        x: root.mx * root.k
        y: (root.isLarge ? 118 : 22) * root.k
        width: (root.isLarge ? 130 : 46) * root.k
        height: width
        fillColor: root.fa(root.dark ? 0.12 : 0.08)
        col: root.fgBtn
        xglyph: "speaker"
        level: root.speakerLevel
        gw: (root.isLarge ? 56 : 24) * root.k
        gh: gw
        onClicked: root.toggleMute()
    }

    Text {
        visible: root.isSmall
        x: (root.mx + 46 + 6) * root.k
        y: 22 * root.k
        width: (root.wr - 2 * root.mx - 46 - 6) * root.k
        height: 46 * root.k
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: root.valueText
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 24 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isSmall
        x: root.mx * root.k
        y: 84 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 28 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Volume")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 20 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isSmall
        x: root.mx * root.k
        y: 112 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 22 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.deviceName
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 15 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isMedium
        x: (root.mx + 46 + 12) * root.k
        y: 20 * root.k
        width: (root.wr - 2 * root.mx - 46 - 12 - 120) * root.k
        height: 28 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Volume")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 20 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isMedium
        x: (root.mx + 46 + 12) * root.k
        y: 48 * root.k
        width: (root.wr - 2 * root.mx - 46 - 12 - 120) * root.k
        height: 22 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.deviceName
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 15 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isMedium
        x: (root.wr - root.mx - 110) * root.k
        y: 22 * root.k
        width: 110 * root.k
        height: 46 * root.k
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: root.valueText
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 26 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isLarge
        x: root.mx * root.k
        y: 21 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 30 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Volume")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 22 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isLarge
        x: root.mx * root.k
        y: 52 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 24 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.deviceName
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 16 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isLarge
        x: (root.mx + 130 + 14) * root.k
        y: 118 * root.k
        width: (root.wr - 2 * root.mx - 130 - 14) * root.k
        height: 130 * root.k
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: root.valueText
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 56 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    ExtraAGlyph {
        visible: !root.isSmall
        x: root.mx * root.k
        y: (root.isLarge ? 334 : 138) * root.k
        width: 22 * root.k
        height: width
        kind: "speaker"
        level: 0
        color: root.fg2
    }

    ExtraAGlyph {
        visible: !root.isSmall
        x: (root.wr - root.mx - 22) * root.k
        y: (root.isLarge ? 334 : 138) * root.k
        width: 22 * root.k
        height: width
        kind: "speaker"
        level: 2
        color: root.fg2
    }

    ExtraASlider {
        x: (root.isSmall ? 9 : 23 + 22 + 4 - 14) * root.k
        y: (root.isLarge ? 332 : (root.isMedium ? 136 : 152)) * root.k
        width: (root.isSmall ? root.wr - 18 : root.wr - 2 * (23 + 22 + 4 - 14)) * root.k
        u: root.k
        value: root.shownLevel
        fillColor: root.fillCol
        trackColor: root.trackCol
        knobColor: "white"
        enabled: root.ready
        onMoved: function(v) { root.setLevel(v) }
    }
}
