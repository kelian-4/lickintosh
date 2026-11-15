import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.ui.topbar.menubar.activewindows
import qs.ui.topbar.menubar.globalmenu

RowLayout {
    id: menuBarRoot
    spacing: 16
    signal appleClicked()
    property bool appleActive: false

    Image {
        id: appleBtn
        source: Qt.resolvedUrl("../../../assets/pngs/linux-logo.png")
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        Layout.preferredHeight: 17
        Layout.preferredWidth: 17
        Layout.alignment: Qt.AlignVCenter
        opacity: appleActive ? 0.7 : 1.0
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: "#FFFFFF"
        }

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
