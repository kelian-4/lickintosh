import Quickshell
import QtQuick
import "./ui/modules"
import "./ui/controlcenter"
import "./ui/components/menubar"
import "./ui/dock"
import "./ui/spotlight"

ShellRoot {
    id: appRoot
    FontLoader { source: "assets/fonts/SFPD" }
    FontLoader { source: "assets/fonts/SFPR" }
    property bool ccOpened:        false
    property bool appleMenuOpened: false
    property bool aboutOpened:     false
    property bool spotlightOpened: false

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
                appleMenuOpened: appRoot.appleMenuOpened
                spotlightOpened: appRoot.spotlightOpened
                onToggleCC:        appRoot.ccOpened        = !appRoot.ccOpened
                onToggleAppleMenu: appRoot.appleMenuOpened = !appRoot.appleMenuOpened
                onToggleSpotlight: appRoot.spotlightOpened = !appRoot.spotlightOpened
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
}
