//@ pragma IconTheme MacTahoe-dark
//@ pragma UseQApplication
//@ pragma ShellId main-shell
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
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
import qs.ui.topbar.statusarea.spotlight
import qs.ui.osd
import qs.ui.lockscreen
import qs.ui.desktop
import qs.ui.widgets


ShellRoot {
    id: appRoot
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
    property bool interfaceShown:    false
    property bool startupDecided:    false

    Connections {
        target: WorkspaceWatcher

        function onChanged() {
            appRoot.ccOpened          = false
            appRoot.appleMenuOpened   = false
            appRoot.spotlightOpened   = false
            appRoot.aiOpened          = false
            appRoot.notifCenterOpened = false
            appRoot.wifiOpened        = false
            appRoot.bluetoothOpened   = false
            appRoot.batteryOpened     = false
            appRoot.volumeOpened      = false
            NotchState.close()
        }
    }

    readonly property bool anySubmenuOpened: ccOpened || appleMenuOpened || aboutOpened ||
        spotlightOpened || aiOpened || notifCenterOpened || wifiOpened || bluetoothOpened ||
        batteryOpened || volumeOpened || NotchState.expanded

    Variants {
        model: appRoot.interfaceShown ? Quickshell.screens : []
        PanelWindow {
            id: topBarWindow
            required property var modelData
            property bool _revealed: true
            readonly property int barHeight: 32
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 420
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: ShellConfig.options.menuBar.autoHide ? 0 : barHeight
            WlrLayershell.keyboardFocus: NotchState.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: NotchState.visualState === "idle" ? _barMask : _fullMask

            Region {
                id: _barMask
                item: _topBarItem
                Region { item: _topBarTriggerZone }
            }

            Region {
                id: _fullMask
                item: _topBarItem
                Region { item: _topBarTriggerZone }
                Region { item: _topBarItem.notchExpandedPanel }
            }

            HyprlandFocusGrab {
                active: NotchState.expanded
                windows: [topBarWindow]
                onCleared: NotchState.close()
            }

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
                notifServer:      _globalNotifServer
                anchors.topMargin: (ShellConfig.options.menuBar.autoHide && !topBarWindow._revealed) ? -topBarWindow.barHeight : 0
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
        onPowerRequested: function(action) { PowerState.request(action) }
    }
    PowerConfirmWindow {
        action: PowerState.action
        onCancelled: PowerState.clear()
        onConfirmed: function(action) {
            PowerState.clear()
            var cmd = ""
            if (action === "poweroff")
                cmd = "hyprshutdown -t 'Extinction...' --post-cmd 'systemctl poweroff' || systemctl poweroff"
            else if (action === "reboot")
                cmd = "hyprshutdown -t 'Redémarrage...' --post-cmd 'systemctl reboot' || systemctl reboot"
            else if (action === "bios")
                cmd = "hyprshutdown -t 'Redémarrage vers le BIOS...' --post-cmd 'systemctl reboot --firmware-setup' || systemctl reboot --firmware-setup"
            else if (action === "logout")
                cmd = "hyprshutdown -t 'Déconnexion...' || hyprctl dispatch 'hl.dsp.exit()'"
            if (cmd.length > 0)
                Quickshell.execDetached(["sh", "-c", cmd])
        }
    }
    AboutWindow {
        opened: appRoot.aboutOpened
        onCloseRequested: appRoot.aboutOpened = false
    }
    ControlCenter {
        opened: appRoot.ccOpened
        onClosing: appRoot.ccOpened = false
    }
    ControlGallery {}
    LazyLoader { active: appRoot.interfaceShown; DesktopLayer {} }
    WidgetGallery {}
    LazyLoader { active: appRoot.interfaceShown; Dock {} }
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

    Process {
        id: startupLockCheck
        command: ["sh", "-c", "m=\"${XDG_RUNTIME_DIR:-/tmp}/lickintosh-startup-lock\"; if [ -e \"$m\" ]; then echo skip; else : > \"$m\"; echo lock; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "lock") lockScreen.lock()
                else appRoot.interfaceShown = true
            }
        }
    }

    function decideStartup() {
        if (startupDecided || !ShellConfig.ready) return
        startupDecided = true
        if (ShellConfig.options.lockscreen.lockAtStartup) startupLockCheck.running = true
        else interfaceShown = true
    }

    Connections {
        target: ShellConfig
        function onReadyChanged() { appRoot.decideStartup() }
    }

    Connections {
        target: lockScreen
        function onLockedChanged() {
            if (!lockScreen.locked && appRoot.startupDecided) appRoot.interfaceShown = true
        }
    }

    Timer {
        interval: 6000
        running: true
        onTriggered: {
            if (!appRoot.interfaceShown && !lockScreen.locked) appRoot.interfaceShown = true
        }
    }

    Component.onCompleted: appRoot.decideStartup()

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
