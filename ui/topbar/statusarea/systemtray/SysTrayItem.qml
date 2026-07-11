import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

MouseArea {
    id: root

    required property SystemTrayItem item
    property int trayItemSize: 22

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitHeight: trayItemSize
    implicitWidth: trayItemSize

    hoverEnabled: true

    onClicked: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            
            if (item.hasMenu) {
                 
                 item.activate();
            }
            break;
        }
        event.accepted = true;
    }

    IconImage {
        id: trayIcon
        anchors.fill: parent
        anchors.margins: 2
        source: root.item.icon

    }
}
