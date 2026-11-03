pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets

/*
    Réglages > Apparence

    Style de l'interface (Liquid Glass / Clair / Sombre) et préréglages de
    flou fournis par Hyprland. Chaque choix passe par Theme.setMode() :
    application immédiate, persistance dans ShellConfig.options.appearance.mode.
*/
ContentPage {
    id: root

    // Vignette cliquable façon Réglages Système de macOS : aperçu d'une
    // fenêtre dessiné avec la palette du mode, anneau d'accent si choisi.
    component StyleTile: Item {
        id: tile

        required property string modeId
        required property string label
        property string palette: "glass"          // clé de Theme.palettes
        property color  windowTint: tile.pal.window
        property color  sidebarTint: tile.pal.panel

        readonly property var  pal: Theme.palettes[tile.palette]
        readonly property bool selected: Theme.mode === tile.modeId

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
                id: _win
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
            onClicked: Theme.setMode(tile.modeId)
        }
    }

    ContentSection {
        title: "Style de l'interface"

        Flow {
            Layout.fillWidth: true
            spacing: 20

            StyleTile {
                modeId: "glass"
                label: "Liquid Glass"
                palette: "glass"
                windowTint: "#40ffffff"
                sidebarTint: "#30ffffff"
            }

            StyleTile {
                modeId: "light"
                label: "Clair"
                palette: "light"
            }

            StyleTile {
                modeId: "dark"
                label: "Sombre"
                palette: "dark"
            }
        }
    }

    ContentSection {
        title: "Flou Hyprland"

        CFText {
            Layout.fillWidth: true
            text: "Remplace le Liquid Glass par un flou fourni par le compositeur (Hyprland 0.57)."
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: 20

            Repeater {
                model: Theme.blurPresets

                StyleTile {
                    required property var modelData

                    modeId: "blur:" + modelData.id
                    label: modelData.name
                    palette: "blur"
                    windowTint: "#a0101010"
                    sidebarTint: "#50101010"
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
