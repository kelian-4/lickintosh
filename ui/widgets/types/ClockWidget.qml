import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"
    property string variant: "analog"

    readonly property bool fullBleed: true
    readonly property bool dark: root.look ? !root.look.light : true

    readonly property real u: Math.min(root.width, root.height) / 158
    readonly property real radiusPx: 22
    readonly property real tickLen: 5.6 * root.u

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property real secs: clock.seconds

    readonly property string displayTime: {
        var hour = clock.hours % 12
        if (hour === 0)
            hour = 12
        return hour + ":" + ("0" + clock.minutes).slice(-2)
    }

    readonly property var tickGeo: {
        var W = root.width, H = root.height, inset = 9 * root.u, L = root.tickLen
        var hw = W / 2 - inset, hh = H / 2 - inset
        var cr = Math.max(4 * root.u, root.radiusPx - inset)
        var cx = hw - cr, cy = hh - cr, out = []
        for (var i = 0; i < 60; i++) {
            var th = i * Math.PI / 30, dx = Math.sin(th), dy = -Math.cos(th)
            var ax = Math.abs(dx), ay = Math.abs(dy)
            var t = Math.min(ax > 1e-9 ? hw / ax : 1e9, ay > 1e-9 ? hh / ay : 1e9)
            var px = ax * t, py = ay * t
            if (px > cx && py > cy) {
                var b = ax * cx + ay * cy, c = cx * cx + cy * cy - cr * cr
                t = b + Math.sqrt(Math.max(0, b * b - c))
                px = ax * t
                py = ay * t
            }
            var ex = dx < 0 ? -px : px, ey = dy < 0 ? -py : py
            out.push({ x: W / 2 + ex - dx * L / 2, y: H / 2 + ey - dy * L / 2, a: Math.atan2(dx, -dy) * 180 / Math.PI })
        }
        return out
    }

    Loader {
        anchors.fill: parent
        active: root.variant === "digital"
        source: "DigitalClockWidget.qml"
        onLoaded: {
            item.size = Qt.binding(function() { return root.size })
            item.look = Qt.binding(function() { return root.look })
        }
    }

    Item {
        id: face
        anchors.fill: parent
        visible: root.variant !== "digital"

        Repeater {
            model: 60

            delegate: Rectangle {
                required property int index

                readonly property var tick: root.tickGeo[index]
                readonly property real passed: index <= root.secs ? 1 : 0
                readonly property real past: 0.40 + 0.58 * Math.min(1, index / Math.max(1, root.secs))
                readonly property real ahead: 0.12 + 0.28 * Math.max(0, Math.min(1, (index - root.secs) / Math.max(1, 60 - root.secs)))

                width: 1.7 * root.u
                height: root.tickLen
                x: tick.x - width / 2
                y: tick.y - height / 2
                radius: width / 2
                rotation: tick.a
                color: root.dark ? "white" : "#0C0D0F"
                opacity: (root.dark ? 0.9 : 1.0) * (passed > 0 ? past : ahead)

                Behavior on opacity { NumberAnimation { duration: 220 } }
            }
        }

        Text {
            id: clockText

            readonly property real xs: 0.94
            readonly property real ys: 1.14

            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1 * root.u

            width: (root.width - 56 * root.u) / xs
            height: 64 * root.u * 1.25

            text: root.displayTime
            color: root.dark ? "#FFFFFF" : "#0C0D0F"
            opacity: 0.96

            font.family: "SF Pro Display"
            font.pixelSize: 64 * root.u
            font.weight: Font.DemiBold
            font.letterSpacing: -2.2 * root.u
            font.features: { "tnum": 1 }

            renderType: Text.QtRendering
            antialiasing: true

            transform: Scale {
                origin.x: clockText.width / 2
                origin.y: clockText.height / 2
                xScale: clockText.xs
                yScale: clockText.ys
            }

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            fontSizeMode: Text.Fit
            minimumPixelSize: 10
        }
    }
}
