import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    ContentSection {
        title: "Horloge"

        ConfigSwitch {
            text: "Afficher l'horloge"
            checked: ShellConfig.options.topbar.clockVisible
            onToggled: function(v) { ShellConfig.options.topbar.clockVisible = v }
        }

        ConfigSwitch {
            text: "Afficher la date"
            enabled: ShellConfig.options.topbar.clockVisible
            checked: ShellConfig.options.topbar.clockTextVisible
            onToggled: function(v) { ShellConfig.options.topbar.clockTextVisible = v }
        }

        ConfigSwitch {
            text: "Afficher le badge de notification"
            enabled: ShellConfig.options.topbar.clockVisible
            checked: ShellConfig.options.topbar.clockBadgeVisible
            onToggled: function(v) { ShellConfig.options.topbar.clockBadgeVisible = v }
        }
    }

    ContentSection {
        title: "Batterie"

        ConfigSwitch {
            text: "Afficher la batterie"
            checked: ShellConfig.options.topbar.batteryVisible
            onToggled: function(v) { ShellConfig.options.topbar.batteryVisible = v }
        }

        ConfigSwitch {
            text: "Afficher le texte"
            enabled: ShellConfig.options.topbar.batteryVisible
            checked: ShellConfig.options.topbar.batteryTextVisible
            onToggled: function(v) { ShellConfig.options.topbar.batteryTextVisible = v }
        }

        ConfigSwitch {
            text: "Afficher l'icône"
            enabled: ShellConfig.options.topbar.batteryVisible
            checked: ShellConfig.options.topbar.batteryIconVisible
            onToggled: function(v) { ShellConfig.options.topbar.batteryIconVisible = v }
        }
    }

    ContentSection {
        title: "Éléments affichés"

        ConfigSwitch {
            text: "Bluetooth"
            checked: ShellConfig.options.topbar.showBluetooth
            onToggled: function(v) { ShellConfig.options.topbar.showBluetooth = v }
        }

        ConfigSwitch {
            text: "Wi-Fi"
            checked: ShellConfig.options.topbar.showWifi
            onToggled: function(v) { ShellConfig.options.topbar.showWifi = v }
        }

        ConfigSwitch {
            text: "Icônes système (tray)"
            checked: ShellConfig.options.topbar.showSystemTray
            onToggled: function(v) { ShellConfig.options.topbar.showSystemTray = v }
        }

        ConfigSwitch {
            text: "Control Center"
            checked: ShellConfig.options.topbar.showControlCenter
            onToggled: function(v) { ShellConfig.options.topbar.showControlCenter = v }
        }

        ConfigSwitch {
            text: "IA"
            checked: ShellConfig.options.topbar.showAI
            onToggled: function(v) { ShellConfig.options.topbar.showAI = v }
        }

        ConfigSwitch {
            text: "Spotlight"
            checked: ShellConfig.options.topbar.showSpotlight
            onToggled: function(v) { ShellConfig.options.topbar.showSpotlight = v }
        }
    }

    ContentSection {
        title: "Comportement"

        ConfigSwitch {
            text: "Masquer et afficher automatiquement la barre"
            checked: ShellConfig.options.menuBar.autoHide
            onToggled: function(v) { ShellConfig.options.menuBar.autoHide = v }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
