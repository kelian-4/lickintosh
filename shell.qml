//@ pragma UseQApplication
//@ pragma ShellId main-shell
import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import qs.services
import qs.ui.topbar.statusarea
import qs.ui.topbar.statusarea.ai
import qs.ui.topbar.statusarea.battery
import qs.ui.topbar.statusarea.volume
import qs.ui.topbar.statusarea.controlcenter.panels
import qs.ui.topbar.statusarea.notifcenter
import qs.ui.topbar
import qs.ui.topbar.statusarea.controlcenter
import qs.ui.topbar.menubar.applemenu
import qs.ui.dock
import qs.ui.topbar.notch
import qs.ui.topbar.statusarea.spotlight
import qs.ui.osd
import qs.ui.lockscreen


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

    readonly property bool anySubmenuOpened: ccOpened || appleMenuOpened || aboutOpened ||
        spotlightOpened || aiOpened || notifCenterOpened || wifiOpened || bluetoothOpened ||
        batteryOpened || volumeOpened

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: topBarWindow
            required property var modelData
            property bool _revealed: true
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 32
            color: "transparent"
            exclusiveZone: ShellConfig.options.menuBar.autoHide ? 0 : implicitHeight

            Connections {
                target: ShellConfig.options.menuBar
                function onAutoHideChanged() {
                    if (ShellConfig.options.menuBar.autoHide) {
                        if (!appRoot.anySubmenuOpened) _topBarHideTimer.restart()
                    } else {
                        _topBarHideTimer.stop()
                        topBarWindow._revealed = true
                    }
                }
            }

            Connections {
                target: appRoot
                function onAnySubmenuOpenedChanged() {
                    if (!ShellConfig.options.menuBar.autoHide) return
                    if (appRoot.anySubmenuOpened) {
                        _topBarHideTimer.stop()
                        topBarWindow._revealed = true
                    } else if (!_topBarLeaveDetector.hovered) {
                        _topBarHideTimer.restart()
                    }
                }
            }

            Component.onCompleted: {
                if (ShellConfig.options.menuBar.autoHide && !appRoot.anySubmenuOpened) _topBarHideTimer.restart()
            }

            MouseArea {
                id: _topBarTriggerZone
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 4
                hoverEnabled: true
                visible: ShellConfig.options.menuBar.autoHide && !topBarWindow._revealed
                z: 10
                onEntered: {
                    _topBarHideTimer.stop()
                    topBarWindow._revealed = true
                }
            }

            Timer {
                id: _topBarHideTimer
                interval: 700
                onTriggered: {
                    if (ShellConfig.options.menuBar.autoHide && !appRoot.anySubmenuOpened) topBarWindow._revealed = false
                }
            }

            TopBar {
                id: _topBarItem
                hostWindow:       topBarWindow
                anchors.topMargin: (ShellConfig.options.menuBar.autoHide && !topBarWindow._revealed) ? -implicitHeight : 0
                Behavior on anchors.topMargin {
                    enabled: ShellConfig.options.menuBar.autoHide
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                HoverHandler {
                    id: _topBarLeaveDetector
                    enabled: ShellConfig.options.menuBar.autoHide
                    onHoveredChanged: {
                        if (!ShellConfig.options.menuBar.autoHide) return
                        if (hovered) {
                            _topBarHideTimer.stop()
                        } else if (!appRoot.anySubmenuOpened) {
                            _topBarHideTimer.restart()
                        }
                    }
                }
                appleMenuOpened:  appRoot.appleMenuOpened
                spotlightOpened:  appRoot.spotlightOpened
                notifUnreadCount: NotifService.trackedCount
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
        onLockRequested:  lockScreen.lock()
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
    Notch {
        notifServer: _globalNotifServer
    }
    SpotlightWindow {
        opened: appRoot.spotlightOpened
        onCloseRequested: appRoot.spotlightOpened = false
    	onOpenRequested:  appRoot.spotlightOpened = true
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

    LockScreen {
        id: lockScreen
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
