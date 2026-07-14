import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.ui.topbar.statusarea

MouseArea {
    id: root
    required property SystemTrayItem item
    property var hostWindow: null
    property int trayItemSize: 22
    property bool showLabel: false
    property bool hovered: false
    property bool contextMenuOpen: false
    property int contextMenuX: 0

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: showLabel ? rowLayout.implicitWidth : trayItemSize
    implicitHeight: showLabel ? Math.max(trayItemSize, rowLayout.implicitHeight) : trayItemSize
    hoverEnabled: true

    readonly property string labelText: {
        if (item.title && item.title.length > 0) return item.title
        if (item.tooltipTitle && item.tooltipTitle.length > 0) return item.tooltipTitle
        if (item.id && item.id.length > 0) return item.id
        return "Application"
    }

    function openContextMenu(x) {
        root.contextMenuX = root.mapToItem(null, x, 0).x
        root.contextMenuOpen = true
    }

    onEntered: root.hovered = true
    onExited: root.hovered = false

    onClicked: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            if (item.onlyMenu === true && item.menu) {
                root.openContextMenu(event.x)
            } else {
                item.activate()
            }
            break
        case Qt.RightButton:
            if (item.menu) {
                root.openContextMenu(event.x)
            } else {
                item.secondaryActivate()
            }
            break
        }
        event.accepted = true
    }

    StatusSubMenuWindow {
        opened: root.contextMenuOpen
        xPos: root.contextMenuX
        onCloseRequested: root.contextMenuOpen = false
        contentComponent: Component {
            TrayContextMenuPanel {
                menuHandle: root.item.menu
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        spacing: 8

        Item {
            width: root.trayItemSize
            height: root.trayItemSize
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                id: trayIcon
                anchors.fill: parent
                anchors.margins: 2
                source: root.item.icon
            }
        }

        Text {
            visible: root.showLabel
            text: root.labelText
            color: "#FFFFFF"
            font.pixelSize: 13
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: root.showLabel
            elide: Text.ElideRight
        }
    }
}
