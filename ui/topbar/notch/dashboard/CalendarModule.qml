import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell

// Calqué sur modules/dashboard/dash/Calendar.qml de caelestia : une
// vraie grille de mois via les contrôles Qt natifs (MonthGrid /
// DayOfWeekRow), sans dépendance externe (pas de CalDAV/khal — plus
// simple et plus robuste, cf. retour d'expérience avec la première
// version basée sur khal qui a été abandonnée).
Rectangle {
    id: root
    radius: 16
    color: "#1A1A1A"

    property date displayDate: new Date()
    readonly property date today: new Date()

    component NavIcon: Item {
        id: navIcon
        property string icon: ""
        signal clicked()
        implicitWidth: 22
        implicitHeight: 22

        VectorImage {
            anchors.centerIn: parent
            width: 12
            height: 12
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + navIcon.icon)
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#8A8A8A"
            }
        }

        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: navIcon.clicked() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            NavIcon {
                icon: "chevron-left.svg"
                onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() - 1, 1)
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale("fr_FR").monthName(root.displayDate.getMonth()) + " " + root.displayDate.getFullYear()
                color: "#FFFFFF"; font.pixelSize: 15; font.bold: true; font.family: "SF Pro Rounded"
            }
            NavIcon {
                icon: "chevron-right.svg"
                onClicked: root.displayDate = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth() + 1, 1)
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: Qt.locale("fr_FR")
            delegate: Text {
                required property var model
                text: model.shortName
                color: (model.day === 0 || model.day === 6) ? "#EC4899" : "#5A5A5A"
                font.pixelSize: 11
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
                implicitWidth: implicitHeight
                implicitHeight: dayText.implicitHeight + 16

                // Badge hexagonal pour aujourd'hui (au lieu d'un simple
                // rectangle arrondi), approximation de la forme vue
                // dans les captures de caelestia. Volontairement plus
                // grand que la cellule (x1.35, avec un leger halo) :
                // signale a deux reprises comme trop petit pour etre vu
                // du premier coup d'oeil dans une cellule aussi compacte.
                Canvas {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 1.35
                    height: width
                    visible: parent.isToday
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2, cy = height / 2, r = width / 2
                        function hexPath(radius) {
                            ctx.beginPath()
                            for (var i = 0; i < 6; i++) {
                                var angle = Math.PI / 3 * i - Math.PI / 2
                                var x = cx + radius * Math.cos(angle)
                                var y = cy + radius * Math.sin(angle)
                                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                            }
                            ctx.closePath()
                        }
                        hexPath(r)
                        ctx.fillStyle = "rgba(28, 122, 255, 0.35)"
                        ctx.fill()
                        hexPath(r * 0.78)
                        ctx.fillStyle = "#1C7AFF"
                        ctx.fill()
                    }
                }

                Text {
                    id: dayText
                    anchors.centerIn: parent
                    text: model.day
                    color: parent.isToday
                           ? "#FFFFFF"
                           : (model.date.getDay() === 0 || model.date.getDay() === 6) ? "#EC4899" : "#B0B0B0"
                    opacity: parent.isToday || model.month === grid.month ? 1 : 0.4
                    font.pixelSize: parent.isToday ? 15 : 13
                    font.bold: parent.isToday
                    font.family: "SF Pro Rounded"
                }
            }
        }
    }
}
