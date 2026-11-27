import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: win

    property string path: ""
    property var sel: []
    readonly property int selectedCount: win.sel.filter(function(v) { return v }).length

    signal applied(var hours)
    signal canceled()

    function toggle(i) {
        var a = win.sel.slice()
        a[i] = !a[i]
        win.sel = a
    }

    function apply() {
        if (win.selectedCount === 0) return
        var out = []
        for (var i = 0; i < 24; i++) if (win.sel[i]) out.push(i)
        win.applied(out)
    }

    Component.onCompleted: {
        var a = []
        for (var i = 0; i < 24; i++) a.push(false)
        a[new Date().getHours()] = true
        win.sel = a
        keys.forceActiveFocus()
    }

    screen: {
        var focused = Hyprland.focusedMonitor
        if (focused) {
            var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
            if (s) return s
        }
        return Quickshell.screens[0]
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper-hours"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    exclusiveZone: -1
    anchors { top: true; left: true; right: true; bottom: true }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"

        MouseArea {
            anchors.fill: parent
            onClicked: win.canceled()
        }
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.canceled()
        Keys.onReturnPressed: win.apply()
        Keys.onEnterPressed: win.apply()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 440
        height: _col.implicitHeight + 40
        radius: 16
        color: Theme.panel
        border.color: Theme.panelRim
        border.width: 1

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: _col
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 192
                Layout.preferredHeight: 112
                radius: 10
                color: "#25000000"
                clip: true

                Image {
                    anchors.fill: parent
                    source: win.path !== "" ? "file://" + win.path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(384, 224)
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr("À quelles heures utiliser ce fond d'écran ?")
                color: Theme.textPrimary
                font.family: "SF Pro Text"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 6
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: 24

                    delegate: Rectangle {
                        id: _chip
                        required property int index
                        readonly property bool on: win.sel[_chip.index] === true

                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 28
                        radius: 8
                        color: _chip.on ? Theme.accent : (_mouse.containsMouse ? Theme.fillHover : Theme.fillControl)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: ("0" + _chip.index).slice(-2) + ":00"
                            color: _chip.on ? Theme.onAccent : Theme.textPrimary
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: _mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.toggle(_chip.index)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 28
                    radius: 8
                    color: _cancelMouse.containsMouse ? Theme.fillHover : Theme.fillControl

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Annuler")
                        color: Theme.textPrimary
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: _cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.canceled()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 28
                    radius: 8
                    opacity: win.selectedCount > 0 ? 1 : 0.45
                    color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Appliquer")
                        color: Theme.onAccent
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: win.selectedCount > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.apply()
                    }
                }
            }
        }
    }
}
