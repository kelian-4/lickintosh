import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root

    property string size: "s"

    readonly property date today: clock.date
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7
    readonly property int monthOffset: (new Date(root.today.getFullYear(), root.today.getMonth(), 1).getDay() - root.firstDay + 7) % 7
    readonly property int monthDays: new Date(root.today.getFullYear(), root.today.getMonth() + 1, 0).getDate()
    readonly property var events: CalendarState.available ? CalendarState.events : []

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.size !== "l"

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            ColumnLayout {
                Layout.preferredWidth: root.size === "s" ? -1 : 110
                Layout.fillWidth: root.size === "s"
                spacing: 0

                Text {
                    text: Qt.locale().dayName(root.today.getDay(), Locale.LongFormat).toUpperCase()
                    color: "#ff453a"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: root.today.getDate()
                    color: "#ffffff"
                    font.pixelSize: 56
                    font.weight: Font.Light
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: Qt.locale().standaloneMonthName(root.today.getMonth(), Locale.LongFormat)
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }

            ColumnLayout {
                visible: root.size === "m"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    visible: root.events.length === 0
                    text: "No Events"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 13
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Repeater {
                    model: root.events.slice(0, 3)

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 28
                            radius: 1.5
                            color: "#0a84ff"
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                elide: Text.ElideRight
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                font.family: "SF Pro Text"
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: modelData.time
                                color: Qt.rgba(1, 1, 1, 0.55)
                                font.pixelSize: 11
                                font.family: "SF Pro Text"
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6
        visible: root.size === "l"

        Text {
            text: Qt.locale().standaloneMonthName(root.today.getMonth(), Locale.LongFormat).toUpperCase() + " " + root.today.getFullYear()
            color: "#ff453a"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: 7

                delegate: Text {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.NarrowFormat)
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }
            }

            Repeater {
                model: 42

                delegate: Item {
                    id: dayCell
                    required property int index
                    readonly property int day: dayCell.index - root.monthOffset + 1
                    readonly property bool valid: dayCell.day >= 1 && dayCell.day <= root.monthDays
                    readonly property bool isToday: dayCell.valid && dayCell.day === root.today.getDate()

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height, 26)
                        height: width
                        radius: width / 2
                        color: "#ff453a"
                        visible: dayCell.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: dayCell.valid
                        text: dayCell.day
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }
}
