import Quickshell
import QtQuick
import Quickshell.Services.Pipewire
import qs.ui.topbar.statusarea
import qs.ui.topbar.statusarea.ai
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

    property real brtValue:    0.65
    property real kbdBrtValue: 0.0

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 32
            color: "transparent"
            exclusiveZone: implicitHeight

            TopBar {
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

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    OSD {
        id: volumeOSD
        type:      "volume"
        label:     Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.description : "Volume"
        iconLow:   "volume/audio-volume-1.svg"
        iconHigh:  "volume/audio-volume-3.svg"
        fillColor: "#F5A623"
        value:     Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
    }

    OSD {
        id: brightnessOSD
        type:      "brightness"
        label:     "Luminosité"
        iconLow:   "sun-small.svg"
        iconHigh:  "sun-huge.svg"
        fillColor: "#1C7AFF"
        value:     appRoot.brtValue
    }

    OSD {
        id: kbdBrightnessOSD
        type:      "kbdbrt"
        label:     "Luminosité clavier"
        iconLow:   "brightness/display-brightness-off-symbolic.svg"
        iconHigh:  "brightness/display-brightness-symbolic.svg"
        fillColor: "#FFD60A"
        value:     appRoot.kbdBrtValue
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            volumeOSD.show()
        }
    }

    onBrtValueChanged:    brightnessOSD.show()
    onKbdBrtValueChanged: kbdBrightnessOSD.show()

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
}
