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
    readonly property color lineCol: root.fa(root.dark ? 0.16 : 0.12)
    readonly property color accent: "#0a84ff"

    readonly property bool on: BluetoothState.enabled
    readonly property var connected: BluetoothState.devices.filter(function(d) { return d.connected })
    readonly property int visibleCount: root.isLarge ? 6 : (root.isMedium ? 3 : 0)
    readonly property string statusText: !root.on ? I18n.tr("Off") : (root.connected.length === 0 ? I18n.tr("No Devices") : I18n.tr("%1 connected").replace("%1", root.connected.length))

    function kindOf(dev) {
        var ic = ((dev && dev.icon) || "").toLowerCase()
        if (ic.indexOf("headset") !== -1 || ic.indexOf("headphone") !== -1 || ic.indexOf("audio") !== -1) return "headphones"
        if (ic.indexOf("mouse") !== -1) return "mouse"
        if (ic.indexOf("laptop") !== -1 || ic.indexOf("notebook") !== -1 || ic.indexOf("computer") !== -1) return "laptop"
        return "bluetooth"
    }

    Rectangle {
        x: root.mx * root.k
        y: 22 * root.k
        width: 46 * root.k
        height: width
        radius: width / 2
        color: root.on ? root.accent : root.fa(root.dark ? 0.14 : 0.10)
        Behavior on color { ColorAnimation { duration: 200 } }

        ExtraAGlyph {
            anchors.centerIn: parent
            width: 24 * root.k
            height: width
            kind: "bluetooth"
            flag: !root.on
            color: root.on ? "white" : root.fg2
        }
    }

    Text {
        visible: root.isSmall
        x: root.mx * root.k
        y: 100 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 30 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Bluetooth")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 21 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isSmall
        x: root.mx * root.k
        y: 130 * root.k
        width: (root.wr - 2 * root.mx) * root.k
        height: 24 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.statusText
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 16 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Text {
        visible: !root.isSmall
        x: (root.mx + 46 + 12) * root.k
        y: 20 * root.k
        width: (root.wr - 2 * root.mx - 46 - 12) * root.k
        height: 28 * root.k
        verticalAlignment: Text.AlignVCenter
        text: I18n.tr("Bluetooth")
        elide: Text.ElideRight
        color: root.fg
        font.family: root.fam
        font.pixelSize: 20 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Text {
        visible: !root.isSmall
        x: (root.mx + 46 + 12) * root.k
        y: 48 * root.k
        width: (root.wr - 2 * root.mx - 46 - 12) * root.k
        height: 22 * root.k
        verticalAlignment: Text.AlignVCenter
        text: root.statusText
        elide: Text.ElideRight
        color: root.fg2
        font.family: root.fam
        font.pixelSize: 15 * root.k
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    Column {
        visible: !root.isSmall
        x: root.mx * root.k
        y: (root.isLarge ? 92 : 84) * root.k
        width: (root.wr - 2 * root.mx) * root.k

        Repeater {
            model: root.connected.slice(0, root.visibleCount)

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property int pct: BluetoothState.batteryPercent(row.modelData)
                width: parent.width
                height: (root.isLarge ? 52 : 34) * root.k

                Rectangle {
                    visible: row.index > 0
                    width: parent.width
                    height: 1
                    color: root.lineCol
                }

                Rectangle {
                    id: badge
                    visible: root.isLarge
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34 * root.k
                    height: width
                    radius: width / 2
                    color: root.fa(root.dark ? 0.12 : 0.08)

                    ExtraAGlyph {
                        anchors.centerIn: parent
                        width: 20 * root.k
                        height: width
                        kind: root.kindOf(row.modelData)
                        color: root.fg
                    }
                }

                Text {
                    anchors.left: root.isLarge ? badge.right : parent.left
                    anchors.leftMargin: root.isLarge ? 12 * root.k : 0
                    anchors.right: level.left
                    anchors.rightMargin: 10 * root.k
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: root.fg
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }

                Text {
                    id: level
                    visible: row.pct >= 0
                    width: visible ? implicitWidth : 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.pct + "%"
                    color: row.pct <= 15 ? "#ff453a" : root.fg2
                    font.family: root.fam
                    font.pixelSize: 16 * root.k
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
