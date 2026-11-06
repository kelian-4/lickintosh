import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var _widgets: [
        { id: "wifiWidget",      name: I18n.tr("Wi-Fi"),              icon: "wifi/nm-signal-100-symbolic.svg", locked: false },
        { id: "btWidget",        name: I18n.tr("Bluetooth"),          icon: "bluetooth/bluetooth.svg", locked: false },
        { id: "adWidget",        name: I18n.tr("AirDrop / KDE Connect"), icon: "devices/smartphone.svg", locked: false },
        { id: "musicWidget",     name: I18n.tr("Lecteur multimédia"), icon: "music/play.svg", locked: false },
        { id: "focusWidget",     name: I18n.tr("Focus"),               icon: "dnd.svg", locked: false },
        { id: "stageWidget",     name: I18n.tr("Capture d'écran"),    icon: "screenshot/region.svg", locked: false },
        { id: "shareWidget",     name: I18n.tr("Partage d'écran"),    icon: "screenshare.svg", locked: false },
        { id: "displayWidget",   name: I18n.tr("Luminosité"),          icon: "sun-small.svg", locked: false },
        { id: "volumeWidget",    name: I18n.tr("Volume"),               icon: "volume/audio-volume-3.svg", locked: false },
        { id: "darkWidget",      name: I18n.tr("Mode sombre"),         icon: "notch/moon.svg", locked: false },
        { id: "calcWidget",      name: I18n.tr("Calculatrice"),        icon: "", locked: false },
        { id: "gameModeWidget",  name: I18n.tr("Mode jeu"),             icon: "", locked: false },
        { id: "timerWidget",     name: I18n.tr("Minuteur"),             icon: "notch/clock.svg", locked: false },
        { id: "alarmWidget",     name: I18n.tr("Alarme"),                icon: "notch/bell.svg", locked: false },
        { id: "stopwatchWidget", name: I18n.tr("Chronomètre"),          icon: "notch/watch.svg", locked: false }
    ]

    ContentSection {
        CFText {
            text: I18n.tr("Contrôles disponibles")
            font.pixelSize: 14
            color: Theme.textPrimary
            Layout.fillWidth: true
        }

        CFText {
            text: I18n.tr("Coche les contrôles que tu veux voir apparaître dans le Control Center.")
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: I18n.tr("Widgets")

        Repeater {
            model: root._widgets

            RowLayout {
                id: _widgetRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Item {
                    width: 20
                    height: 20

                    CFVI {
                        visible: _widgetRow.modelData.icon.length > 0
                        anchors.fill: parent
                        icon: _widgetRow.modelData.icon
                        gray: true
                    }

                    Item {
                        visible: _widgetRow.modelData.id === "calcWidget"
                        anchors.centerIn: parent
                        width: 16
                        height: 19
                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: "transparent"
                            border.color: "#a0ffffff"
                            border.width: 1.5
                        }
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 3
                            height: 4
                            radius: 1
                            color: Theme.textSecondary
                        }
                        Grid {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 3
                            anchors.rightMargin: 3
                            anchors.bottomMargin: 3
                            columns: 3
                            rowSpacing: 1.5
                            columnSpacing: 1.5
                            Repeater {
                                model: 6
                                Rectangle {
                                    width: 2
                                    height: 2
                                    radius: 1
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }

                    Item {
                        visible: _widgetRow.modelData.id === "gameModeWidget"
                        anchors.centerIn: parent
                        width: 20
                        height: 14
                        Rectangle {
                            anchors.fill: parent
                            radius: height/2
                            color: "transparent"
                            border.color: "#a0ffffff"
                            border.width: 1.5
                        }
                        Rectangle {
                            width: 6
                            height: 1.5
                            radius: 0.75
                            color: Theme.textSecondary
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 1.5
                            height: 6
                            radius: 0.75
                            color: Theme.textSecondary
                            anchors.left: parent.left
                            anchors.leftMargin: 6.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: Theme.textSecondary
                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.top: parent.top
                            anchors.topMargin: 3
                        }
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: Theme.textSecondary
                            anchors.right: parent.right
                            anchors.rightMargin: 6.5
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                        }
                    }
                }

                CFText {
                    text: _widgetRow.modelData.name
                    font.pixelSize: 14
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    opacity: _widgetRow.modelData.locked ? 0.35 : 1
                    color: _widgetRow.modelData.locked ? "#34c759" : (ShellConfig.ccWidgetVisible(_widgetRow.modelData.id) ? "#34c759" : "#40ffffff")
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        x: (_widgetRow.modelData.locked || ShellConfig.ccWidgetVisible(_widgetRow.modelData.id)) ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !_widgetRow.modelData.locked
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellConfig.setCcWidgetVisible(
                            _widgetRow.modelData.id,
                            !ShellConfig.ccWidgetVisible(_widgetRow.modelData.id)
                        )
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
