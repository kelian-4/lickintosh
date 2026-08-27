import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.ui.primitives
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var _widgets: [
        { id: "wifiWidget",      name: "Wi-Fi",              icon: "wifi/nm-signal-100-symbolic.svg" },
        { id: "btWidget",        name: "Bluetooth",          icon: "bluetooth/bluetooth.svg" },
        { id: "adWidget",        name: "AirDrop / KDE Connect", icon: "devices/smartphone.svg" },
        { id: "musicWidget",     name: "Lecteur multimédia", icon: "music/play.svg" },
        { id: "focusWidget",     name: "Focus",               icon: "dnd.svg" },
        { id: "stageWidget",     name: "Capture d'écran",    icon: "screenshot/region.svg" },
        { id: "shareWidget",     name: "Partage d'écran",    icon: "screenshare.svg" },
        { id: "darkWidget",      name: "Mode sombre",         icon: "notch/moon.svg" },
        { id: "calcWidget",      name: "Calculatrice",        icon: "" },
        { id: "gameModeWidget",  name: "Mode jeu",             icon: "" },
        { id: "displayWidget",   name: "Luminosité",          icon: "sun-small.svg" },
        { id: "volumeWidget",    name: "Volume",               icon: "volume/audio-volume-3.svg" },
        { id: "timerWidget",     name: "Minuteur",             icon: "notch/clock.svg" },
        { id: "alarmWidget",     name: "Alarme",                icon: "notch/bell.svg" },
        { id: "stopwatchWidget", name: "Chronomètre",          icon: "notch/watch.svg" }
    ]

    Process {
        id: _openControlCenterProc
        command: ["sh", "-c", "qs ipc -p \"" + Quickshell.shellDir + "/shell.qml\" call controlcenter openEditMode 2>/dev/null || true"]
    }

    ContentSection {
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Contrôles disponibles"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                id: _openCcButton
                Layout.preferredWidth: 160
                Layout.minimumWidth: 100
                Layout.preferredHeight: 30
                radius: 8
                color: _openCcMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                clip: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    CFVI {
                        width: 13
                        height: 13
                        icon: "control-center.svg"
                    }
                    CFText {
                        text: "Ouvrir le Control Center"
                        font.pixelSize: 12
                        color: "#fff"
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: _openCcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _openControlCenterProc.running = true
                }
            }
        }

        CFText {
            text: "Coche les contrôles que tu veux voir apparaître dans le Control Center."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: "Widgets"

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
                            color: "#a0ffffff"
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
                                    color: "#a0ffffff"
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
                            color: "#a0ffffff"
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 1.5
                            height: 6
                            radius: 0.75
                            color: "#a0ffffff"
                            anchors.left: parent.left
                            anchors.leftMargin: 6.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: "#a0ffffff"
                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.top: parent.top
                            anchors.topMargin: 3
                        }
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: "#a0ffffff"
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
                    color: "#fff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    color: ShellConfig.ccWidgetVisible(_widgetRow.modelData.id) ? "#34c759" : "#40ffffff"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#fff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: ShellConfig.ccWidgetVisible(_widgetRow.modelData.id) ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
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
