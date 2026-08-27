import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    ContentSection {
        title: "Dock"

        ConfigSwitch {
            text: "Afficher le Dock"
            checked: ShellConfig.options.dockAppearance.enable
            onToggled: function(v) { ShellConfig.options.dockAppearance.enable = v }
        }

        ConfigSwitch {
            text: "Révéler au survol"
            description: "Le Dock apparaît quand le curseur atteint le bord de l'écran"
            checked: ShellConfig.options.dockAppearance.hoverToReveal
            onToggled: function(v) { ShellConfig.options.dockAppearance.hoverToReveal = v }
        }

        ConfigSwitch {
            text: "Icônes monochromes"
            checked: ShellConfig.options.dockAppearance.monochromeIcons
            onToggled: function(v) { ShellConfig.options.dockAppearance.monochromeIcons = v }
        }
    }

    ContentSection {
        title: "Apparence"

        ConfigSlider {
            text: "Hauteur"
            value: ShellConfig.options.dockAppearance.height
            from: 40
            to: 100
            decimals: 0
            valueSuffix: " px"
            onMoved: function(v) { ShellConfig.options.dockAppearance.height = Math.round(v) }
        }
    }
}
