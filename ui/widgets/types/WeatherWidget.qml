import QtQuick
import qs.components
import qs.services

Item {
    id: w

    property var look: null
    property string size: "s"

    readonly property bool fullBleed: true
    readonly property bool isSmall: w.size === "s"
    readonly property bool isMedium: w.size === "m"
    readonly property bool isLarge: w.size === "l"

    readonly property bool dark: w.look ? !w.look.light : true
    readonly property string fam: "SF Pro Text"
    readonly property real s: w.isLarge ? w.width / 358 : w.height / 158
    readonly property real pad: 15 * w.s

    function fa(a) { return w.dark ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a) }
    readonly property color fg: w.fa(w.dark ? 0.96 : 0.86)
    readonly property color fgSub: w.fa(w.dark ? 0.62 : 0.52)
    readonly property color fgHour: w.fa(w.dark ? 0.85 : 0.70)
    readonly property color line: w.fa(w.dark ? 0.16 : 0.12)
    readonly property color barTrack: w.fa(w.dark ? 0.22 : 0.14)
    readonly property color barFill: w.fa(w.dark ? 0.85 : 0.62)

    readonly property bool hasData: WeatherState.available
    readonly property var today: WeatherState.forecast.length > 0 ? WeatherState.forecast[0] : null
    readonly property string kind: WeatherState.kind
    readonly property int temp: Math.round(WeatherState.tempC)
    readonly property string unit: "°"

    readonly property string hiLo: w.hasData && w.today
        ? I18n.tr("H:") + w.today.tempMax + w.unit + " " + I18n.tr("L:") + w.today.tempMin + w.unit
        : " "

    readonly property var hourlyModel: {
        var out = []
        var src = WeatherState.hourly
        for (var i = 0; i < src.length; i++) {
            out.push({
                h: w.hourLabel(src[i].time, i === 0),
                t: src[i].temp,
                k: WeatherState._kindFor(src[i].code, src[i].isDay)
            })
        }
        return out
    }

    readonly property var dailyModel: {
        var out = []
        var src = WeatherState.forecast
        for (var i = 0; i < src.length && i < 5; i++) {
            out.push({
                d: w.dayLabel(src[i].date, i),
                lo: src[i].tempMin,
                hi: src[i].tempMax,
                k: WeatherState._kindFor(src[i].code, true)
            })
        }
        return out
    }

    function hourLabel(iso, first) {
        if (first) return I18n.tr("Now")
        var h = parseInt(String(iso).substr(11, 2))
        if (I18n.lang === "en") return (h % 12 === 0 ? 12 : h % 12) + (h < 12 ? "AM" : "PM")
        return h + "h"
    }

    function dayLabel(dateString, i) {
        if (i === 0) return I18n.tr("Today")
        return Qt.locale(I18n.lang).dayName(new Date(dateString + "T12:00:00").getDay(), Locale.ShortFormat)
    }

    component HourCol: Column {
        id: hc
        required property var info
        property real colW: 40
        width: hc.colW
        spacing: 3 * w.s

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: hc.info.h
            color: w.fgHour
            font.family: w.fam
            font.pixelSize: 12 * w.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Item {
            width: parent.width
            height: 20 * w.s

            WeatherIconGlyph {
                anchors.centerIn: parent
                kind: hc.info.k
                size: 18 * w.s
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: hc.info.t + w.unit
            color: w.fg
            font.family: w.fam
            font.pixelSize: 15 * w.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    Row {
        x: w.pad
        y: w.pad - 1 * w.s
        spacing: 4 * w.s

        Text {
            id: cityText
            text: WeatherState.city !== "" ? WeatherState.city : I18n.tr("Weather")
            width: Math.min(implicitWidth, (w.isLarge ? w.width : 158 * w.s) - 2 * w.pad - 14 * w.s)
            elide: Text.ElideRight
            color: w.fg
            font.family: w.fam
            font.pixelSize: 15 * w.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Canvas {
            id: loc
            visible: WeatherState.city !== ""
            anchors.verticalCenter: cityText.verticalCenter
            anchors.verticalCenterOffset: 1 * w.s
            width: 9 * w.s
            height: 9 * w.s
            onWidthChanged: requestPaint()
            Connections {
                target: w
                function onDarkChanged() { loc.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = w.dark ? "white" : "#1c1c1e"
                ctx.beginPath()
                ctx.moveTo(width, 0)
                ctx.lineTo(0.05 * width, 0.42 * height)
                ctx.lineTo(0.58 * width, 0.46 * height)
                ctx.lineTo(0.62 * width, 1.0 * height)
                ctx.closePath()
                ctx.fill()
            }
        }
    }

    Text {
        x: w.pad - 1 * w.s
        y: 30 * w.s
        text: w.hasData ? (w.temp + w.unit) : "–°"
        color: w.fg
        font.family: w.fam
        font.pixelSize: 46 * w.s
        font.weight: Font.Light
        renderType: Text.NativeRendering
    }

    Column {
        id: condCol
        width: w.isLarge ? 150 * w.s : 158 * w.s - 2 * w.pad
        x: w.isLarge ? w.width - w.pad - width : w.pad
        y: w.isLarge ? 36 * w.s : w.height - w.pad + 1 * w.s - implicitHeight
        spacing: 1 * w.s

        Item {
            visible: w.hasData
            width: parent.width
            height: visible ? 23 * w.s : 0

            WeatherIconGlyph {
                x: w.isLarge ? parent.width - width : 0
                kind: w.kind
                size: 20 * w.s
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: w.isLarge ? Text.AlignRight : Text.AlignLeft
            text: WeatherState.description
            elide: Text.ElideRight
            color: w.fg
            font.family: w.fam
            font.pixelSize: 14 * w.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Text {
            width: parent.width
            horizontalAlignment: w.isLarge ? Text.AlignRight : Text.AlignLeft
            elide: Text.ElideRight
            text: w.hiLo
            color: w.fg
            font.family: w.fam
            font.pixelSize: 14 * w.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    Rectangle {
        visible: w.isMedium
        x: 164 * w.s
        y: 16 * w.s
        width: 1
        height: w.height - 32 * w.s
        color: w.line
    }

    Row {
        visible: w.isMedium
        x: 172 * w.s
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: w.isMedium ? w.hourlyModel.slice(0, 4) : []

            delegate: HourCol {
                required property var modelData
                info: modelData
                colW: (w.width - 172 * w.s - w.pad + 4 * w.s) / 4
            }
        }
    }

    Rectangle {
        visible: w.isLarge
        x: w.pad
        y: 134 * w.s
        width: w.width - 2 * w.pad
        height: 1
        color: w.line
    }

    Row {
        visible: w.isLarge
        x: w.pad
        y: 142 * w.s

        Repeater {
            model: w.isLarge ? w.hourlyModel.slice(0, 6) : []

            delegate: HourCol {
                required property var modelData
                info: modelData
                colW: (w.width - 2 * w.pad) / 6
            }
        }
    }

    Rectangle {
        visible: w.isLarge
        x: w.pad
        y: 206 * w.s
        width: w.width - 2 * w.pad
        height: 1
        color: w.line
    }

    Column {
        id: dailyCol
        visible: w.isLarge
        x: w.pad
        y: 210 * w.s
        width: w.width - 2 * w.pad

        readonly property var days: w.dailyModel
        readonly property real minT: {
            var m = 1e9
            for (var i = 0; i < days.length; i++) m = Math.min(m, days[i].lo)
            return m
        }
        readonly property real maxT: {
            var m = -1e9
            for (var i = 0; i < days.length; i++) m = Math.max(m, days[i].hi)
            return m
        }

        Repeater {
            model: dailyCol.days

            delegate: Item {
                id: dr
                required property var modelData
                width: dailyCol.width
                height: 27 * w.s
                readonly property real span: Math.max(1, dailyCol.maxT - dailyCol.minT)

                Text {
                    x: 0
                    width: 66 * w.s
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: dr.modelData.d
                    color: w.fg
                    font.family: w.fam
                    font.pixelSize: 14 * w.s
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                WeatherIconGlyph {
                    x: 72 * w.s
                    anchors.verticalCenter: parent.verticalCenter
                    kind: dr.modelData.k
                    size: 18 * w.s
                }

                Text {
                    x: 104 * w.s
                    width: 32 * w.s
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    text: dr.modelData.lo + w.unit
                    color: w.fgSub
                    font.family: w.fam
                    font.pixelSize: 14 * w.s
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    id: track
                    x: 144 * w.s
                    width: dr.width - 144 * w.s - 38 * w.s
                    height: 4 * w.s
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: w.barTrack

                    Rectangle {
                        x: track.width * (dr.modelData.lo - dailyCol.minT) / dr.span
                        width: Math.max(track.height, track.width * (dr.modelData.hi - dr.modelData.lo) / dr.span)
                        height: parent.height
                        radius: height / 2
                        color: w.barFill
                    }
                }

                Text {
                    x: dr.width - 32 * w.s
                    width: 32 * w.s
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    text: dr.modelData.hi + w.unit
                    color: w.fg
                    font.family: w.fam
                    font.pixelSize: 14 * w.s
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
