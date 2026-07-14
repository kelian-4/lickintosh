//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import qs.core.network
import qs.ui.topbar.statusarea
import qs.ui.topbar.statusarea.ai
import qs.ui.topbar.statusarea.battery
import qs.ui.topbar.statusarea.volume
import qs.ui.topbar.controlcenter.panels
import qs.ui.topbar.notifcenter
import qs.ui.topbar
import qs.ui.topbar.controlcenter
import qs.ui.topbar.menubar.applemenu
import qs.ui.dock
import qs.ui.topbar.spotlight
import qs.ui.osd


ShellRoot {
    id: appRoot
    FontLoader { source: "assets/fonts/SFPD" }
    FontLoader { source: "assets/fonts/SFPR" }
    property bool ccOpened:          false
    property bool appleMenuOpened:   false
    property bool aboutOpened:       false
    property bool spotlightOpened:   false
    property bool aiOpened:          false
    property bool notifCenterOpened: false
    property bool wifiOpened:        false
    property bool bluetoothOpened:   false
    property int  wifiX:             0
    property int  bluetoothX:        0
    property bool batteryOpened:     false
    property int  batteryX:          0
    property bool volumeOpened:      false
    property int  volumeX:           0

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: topBarWindow
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 32
            color: "transparent"
            exclusiveZone: implicitHeight

            TopBar {
                hostWindow:       topBarWindow
                appleMenuOpened:  appRoot.appleMenuOpened
                spotlightOpened:  appRoot.spotlightOpened
                notifUnreadCount: _globalNotifServer.trackedNotifications.length
                onToggleCC:           appRoot.ccOpened           = !appRoot.ccOpened
                onToggleAppleMenu:    appRoot.appleMenuOpened    = !appRoot.appleMenuOpened
                onToggleSpotlight:    appRoot.spotlightOpened    = !appRoot.spotlightOpened
                onToggleAI:           appRoot.aiOpened           = !appRoot.aiOpened
                onToggleNotifCenter:  appRoot.notifCenterOpened  = !appRoot.notifCenterOpened
                onToggleWifi:         (x) => { appRoot.wifiX = x; appRoot.wifiOpened = !appRoot.wifiOpened }
                onToggleBluetooth:    (x) => { appRoot.bluetoothX = x; appRoot.bluetoothOpened = !appRoot.bluetoothOpened }
                onToggleBattery:      (x) => { appRoot.batteryX = x; appRoot.batteryOpened = !appRoot.batteryOpened }
                onToggleVolume:       (x) => { appRoot.volumeX = x; appRoot.volumeOpened = !appRoot.volumeOpened }
            }
        }
    }

    AppleMenuWindow {
        opened: appRoot.appleMenuOpened
        onCloseRequested: appRoot.appleMenuOpened = false
        onOpenAbout:      appRoot.aboutOpened     = true
    }
    AboutWindow {
        opened: appRoot.aboutOpened
        onCloseRequested: appRoot.aboutOpened = false
    }
    ControlCenter {
        opened: appRoot.ccOpened
        onClosing: appRoot.ccOpened = false
    }
    Dock {}
    SpotlightWindow {
        opened: appRoot.spotlightOpened
        onCloseRequested: appRoot.spotlightOpened = false
    }
    AiWindow {
        opened: appRoot.aiOpened
        onClosing: appRoot.aiOpened = false
    }
    NotifCenter {
        opened:      appRoot.notifCenterOpened
        notifServer: _globalNotifServer
        onClosing:   appRoot.notifCenterOpened = false
    }
    NotifPopup {
        notifServer: _globalNotifServer
    }

    OSD {
        id: _osd
        blocked: appRoot.ccOpened
                 || appRoot.wifiOpened
                 || appRoot.bluetoothOpened
                 || appRoot.aiOpened
                 || appRoot.notifCenterOpened
                 || appRoot.spotlightOpened
        batteryShowing: _batteryOSD.isShowing
    }

    BatteryOSD {
        id: _batteryOSD
    }

    NotificationServer {
        id: _globalNotifServer
        keepOnReload:        true
        bodyMarkupSupported: true
        actionsSupported:    true
        imageSupported:      true
    }

    StatusSubMenuWindow {
        opened: appRoot.wifiOpened
        xPos: appRoot.wifiX
        onCloseRequested: appRoot.wifiOpened = false
        contentComponent: Component {
            CCWifiPanel {}
        }
    }

    StatusSubMenuWindow {
        opened: appRoot.bluetoothOpened
        xPos: appRoot.bluetoothX
        onCloseRequested: appRoot.bluetoothOpened = false
        contentComponent: Component {
            CCBluetoothPanel {}
        }
    }

    StatusSubMenuWindow {
        opened: appRoot.batteryOpened
        xPos: appRoot.batteryX
        onCloseRequested: appRoot.batteryOpened = false
        contentComponent: Component {
            BatteryPanel {}
        }
    }

    StatusSubMenuWindow {
        opened: appRoot.volumeOpened
        xPos: appRoot.volumeX
        onCloseRequested: appRoot.volumeOpened = false
        contentComponent: Component {
            VolumePanel {}
        }
    }
}
