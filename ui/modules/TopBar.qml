import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import "../components/menubar"
import "../components/statusarea"

Rectangle {
    id: root
    signal toggleCC()
    signal toggleAppleMenu()
    signal toggleSpotlight()

    property bool appleMenuOpened: false
    property bool spotlightOpened: false

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
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onToggleCC:        root.toggleCC()
            onToggleSpotlight: root.toggleSpotlight()
        }
    }
}
