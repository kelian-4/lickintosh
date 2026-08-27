import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    ContentSection {
        title: "Éléments affichés"

        ConfigSwitch {
            text: "Horloge"
            checked: ShellConfig.options.topbar.showClock
            onToggled: function(v) { ShellConfig.options.topbar.showClock = v }
        }

        ConfigSwitch {
            text: "Batterie"
            checked: ShellConfig.options.topbar.showBattery
            onToggled: function(v) { ShellConfig.options.topbar.showBattery = v }
        }

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
    }

    ContentSection {
        title: "Apparence"

        ConfigSlider {
            text: "Hauteur de la barre"
            value: ShellConfig.options.topbar.barHeight
            from: 24
            to: 48
            decimals: 0
            valueSuffix: " px"
            onMoved: function(v) { ShellConfig.options.topbar.barHeight = Math.round(v) }
        }
    }
}
