import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Calqué sur modules/dashboard/dash/Calendar.qml de caelestia : une
// vraie grille de mois via les contrôles Qt natifs (MonthGrid /
// DayOfWeekRow), sans dépendance externe (pas de CalDAV/khal — plus
// simple et plus robuste, cf. retour d'expérience avec la première
// version basée sur khal qui a été abandonnée).
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 12
    color: "#1A1A1A"

    property date displayDate: new Date()
    readonly property date today: new Date()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "◀"
                color: "#8A8A8A"; font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() - 1, 1) }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale("fr_FR").monthName(root.displayDate.getMonth()) + " " + root.displayDate.getFullYear()
                color: "#FFFFFF"; font.pixelSize: 11; font.bold: true; font.family: "SF Pro Rounded"
            }
            Text {
                text: "▶"
                color: "#8A8A8A"; font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() + 1, 1) }
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: Qt.locale("fr_FR")
            delegate: Text {
                text: model.shortName
                color: "#5A5A5A"
                font.pixelSize: 9
                font.family: "SF Pro Rounded"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: root.displayDate.getMonth()
            year: root.displayDate.getFullYear()
            locale: Qt.locale("fr_FR")

            delegate: Item {
                readonly property bool isToday: model.month === root.today.getMonth()
                                                 && model.year === root.today.getFullYear()
                                                 && model.day === root.today.getDate()
                width: grid.width / 7
                height: grid.height / 6

                // Badge hexagonal pour aujourd'hui (au lieu d'un simple
                // rectangle arrondi), approximation de la forme vue
                // dans les captures de caelestia.
                Canvas {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 6
                    height: width
                    visible: parent.isToday
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2, cy = height / 2, r = width / 2
                        ctx.beginPath()
                        for (var i = 0; i < 6; i++) {
                            var angle = Math.PI / 3 * i - Math.PI / 2
                            var x = cx + r * Math.cos(angle)
                            var y = cy + r * Math.sin(angle)
                            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.closePath()
                        ctx.fillStyle = "#1C7AFF"
                        ctx.fill()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: model.month === grid.month ? "#FFFFFF" : "#4A4A4A"
                    font.pixelSize: 9
                    font.family: "SF Pro Rounded"
                }
            }
        }
    }
}
