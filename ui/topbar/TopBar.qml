import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.ui.topbar.menubar
import qs.ui.topbar.statusarea

Rectangle {
    id: root
    signal toggleCC()
    signal toggleAppleMenu()
    signal toggleSpotlight()
    signal toggleAI()
    signal toggleNotifCenter()
    signal toggleWifi(int xPos)
    signal toggleBluetooth(int xPos)
    signal toggleBattery(int xPos)

    property bool appleMenuOpened:  false
    property bool spotlightOpened:  false
    property int  notifUnreadCount: 0

    readonly property color themeBackground: "transparent"
    readonly property int   themeHeight:     32
    readonly property int   themeMargin:     20

    implicitHeight: themeHeight
    color:          themeBackground

    anchors.top:   parent.top
    anchors.left:  parent.left
    anchors.right: parent.right

    FontLoader {
        id: macFont
        source: "../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    RowLayout {
        anchors.fill:        parent
        anchors.leftMargin:  root.themeMargin
        anchors.rightMargin: root.themeMargin

        MenuBar {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            appleActive: root.appleMenuOpened
            onAppleClicked: root.toggleAppleMenu()
        }

        Item {
            Layout.fillWidth:       true
            Layout.preferredHeight: root.themeHeight
        }

        StatusArea {
            Layout.alignment:  Qt.AlignRight | Qt.AlignVCenter
            notifUnreadCount:  root.notifUnreadCount
            onToggleCC:        root.toggleCC()
            onToggleSpotlight: root.toggleSpotlight()
            onToggleAI:        root.toggleAI()
            onToggleNotifCenter: root.toggleNotifCenter()
            onToggleWifi:      (x) => root.toggleWifi(x)
            onToggleBluetooth: (x) => root.toggleBluetooth(x)
            onToggleBattery:    (x) => root.toggleBattery(x)
        }
    }
}
