import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root

    property var look: null
    property string size: "m"

    readonly property bool isLarge: root.size === "l"
    readonly property real k: Math.min(root.width / 330, root.height / (root.isLarge ? 326 : 140))
    readonly property color fg: root.look ? root.look.primary : "white"
    readonly property color fg2: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)

    readonly property var cities: [
        { name: "Cupertino", tz: "America/Los_Angeles" },
        { name: "New York", tz: "America/New_York" },
        { name: "London", tz: "Europe/London" },
        { name: "Paris", tz: "Europe/Paris" },
        { name: "Dubai", tz: "Asia/Dubai" },
        { name: "Tokyo", tz: "Asia/Tokyo" }
    ]
    readonly property var shown: root.cities.slice(0, root.isLarge ? 6 : 3)

    property var times: ({})

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: refresh.running = true
    }

    Process {
        id: refresh
        running: true
        command: ["sh", "-c", "for z in \"$@\"; do printf '%s|' \"$z\"; TZ=\"$z\" date +'%H:%M|%a'; done",
            "sh"].concat(root.shown.map(function(c) { return c.tz }))
        stdout: StdioCollector {
            id: out
        }
        onExited: {
            var map = {}
            String(out.text).trim().split("\n").forEach(function(line) {
                var p = line.split("|")
                if (p.length >= 3) map[p[0]] = { time: p[1], day: p[2] }
            })
            root.times = map
        }
    }

    onSizeChanged: refresh.running = true

    ColumnLayout {
        anchors.fill: parent
        spacing: 4 * root.k

        Text {
            text: I18n.tr("Horloge mondiale")
            color: "#ff9f0a"
            font.pixelSize: 14 * root.k
            font.weight: Font.DemiBold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.shown

            delegate: RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property var t: root.times[row.modelData.tz]

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: root.fg
                    font.pixelSize: 15 * root.k
                    font.weight: Font.Medium
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: row.t ? row.t.day : ""
                    color: root.fg2
                    font.pixelSize: 12 * root.k
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: row.t ? row.t.time : "--:--"
                    color: root.fg
                    font.pixelSize: 22 * root.k
                    font.weight: Font.Light
                    font.family: "SF Pro Display"
                    font.features: { "tnum": 1 }
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
