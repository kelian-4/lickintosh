import QtQuick
import QtQuick.Layouts
import qs.services

/*
    Refonte complete demandee par l'utilisateur, calquee sur l'app
    macOS "Nook" (captures fournies) : plus de grille de mois complete
    (MonthGrid), juste une bande de quelques jours centree sur
    aujourd'hui (jour de la semaine + numero), aujourd'hui mis en
    evidence, week-end en rose/rouge — puis une ligne d'agenda en
    dessous ("Rien de prevu aujourd'hui" ou le prochain evenement),
    alimentee par le service CalendarState deja existant dans ce depot
    (best-effort via khal, ne plante jamais si indisponible).
*/
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property date today: new Date()
    readonly property int daySpan: 2 // jours affiches de chaque cote d'aujourd'hui

    function dayAt(offset) {
        var d = new Date(root.today)
        d.setDate(d.getDate() + offset)
        return d
    }

    readonly property var nextEvent: CalendarState.available && CalendarState.events.length > 0
                                      ? CalendarState.events[0] : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: Qt.locale("fr_FR").standaloneMonthName(root.today.getMonth(), Locale.ShortFormat)
                color: "#FFFFFF"
                font.pixelSize: 26
                font.bold: true
                font.family: "SF Pro Rounded"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 14

                Repeater {
                    model: root.daySpan * 2 + 1

                    delegate: ColumnLayout {
                        required property int index
                        readonly property date cellDate: root.dayAt(index - root.daySpan)
                        readonly property bool isToday: index === root.daySpan
                        readonly property bool isWeekend: cellDate.getDay() === 0 || cellDate.getDay() === 6

                        spacing: 2
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.locale("fr_FR").standaloneDayName(parent.cellDate.getDay(), Locale.NarrowFormat).toUpperCase()
                            color: parent.isToday ? "#1C7AFF" : (parent.isWeekend ? "#EC4899" : "#8A8A8A")
                            font.pixelSize: 10
                            font.bold: parent.isToday
                            font.family: "SF Pro Rounded"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.cellDate.getDate()
                            color: parent.isToday ? "#1C7AFF" : (parent.isWeekend ? "#EC4899" : "#FFFFFF")
                            font.pixelSize: parent.isToday ? 18 : 15
                            font.bold: parent.isToday
                            font.family: "SF Pro Rounded"
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "🗓"
                font.pixelSize: 11
                opacity: 0.6
            }
            Text {
                Layout.fillWidth: true
                text: root.nextEvent ? (root.nextEvent.time + " · " + root.nextEvent.title) : "Rien de prévu aujourd'hui"
                color: "#8A8A8A"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
        }
    }
}
