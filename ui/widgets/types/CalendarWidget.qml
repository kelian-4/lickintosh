import QtQuick
import qs.services

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
    readonly property string famDisplay: "SF Pro Display"
    readonly property var loc: Qt.locale(I18n.lang)

    readonly property real k: root.isSmall ? root.width / 158 : (root.isMedium ? root.width / 338 : root.height / 354)
    readonly property real pad: 15 * root.k

    function fa(a) { return root.dark ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a) }
    readonly property color fg: root.fa(root.dark ? 0.96 : 0.86)
    readonly property color fgSub: root.fa(root.dark ? 0.55 : 0.45)
    readonly property color red: root.dark ? "#FF453A" : "#FF3B30"
    readonly property color line: root.fa(root.dark ? 0.16 : 0.12)

    readonly property date today: clock.date
    readonly property int firstDay: root.loc.firstDayOfWeek % 7
    readonly property int monthOffset: (new Date(root.today.getFullYear(), root.today.getMonth(), 1).getDay() - root.firstDay + 7) % 7
    readonly property int monthDays: new Date(root.today.getFullYear(), root.today.getMonth() + 1, 0).getDate()
    readonly property var events: CalendarState.available ? CalendarState.events : []
    readonly property bool showEvents: root.isMedium && root.events.length > 0

    readonly property var gridSpec: root.isSmall ? { x: 12, y: 32, w: 134, wdH: 16, rowH: 16.7, wdPx: 10.5, dayPx: 11.5, circ: 17 }
                                  : (root.isMedium ? { x: 172, y: 11, w: 152, wdH: 18, rowH: 19.5, wdPx: 11, dayPx: 12.5, circ: 18 }
                                                   : { x: 15, y: 58, w: 308, wdH: 24, rowH: 44, wdPx: 13, dayPx: 19, circ: 33 })

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: grid
        visible: !root.showEvents
        x: root.isLarge ? Math.round(root.pad) : Math.round(root.gridSpec.x * root.k)
        y: Math.round(root.gridSpec.y * root.k)
        width: root.isLarge ? Math.round(root.width - 2 * root.pad) : Math.round(root.gridSpec.w * root.k)
        height: grid.wdH + 6 * grid.rowH

        readonly property real cw: grid.width / 7
        readonly property int wdH: Math.round(root.gridSpec.wdH * root.k)
        readonly property int rowH: Math.round(root.gridSpec.rowH * root.k)
        readonly property real wdPx: root.gridSpec.wdPx * root.k
        readonly property real dayPx: root.gridSpec.dayPx * root.k
        readonly property int circ: 2 * Math.round(root.gridSpec.circ * root.k / 2)

        Repeater {
            model: 7

            delegate: Text {
                required property int index
                x: Math.round((index + 0.5) * grid.cw - implicitWidth / 2)
                y: Math.round((grid.wdH - implicitHeight) / 2)
                text: root.loc.dayName((root.firstDay + index) % 7, Locale.NarrowFormat).toUpperCase()
                color: root.fgSub
                font.family: root.fam
                font.pixelSize: grid.wdPx
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }
        }

        Repeater {
            model: 42

            delegate: Item {
                id: cell
                required property int index
                readonly property int day: cell.index - root.monthOffset + 1
                readonly property bool valid: cell.day >= 1 && cell.day <= root.monthDays
                readonly property bool isToday: cell.valid && cell.day === root.today.getDate()

                visible: cell.valid
                x: Math.round((cell.index % 7 + 0.5) * grid.cw) - grid.circ / 2
                y: grid.wdH + Math.floor(cell.index / 7) * grid.rowH + Math.round((grid.rowH - grid.circ) / 2)
                width: grid.circ
                height: grid.circ

                Rectangle {
                    visible: cell.isToday
                    anchors.fill: parent
                    radius: width / 2
                    color: root.red
                }

                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: cell.day
                    color: cell.isToday ? "#ffffff" : root.fg
                    font.family: root.fam
                    font.pixelSize: grid.dayPx
                    font.weight: cell.isToday ? Font.Bold : Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Text {
        visible: root.isSmall
        x: 13 * root.k
        y: 10 * root.k
        width: root.width - 26 * root.k
        elide: Text.ElideRight
        text: root.loc.standaloneMonthName(root.today.getMonth(), Locale.LongFormat).toUpperCase()
        color: root.red
        font.family: root.fam
        font.pixelSize: 13 * root.k
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    Rectangle {
        visible: root.isMedium
        x: 164 * root.k
        y: 16 * root.k
        width: 1
        height: root.height - 32 * root.k
        color: root.line
    }

    Text {
        visible: root.isMedium
        x: root.pad
        y: 14 * root.k
        width: 142 * root.k
        elide: Text.ElideRight
        text: root.loc.dayName(root.today.getDay(), Locale.LongFormat).toUpperCase()
        color: root.red
        font.family: root.fam
        font.pixelSize: 13 * root.k
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isMedium
        x: root.pad - 1 * root.k
        y: 30 * root.k
        text: root.today.getDate()
        color: root.fg
        font.family: root.famDisplay
        font.pixelSize: 58 * root.k
        font.weight: Font.Light
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.isMedium
        x: root.pad
        y: root.height - root.pad + 1 * root.k - implicitHeight
        width: 142 * root.k
        elide: Text.ElideRight
        text: root.loc.standaloneMonthName(root.today.getMonth(), Locale.LongFormat) + " " + root.today.getFullYear()
        color: root.fgSub
        font.family: root.fam
        font.pixelSize: 14 * root.k
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }

    Column {
        visible: root.showEvents
        x: 178 * root.k
        y: 16 * root.k
        width: root.width - 178 * root.k - root.pad
        spacing: 7 * root.k

        Repeater {
            model: root.events.slice(0, 3)

            delegate: Row {
                required property var modelData
                width: parent.width
                spacing: 8 * root.k

                Rectangle {
                    width: 3 * root.k
                    height: 30 * root.k
                    radius: width / 2
                    color: Theme.accent
                }

                Column {
                    width: parent.width - 11 * root.k
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: modelData.title
                        elide: Text.ElideRight
                        color: root.fg
                        font.family: root.fam
                        font.pixelSize: 12.5 * root.k
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: modelData.time
                        elide: Text.ElideRight
                        color: root.fgSub
                        font.family: root.fam
                        font.pixelSize: 11 * root.k
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    Row {
        visible: root.isLarge
        x: root.pad
        y: 13 * root.k
        width: root.width - 2 * root.pad
        spacing: 7 * root.k

        Text {
            text: root.loc.standaloneMonthName(root.today.getMonth(), Locale.LongFormat)
            color: root.red
            font.family: root.famDisplay
            font.pixelSize: 26 * root.k
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Text {
            text: root.today.getFullYear()
            color: root.fgSub
            font.family: root.famDisplay
            font.pixelSize: 26 * root.k
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    Rectangle {
        visible: root.isLarge
        x: root.pad
        y: grid.y + grid.wdH
        width: root.width - 2 * root.pad
        height: 1
        color: root.line
    }
}
