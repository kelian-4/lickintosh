import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    signal closeRequested()

    property int monthOffset: 0

    readonly property date today: new Date()
    readonly property date shown: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
    readonly property int firstOffset: (root.shown.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 0).getDate()
    readonly property int rows: Math.ceil((root.firstOffset + root.daysInMonth) / 7)
    readonly property var weekdays: ["L", "M", "M", "J", "V", "S", "D"]
    readonly property var events: CalendarState.available ? CalendarState.events.slice(0, 4) : []
    readonly property string monthTitle: {
        var n = Qt.locale("fr_FR").monthName(root.shown.getMonth(), Locale.LongFormat)
        return n.charAt(0).toUpperCase() + n.slice(1)
    }

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: "#262626"
    }

    component NavButton: Item {
        id: nav
        property string label: ""
        property bool pill: false
        signal clicked()

        implicitWidth: navText.implicitWidth + (nav.pill ? 16 : 8)
        implicitHeight: 24

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: nav.pill ? "#1F1F1F" : "transparent"
        }
        Text {
            id: navText
            anchors.centerIn: parent
            text: nav.label
            color: "#FFFFFF"
            font.pixelSize: nav.pill ? 12 : 18
            font.family: "SF Pro Rounded"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 170
            Layout.fillHeight: true
            spacing: 2

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: root.monthTitle
                color: "#FFFFFF"
                font.pixelSize: 28
                font.bold: true
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                text: root.shown.getFullYear()
                color: "#8A8A8A"
                font.pixelSize: 15
                font.family: "SF Pro Rounded"
            }

            RowLayout {
                Layout.topMargin: 8
                spacing: 4

                NavButton { label: "‹"; onClicked: root.monthOffset -= 1 }
                NavButton { label: "Aujourd'hui"; pill: true; onClicked: root.monthOffset = 0 }
                NavButton { label: "›"; onClicked: root.monthOffset += 1 }
            }

            Item { Layout.fillHeight: true }
        }

        Divider {}

        Item {
            id: gridArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real cellH: gridArea.height / (root.rows + 1)

            Row {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: gridArea.cellH

                Repeater {
                    model: root.weekdays

                    delegate: Item {
                        required property string modelData
                        required property int index
                        width: header.width / 7
                        height: header.height

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.index >= 5 ? "#EC4899" : "#8A8A8A"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "SF Pro Rounded"
                        }
                    }
                }
            }

            Grid {
                id: grid
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                columns: 7

                Repeater {
                    model: root.rows * 7

                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property date cellDate: new Date(root.shown.getFullYear(), root.shown.getMonth(), 1 - root.firstOffset + cell.index)
                        readonly property bool inMonth: cell.cellDate.getMonth() === root.shown.getMonth()
                        readonly property bool isToday: cell.cellDate.toDateString() === root.today.toDateString()
                        readonly property bool isWeekend: (cell.index % 7) >= 5

                        width: grid.width / 7
                        height: gridArea.cellH

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.height, 24)
                            height: width
                            radius: width / 2
                            color: "#1C7AFF"
                            visible: cell.isToday
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.cellDate.getDate()
                            color: cell.isToday ? "#FFFFFF" : (!cell.inMonth ? "#4A4A4A" : (cell.isWeekend ? "#EC4899" : "#FFFFFF"))
                            font.pixelSize: 12
                            font.bold: cell.isToday
                            font.family: "SF Pro Rounded"
                        }
                    }
                }
            }
        }

        Divider {}

        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Agenda"
                    color: "#8A8A8A"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "SF Pro Rounded"
                }
                Item { Layout.fillWidth: true }
                CtrlButton {
                    icon: "notch/minimize-2.svg"
                    size: 14
                    onClicked: root.closeRequested()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.events.length === 0
                text: "Rien de prévu aujourd'hui"
                color: "#C0C0C0"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }

            Repeater {
                model: root.events

                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 18

                    Text {
                        anchors.fill: parent
                        text: parent.modelData.time + "  " + parent.modelData.title
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.family: "SF Pro Rounded"
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
