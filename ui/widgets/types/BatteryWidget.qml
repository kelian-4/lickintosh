import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
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
    readonly property color trackCol: root.fa(root.dark ? 0.16 : 0.10)
    readonly property color lineCol: root.fa(root.dark ? 0.16 : 0.12)

    readonly property bool present: UPower.displayDevice.isLaptopBattery
    readonly property real fraction: root.present ? UPower.displayDevice.percentage : 1
    readonly property bool charging: UPower.onBattery ? UPower.displayDevice.state === 1 : true
    readonly property color level: root.fraction <= 0.15 ? "#ff453a" : (root.fraction <= 0.3 ? "#ff9f0a" : "#30d158")
    readonly property string stateText: !root.present ? I18n.tr("Plugged in") : (root.charging ? I18n.tr("Charging") : I18n.tr("On battery"))
    readonly property real timeSeconds: root.charging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty
    readonly property string timeText: root.present && root.timeSeconds > 0 ? root.duration(root.timeSeconds) : "—"
    readonly property real freeGb: Math.max(0, ResourcesState.memoryTotalGb - ResourcesState.memoryUsedGb)
    readonly property real diskFreeGb: Math.max(0, ResourcesState.storageTotalGb - ResourcesState.storageUsedGb)
    readonly property bool wantsTop: root.size === "l"
    property bool registered: false

    function duration(seconds) {
        var minutes = Math.round(seconds / 60)
        var hours = Math.floor(minutes / 60)
        return hours > 0 ? hours + "h " + (minutes % 60) + "m" : minutes + "m"
    }

    function memory(mb) {
        return mb >= 1024 ? (mb / 1024).toFixed(2) + " GB" : mb.toFixed(1) + " MB"
    }

    function sync() {
        if (root.wantsTop && !root.registered) {
            ResourcesState.topMemoryWatchers++
            root.registered = true
        } else if (!root.wantsTop && root.registered) {
            ResourcesState.topMemoryWatchers--
            root.registered = false
        }
    }

    onWantsTopChanged: root.sync()
    Component.onCompleted: root.sync()
    Component.onDestruction: {
        if (root.registered) ResourcesState.topMemoryWatchers--
    }

    readonly property var rows: [
        { name: I18n.tr("Battery"), pct: root.fraction * 100, tint: root.level, bolt: root.present && root.charging },
        { name: I18n.tr("Memory"), pct: ResourcesState.memoryPercent, tint: "#30d158", bolt: false },
        { name: "CPU", pct: ResourcesState.cpuPercent, tint: "#64d2ff", bolt: false },
        { name: I18n.tr("Storage"), pct: ResourcesState.storagePercent, tint: "#ff9f0a", bolt: false }
    ]

    readonly property var rings: [
        { cap: I18n.tr("BAT"), pct: root.fraction * 100, tint: root.level },
        { cap: I18n.tr("CPU"), pct: ResourcesState.cpuPercent, tint: "#64d2ff" },
        { cap: I18n.tr("RAM"), pct: ResourcesState.memoryPercent, tint: "#30d158" },
        { cap: I18n.tr("DISK"), pct: ResourcesState.storagePercent, tint: "#ff9f0a" }
    ]

    ExtraARing {
        visible: root.isSmall
        x: (root.wr - 84) / 2 * root.k
        y: 24 * root.k
        width: 84 * root.k
        height: width
        percent: root.fraction * 100
        tint: root.level
        trackColor: root.trackCol
        inkColor: root.fg
        lineWidth: 6 * root.k
        glyph: root.present ? "laptop" : "device"
        glyphSize: 32 * root.k
        charging: root.present && root.charging
        fam: root.fam
    }

    Text {
        visible: root.isSmall
        x: root.mx * root.k
        y: 124 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 28 * root.k
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Math.round(root.fraction * 100) + "%"
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
        y: 154 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 22 * root.k
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.timeText !== "—" ? root.stateText + " · " + root.timeText : root.stateText
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 16 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Column {
        visible: root.isMedium
        x: root.mx * root.k
        y: 21 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        spacing: 12 * root.k

        Repeater {
            model: root.isMedium ? root.rows : []

            delegate: Item {
                id: row
                required property var modelData
                width: parent.width
                height: 31 * root.k

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 104 * root.k
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: root.fg
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    x: 120 * root.k
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - 120 * root.k - 70 * root.k)
                    height: 8.5 * root.k
                    radius: height / 2
                    color: root.trackCol

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, row.modelData.pct / 100))
                        height: parent.height
                        radius: height / 2
                        color: row.modelData.tint
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 62 * root.k
                    horizontalAlignment: Text.AlignRight
                    text: (row.modelData.bolt ? "\u26A1" : "") + Math.round(row.modelData.pct) + "%"
                    elide: Text.ElideRight
                    color: root.fg
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Text {
        visible: root.isLarge
        x: root.mx * root.k
        y: 21 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 30 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("System Monitor")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 22 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Row {
        visible: root.isLarge
        x: root.mx * root.k
        y: 62 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 108 * root.k

        Repeater {
            model: root.isLarge ? root.rings : []

            delegate: Item {
                id: ringCell
                required property var modelData
                width: parent.width / 4
                height: parent.height

                ExtraARing {
                    x: (parent.width - width) / 2
                    width: 80 * root.k
                    height: width
                    percent: ringCell.modelData.pct
                    tint: ringCell.modelData.tint
                    trackColor: root.trackCol
                    inkColor: root.fg
                    lineWidth: 6 * root.k
                    valueSize: 19 * root.k
                    fam: root.fam
                }

                Text {
                    y: 84 * root.k
                    width: parent.width
                    height: 20 * root.k
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: ringCell.modelData.cap
                    elide: Text.ElideRight
                    color: root.fg2
                    font.family: root.fam
                    font.pixelSize: 15 * root.k
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Text {
        visible: root.isLarge
        x: root.mx * root.k
        y: 182 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 24 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Top Memory Users")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 17 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Column {
        visible: root.isLarge
        x: root.mx * root.k
        y: 212 * root.k
        width: (root.wr - 2 * root.mx) * root.k

        Repeater {
            model: root.isLarge ? ResourcesState.topMemory.slice(0, 5) : []

            delegate: Item {
                id: mem
                required property var modelData
                required property int index
                width: parent.width
                height: 34 * root.k

                Rectangle {
                    visible: mem.index > 0
                    width: parent.width
                    height: 1
                    color: root.lineCol
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: usage.left
                    anchors.rightMargin: 10 * root.k
                    anchors.verticalCenter: parent.verticalCenter
                    text: mem.modelData.name
                    elide: Text.ElideRight
                    color: root.fg
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }

                Text {
                    id: usage
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.memory(mem.modelData.mb)
                    color: root.fg2
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Text {
        visible: root.isLarge
        x: root.mx * root.k
        y: (root.hr - 23 - 22) * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 22 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.stateText + " · " + root.timeText
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 16 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }
}
