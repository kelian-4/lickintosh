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
