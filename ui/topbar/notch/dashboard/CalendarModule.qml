import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root
    Layout.preferredWidth: 168
    Layout.fillHeight: true

    signal activated()

    readonly property date today: new Date()
    readonly property int daySpan: 1
    readonly property var upcoming: CalendarState.available ? CalendarState.events.slice(0, 2) : []

    function dayAt(offset) {
        var d = new Date(root.today)
        d.setDate(d.getDate() + offset)
        return d
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: Qt.locale("fr_FR").standaloneMonthName(root.today.getMonth(), Locale.ShortFormat)
                color: "#FFFFFF"
                font.pixelSize: 24
                font.bold: true
                font.family: "SF Pro Rounded"
            }

            Repeater {
                model: root.daySpan * 2 + 1

                delegate: ColumnLayout {
                    required property int index
                    readonly property date cellDate: root.dayAt(index - root.daySpan)
                    readonly property bool isToday: index === root.daySpan
                    readonly property bool isWeekend: cellDate.getDay() === 0 || cellDate.getDay() === 6

                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.locale("fr_FR").standaloneDayName(parent.cellDate.getDay(), Locale.ShortFormat).toUpperCase().replace(".", "")
                        color: parent.isToday ? "#1C7AFF" : (parent.isWeekend ? "#EC4899" : "#8A8A8A")
                        font.pixelSize: 10
                        font.bold: parent.isToday
                        font.family: "SF Pro Rounded"
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.cellDate.getDate()
                        color: parent.isToday ? "#1C7AFF" : (parent.isWeekend ? "#EC4899" : "#FFFFFF")
                        font.pixelSize: parent.isToday ? 20 : 15
                        font.bold: parent.isToday
                        font.family: "SF Pro Rounded"
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                visible: root.upcoming.length === 0
                text: "Rien de prévu aujourd'hui"
                color: "#8A8A8A"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }

            Repeater {
                model: root.upcoming

                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 16

                    Text {
                        anchors.fill: parent
                        text: parent.modelData.time + "  " + parent.modelData.title
                        color: "#C0C0C0"
                        font.pixelSize: 11
                        font.family: "SF Pro Rounded"
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
