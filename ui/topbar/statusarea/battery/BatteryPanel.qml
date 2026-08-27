pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.components
import qs.services

Item {
    id: root
    signal closeRequested()
    property bool needsKeyboard: false
  
    implicitHeight: content.implicitHeight + 24

    readonly property bool onBattery: UPower.onBattery
    readonly property real batPercentage: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 1
    readonly property bool charging: onBattery ? (UPower.displayDevice.state === 1) : true
    readonly property string powerSourceText: onBattery ? "Battery" : "Power Adapter"
    readonly property string currentProfile: ShellConfig.powerProfile

    readonly property var profiles: [
        { id: "balanced", label: "Automatic", icon: "battery/battery-100.svg" },
        { id: "power-saver", label: "Low Power", icon: "battery/battery-010.svg" },
        { id: "performance", label: "High Power", icon: "battery/battery-100-charging.svg" }
    ]

    function setProfile(profileId) {
        ShellConfig.setPowerProfile(profileId)
    }

    readonly property var topConsumers: ShellConfig.topConsumers
    readonly property bool hasCollectedOnce: ShellConfig.hasCollectedOnce
    function formatMemory(mb) { return ShellConfig.formatMemory(mb) }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            CFText {
                text: "Battery"
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            CFText {
                text: Math.round(root.batPercentage * 100) + "%"
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }

        CFText {
            text: "Power Source: " + root.powerSourceText
            gray: true
            font.pixelSize: 12
            font.weight: Font.Bold
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Energy Mode"
                gray: true
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.profiles

                    Rectangle {
                        id: profileRow
                        required property var modelData
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: rowMouse.containsMouse ? "#14ffffff" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: modelData.id === root.currentProfile ? "#1C7AFF" : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                CFVI {
                                    anchors.centerIn: parent
                                    icon: modelData.icon
                                    size: 16
                                    color: "#ffffff"
                                }
                            }

                            CFText {
                                text: modelData.label
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setProfile(modelData.id)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Energy Usage"
                gray: true
                font.pixelSize: 11
                font.weight: Font.Bold
            }

	    CFText {
                visible: root.topConsumers.length === 0
                text: root.hasCollectedOnce ? "No Apps Using Significant Energy" : "Calculating..."
                gray: true
                font.pixelSize: 12
            }

            ColumnLayout {
                visible: root.topConsumers.length > 0
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.topConsumers.slice(0, 3)

                    Rectangle {
                        id: usageRow
                        required property var modelData
                        Layout.fillWidth: true
                        height: 48
                        radius: 8
                        color: usageMouse.containsMouse ? "#14ffffff" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: "#20ffffff"
                                Layout.alignment: Qt.AlignVCenter
                                clip: true

                                Image {
                                    id: usageIco
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: source !== "" && status === Image.Ready
                                    source: modelData.icon || ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    asynchronous: true
                                }

                                CFText {
                                    anchors.centerIn: parent
                                    visible: !usageIco.visible
                                    text: modelData.name.length > 0 ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                CFText {
                                    text: modelData.name
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

				CFText {
                                    text: "CPU " + modelData.cpu.toFixed(1) + "%  ·  RAM " + root.formatMemory(modelData.rssMb) + "  ·  Swap " + modelData.swap.toFixed(1) + " MB"
                                    gray: true
                                    font.pixelSize: 11
                                }

                            }
                        }

                        MouseArea {
                            id: usageMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        MouseArea {
            Layout.fillWidth: true
            height: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()

            CFText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Battery Settings..."
                font.pixelSize: 13
            }
        }
    }
}
