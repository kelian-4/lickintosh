import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    signal closeRequested()

    readonly property bool onBattery:   UPower.onBattery
    readonly property real batPct:      UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 1
    readonly property bool charging:    !onBattery

    property string _energyMode: "normal"

    implicitHeight: _col.implicitHeight + 20

    Process {
        id: _setPowerMode
        command: []
    }

    function _applyMode(mode) {
        _energyMode = mode
        if (mode === "low") {
            _setPowerMode.command = ["powerprofilesctl", "set", "power-saver"]
        } else if (mode === "performance") {
            _setPowerMode.command = ["powerprofilesctl", "set", "performance"]
        } else {
            _setPowerMode.command = ["powerprofilesctl", "set", "balanced"]
        }
        _setPowerMode.running = true
    }

    Process {
        id: _getModeProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t === "power-saver")  root._energyMode = "low"
                else if (t === "performance") root._energyMode = "performance"
                else                          root._energyMode = "normal"
            }
        }
    }

    Component.onCompleted: _getModeProc.running = true

    Column {
        id: _col
        width:             parent.width
        anchors.top:       parent.top
        anchors.topMargin: 10
        spacing:           0

        Item {
            width:  parent.width
            height: 54

            CFText {
                text:           "Batterie"
                font.weight:    Font.Bold
                font.pixelSize: 18
                anchors.left:           parent.left
                anchors.leftMargin:     20
                anchors.verticalCenter: parent.verticalCenter
            }

            CFText {
                text:           Math.round(root.batPct * 100) + "%"
                font.pixelSize: 15
                font.weight:    Font.Bold
                color:          root.charging ? "#30D158" : "#ffffff"
                anchors.right:          parent.right
                anchors.rightMargin:    20
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width:  parent.width - 40
            height: 1
            color:  "#20ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { width: parent.width; height: 10 }

        CFText {
            text:           "Source d'alimentation"
            font.pixelSize: 13
            gray:           true
            leftPadding:    20
            bottomPadding:  2
        }

        CFText {
            text:           root.onBattery ? "Batterie" : "Secteur"
            font.pixelSize: 14
            font.weight:    Font.SemiBold
            leftPadding:    20
            bottomPadding:  10
        }

        Rectangle {
            width:  parent.width - 40
            height: 1
            color:  "#10ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { width: parent.width; height: 10 }

        CFText {
            text:           "Mode énergie"
            font.pixelSize: 13
            gray:           true
            leftPadding:    20
            bottomPadding:  8
        }

        Repeater {
            model: [
                { id: "low",         label: "Économie d'énergie", icon: "notch/battery.svg" },
                { id: "normal",      label: "Normal",              icon: "settings/battery.svg" },
                { id: "performance", label: "Performance",         icon: "notch/zap.svg" }
            ]
            delegate: Item {
                required property var modelData
                width:   parent.width
                height:  44
                property bool _hovered:  false
                property bool _selected: root._energyMode === modelData.id

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: 6
                    radius:          10
                    color:           _selected ? Qt.rgba(1,1,1,0.12) : (_hovered ? Qt.rgba(1,1,1,0.06) : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors {
                        fill:        parent
                        leftMargin:  20
                        rightMargin: 20
                    }
                    spacing: 12

                    CFClippingRect {
                        width:  30
                        height: 30
                        radius: 15
                        color:  _selected ? "#fff" : Qt.rgba(1,1,1,0.18)
                        CFVI {
                            anchors.centerIn: parent
                            icon:  modelData.icon
                            size:  18
                            color: _selected ? "#1C7AFF" : "#fff"
                        }
                    }

                    CFText {
                        text:             modelData.label
                        font.pixelSize:   14
                        Layout.fillWidth: true
                    }

                    CFVI {
                        icon:    "check.svg"
                        size:    16
                        color:   "#1C7AFF"
                        visible: _selected
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onEntered:    parent._hovered = true
                    onExited:     parent._hovered = false
                    onClicked:    root._applyMode(modelData.id)
                }
            }
        }

        Item { width: parent.width; height: 8 }

        Rectangle {
            width:  parent.width - 40
            height: 1
            color:  "#10ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width:  parent.width
            height: 44

            CFText {
                text:           "Paramètres batterie…"
                font.pixelSize: 14
                gray:           true
                anchors.left:           parent.left
                anchors.leftMargin:     20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
