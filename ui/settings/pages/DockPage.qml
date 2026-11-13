import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.ui.settings.widgets

ContentPage {
    id: root

    ContentSection {
        title: I18n.tr("Dock")

        ConfigSwitch {
            text: I18n.tr("Masquer et afficher automatiquement le Dock")
            checked: ShellConfig.options.dockAppearance.hoverToReveal
            onToggled: function(v) { ShellConfig.options.dockAppearance.hoverToReveal = v }
        }

        ConfigSlider {
            text: I18n.tr("Taille")
            value: ShellConfig.options.dockAppearance.iconSize
            from: 32
            to: 84
            decimals: 0
            valueSuffix: " px"
            onMoved: function(v) { ShellConfig.options.dockAppearance.iconSize = Math.round(v) }
        }

        ConfigSlider {
            text: I18n.tr("Échelle du Dock")
            value: ShellConfig.options.dockAppearance.iconScale
            from: 0.8
            to: 1.6
            decimals: 2
            onMoved: function(v) { ShellConfig.options.dockAppearance.iconScale = v }
        }

        ConfigSlider {
            text: I18n.tr("Débordement des icônes")
            value: ShellConfig.options.dockAppearance.iconOverflow
            from: -4
            to: 14
            decimals: 0
            valueSuffix: " px"
            onMoved: function(v) { ShellConfig.options.dockAppearance.iconOverflow = Math.round(v) }
        }

        ConfigSwitch {
            text: I18n.tr("Teinter les icônes")
            checked: ShellConfig.options.dockAppearance.iconTint
            onToggled: function(v) { ShellConfig.options.dockAppearance.iconTint = v }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            visible: ShellConfig.options.dockAppearance.iconTint

            Repeater {
                model: ["#0a84ff", "#bf5af2", "#ff375f", "#ff453a", "#ff9f0a", "#ffd60a", "#30d158", "#40c8e0", "#8e8e93", "#ffffff", "#1c1c1e"]

                delegate: Rectangle {
                    id: _swatch
                    required property string modelData
                    width: 26
                    height: 26
                    radius: 13
                    color: _swatch.modelData
                    border.width: ShellConfig.options.dockAppearance.iconTintColor === _swatch.modelData ? 3 : 1
                    border.color: ShellConfig.options.dockAppearance.iconTintColor === _swatch.modelData ? Theme.accent : "#33ffffff"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellConfig.options.dockAppearance.iconTintColor = _swatch.modelData
                    }
                }
            }
        }

        ConfigSlider {
            text: I18n.tr("Intensité de la teinte")
            visible: ShellConfig.options.dockAppearance.iconTint
            value: ShellConfig.options.dockAppearance.iconTintStrength
            from: 0.2
            to: 1.0
            decimals: 2
            onMoved: function(v) { ShellConfig.options.dockAppearance.iconTintStrength = v }
        }

        ConfigSwitch {
            text: I18n.tr("Grossissement à l'approche du curseur")
            checked: ShellConfig.options.dockAppearance.magnificationEnabled
            onToggled: function(v) { ShellConfig.options.dockAppearance.magnificationEnabled = v }
        }

        ConfigSlider {
            text: I18n.tr("Niveau de grossissement")
            visible: ShellConfig.options.dockAppearance.magnificationEnabled
            value: ShellConfig.options.dockAppearance.magnification
            from: 1.0
            to: 2.0
            decimals: 2
            onMoved: function(v) { ShellConfig.options.dockAppearance.magnification = v }
        }

        ConfigSwitch {
            text: I18n.tr("Icônes monochromes")
            checked: ShellConfig.options.dockAppearance.monochromeIcons
            onToggled: function(v) { ShellConfig.options.dockAppearance.monochromeIcons = v }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
