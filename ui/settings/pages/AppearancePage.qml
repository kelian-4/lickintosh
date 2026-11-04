pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    component StyleTile: Item {
        id: tile

        required property string label
        required property bool selected
        property string palette: "glass"
        property color windowTint: tile.pal.window
        property color sidebarTint: tile.pal.panel
        signal picked()

        readonly property var pal: Theme.palettes[tile.palette]

        implicitWidth: 132
        implicitHeight: 84 + 8 + _label.implicitHeight

        Rectangle {
            id: _preview
            width: 132
            height: 84
            radius: 10
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a6fd8" }
                GradientStop { position: 0.55; color: "#8a5bd0" }
                GradientStop { position: 1.0; color: "#e0728a" }
            }

            Rectangle {
                x: 10
                y: 10
                width: 84
                height: 52
                radius: 6
                color: tile.windowTint
                border.width: 1
                border.color: tile.pal.panelRim
                clip: true

                Rectangle {
                    width: 22
                    height: parent.height
                    color: tile.sidebarTint
                }

                Rectangle { x: 28; y: 8;  width: 40; height: 4; radius: 2; color: tile.pal.textSecondary }
                Rectangle { x: 28; y: 18; width: 52; height: 3; radius: 1.5; color: tile.pal.textTertiary }
                Rectangle { x: 28; y: 25; width: 46; height: 3; radius: 1.5; color: tile.pal.textTertiary }
                Rectangle { x: 28; y: 36; width: 20; height: 7; radius: 3.5; color: tile.pal.accent }
            }

            Rectangle {
                width: 38
                height: 5
                radius: 2.5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                color: "#66ffffff"
            }
        }

        Rectangle {
            anchors.fill: _preview
            anchors.margins: -4
            radius: 14
            color: "transparent"
            border.width: 3
            border.color: Theme.accent
            visible: tile.selected
        }

        CFText {
            id: _label
            anchors.top: _preview.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: _preview.horizontalCenter
            text: tile.label
            font.pixelSize: 12
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
            gray: !tile.selected
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.picked()
        }
    }

    ContentSection {
        title: "Style de l'interface"

        Flow {
            Layout.fillWidth: true
            spacing: 20

            StyleTile {
                label: "Liquid Glass"
                selected: Theme.mode === "glass"
                palette: "glass"
                windowTint: "#40ffffff"
                sidebarTint: "#30ffffff"
                onPicked: Theme.setMode("glass")
            }

            StyleTile {
                label: "Clair"
                selected: Theme.mode === "light"
                palette: "light"
                windowTint: "#99ffffff"
                sidebarTint: "#66ffffff"
                onPicked: Theme.setMode("light")
            }

            StyleTile {
                label: "Sombre"
                selected: Theme.mode === "dark"
                palette: "dark"
                windowTint: "#99000000"
                sidebarTint: "#66000000"
                onPicked: Theme.setMode("dark")
            }
        }
    }

    ContentSection {
        title: "Thème de flou Hyprland"

        CFText {
            Layout.fillWidth: true
            text: "Rend toutes les fenêtres translucides avec le flou choisi, quel que soit le style de l'interface."
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: 20

            StyleTile {
                label: "Aucun"
                selected: !Theme.compositorBlur
                palette: "glass"
                windowTint: "#40ffffff"
                sidebarTint: "#30ffffff"
                onPicked: Theme.setBlurPreset("")
            }

            Repeater {
                model: Theme.blurPresets

                StyleTile {
                    id: presetTile

                    required property var modelData

                    label: presetTile.modelData.name
                    selected: Theme.blurPreset === presetTile.modelData.id
                    palette: "glass"
                    windowTint: "#a0101010"
                    sidebarTint: "#50101010"
                    onPicked: Theme.setBlurPreset(presetTile.modelData.id)
                }
            }
        }

        CFText {
            Layout.fillWidth: true
            visible: Theme.compositorBlur && Theme.blurPresetData !== null
            text: Theme.blurPresetData ? Theme.blurPresetData.description : ""
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        ConfigSlider {
            visible: Theme.compositorBlur
            text: "Opacité des fenêtres"
            from: 0.3
            to: 1.0
            decimals: 2
            value: Theme.blurWindowOpacity
            onMoved: function(v) { Theme.setBlurWindowOpacity(v) }
        }

        CFText {
            Layout.fillWidth: true
            visible: Theme.lastError.length > 0
            text: "Hyprland a refusé le préréglage : " + Theme.lastError
            font.pixelSize: 12
            color: "#ff453a"
            wrapMode: Text.WordWrap
        }
    }
}
