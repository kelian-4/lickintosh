import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.components.glass
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
        card.forceActiveFocus()
    }

    screen: {
        var focused = Hyprland.focusedMonitor
        if (focused) {
            var s = Quickshell.screens.find(function(sc) { return sc.name === focused.name })
            if (s) return s
        }
        return Quickshell.screens[0]
    }

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper-hours"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    GlassBackdrop { element: "osd" }

    MouseArea {
        anchors.fill: parent
        onClicked: win.canceled()
    }

    Item {
        id: card
        width: 440
        height: _col.implicitHeight + 40
        anchors.centerIn: parent
        focus: true

        Keys.onEscapePressed: win.canceled()
        Keys.onReturnPressed: win.apply()
        Keys.onEnterPressed: win.apply()

        MouseArea {
            anchors.fill: parent
            onClicked: function(e) { e.accepted = true }
        }

        BoxGlass {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(0.10, 0.10, 0.12, 0.72)
            light: Qt.rgba(1, 1, 1, 0.22)
            rimStrength: 1.4
        }

        ColumnLayout {
            id: _col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 14

            CFClippingRect {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 192
                Layout.preferredHeight: 112
                radius: 10
                color: "#25000000"

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
                color: "#FFFFFF"
                font.family: "SF Pro Text"
                font.pixelSize: 15
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
                        radius: 14
                        color: _chip.on ? Theme.accent : (_mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.14))
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, _chip.on ? 0.35 : 0.18)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: ("0" + _chip.index).slice(-2) + ":00"
                            color: _chip.on ? Theme.onAccent : "#FFFFFF"
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
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Item {
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 32

                    BoxGlass {
                        anchors.fill: parent
                        radius: 16
                        color: _cancelArea.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.14)
                        light: Qt.rgba(1, 1, 1, 0.3)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Annuler")
                        color: "#FFFFFF"
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: _cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.canceled()
                    }
                }

                Item {
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 32
                    opacity: win.selectedCount > 0 ? 1 : 0.45

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: _applyArea.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                    }

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Appliquer")
                        color: Theme.onAccent
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: _applyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: win.selectedCount > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.apply()
                    }
                }
            }
        }
    }
}
