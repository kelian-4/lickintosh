pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.components
import qs.services

Item {
    id: root

    signal closeRequested()

    readonly property int rowHeight: 48
    readonly property int maxScrollHeight: 400

    readonly property var modes: [
        { mode: "glass", label: "Liquid Glass", icon: "settings/appearance.svg" },
        { mode: "light", label: "Clair", icon: "weather/sun.svg" },
        { mode: "dark", label: "Sombre", icon: "notch/moon.svg" }
    ]

    implicitHeight: _content.implicitHeight + 20

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property string icon: ""
        property bool picked: false
        signal activated()

        width: parent ? parent.width : 0
        height: root.rowHeight
        radius: height / 2
        color: pill.picked ? "#ffffff" : (pillMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.11))
        Behavior on color { ColorAnimation { duration: 160 } }

        CFVI {
            visible: pill.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            icon: pill.icon
            size: 22
            color: pill.picked ? "#000000" : "#ffffff"
        }

        CFText {
            anchors.centerIn: parent
            width: parent.width - 100
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: pill.label
            font.family: "SF Pro Text"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: pill.picked ? "#000000" : "#ffffff"
        }

        MouseArea {
            id: pillMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: pill.activated()
        }
    }

    Column {
        id: _content
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 0

        Item {
            width: parent.width
            height: 54

            CFText {
                text: I18n.tr("Theme")
                font.weight: Font.Bold
                font.pixelSize: 18
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width - 40
            height: 1
            color: "#20ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { width: parent.width; height: 10 }

        ScrollView {
            id: _scroll
            width: parent.width
            height: Math.min(_col.implicitHeight, root.maxScrollHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ScrollBar.vertical: ScrollBar {
                id: _vbar
                parent: _scroll
                x: _scroll.width - width
                width: 4
                policy: ScrollBar.AsNeeded

                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#50ffffff"
                    opacity: _vbar.pressed ? 0.9 : (_vbar.hovered ? 0.7 : 0.0)
                    Behavior on opacity { NumberAnimation { duration: ShellMotion.effects(0.75) } }
                }
                background: Item {}
            }

            Column {
                id: _col
                x: 14
                width: _scroll.width - 28
                spacing: 8

                CFText {
                    text: I18n.tr("Appearance")
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    leftPadding: 6
                    bottomPadding: 2
                }

                Repeater {
                    model: root.modes

                    delegate: Pill {
                        required property var modelData
                        label: I18n.tr(modelData.label)
                        icon: modelData.icon
                        picked: Theme.mode === modelData.mode
                        onActivated: Theme.setMode(modelData.mode)
                    }
                }

                CFText {
                    text: I18n.tr("Thème de flou Hyprland")
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    leftPadding: 6
                    topPadding: 10
                    bottomPadding: 2
                }

                Pill {
                    label: I18n.tr("Aucun")
                    picked: !Theme.compositorBlur
                    onActivated: Theme.setBlurPreset("")
                }

                Repeater {
                    model: Theme.blurPresets

                    delegate: Pill {
                        required property var modelData
                        label: I18n.tr(modelData.name)
                        picked: Theme.blurPreset === modelData.id
                        onActivated: Theme.setBlurPreset(modelData.id)
                    }
                }

                Item { width: 1; height: 4 }
            }
        }

        Item { width: parent.width; height: 6 }
    }
}
