import qs.services
import QtQuick
import QtQuick.Layouts
import qs.ui.topbar.menubar.activewindows
import qs.ui.topbar.menubar.globalmenu

RowLayout {
    id: menuBarRoot
    spacing: 16
    signal appleClicked()
    property bool appleActive: false

    Text {
        id: appleBtn
        text: ""
        color: appleActive ? Qt.alpha(Theme.ink(menuBarRoot, false), 0.7) : Theme.ink(menuBarRoot, false)
        font.pixelSize: 18
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: menuBarRoot.appleClicked()
        }
    }

    ActiveWindow {
        Layout.alignment: Qt.AlignVCenter
    }

    GlobalMenuBar {
        Layout.alignment: Qt.AlignVCenter
    }
}
