import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import qs.ui.topbar.menubar.globalmenu

RowLayout {
    id: root
    spacing: 16
    visible: GlobalMenuService.hasWindow
    property int openIndex: -1
    property int overflowStart: 999
    property int reservedLeft: 140
    property int reservedRight: 260

    function recomputeOverflow() {
        var avail = Window.width - root.reservedLeft - root.reservedRight
        var used = 0
        var cut = repeaterMain.count
        for (var i = 0; i < repeaterMain.count; i++) {
            var it = repeaterMain.itemAt(i)
            if (!it) continue
            used += it.implicitWidth + root.spacing
            if (used > avail) {
                cut = i
                break
            }
        }
        root.overflowStart = cut
    }

    function openMenu(index, x, items) {
        root.openIndex = index
        popup.xPos = x
        popup.yPos = 36
        popup.items = items
    }

    function openOverflow(x) {
        root.openIndex = -2
        overflowPopup.xPos = x
        overflowPopup.yPos = 36
        var hidden = []
        for (var i = root.overflowStart; i < GlobalMenuService.menus.length; i++) {
            hidden.push({ label: GlobalMenuService.menus[i].label, submenu: GlobalMenuService.menus[i].items })
        }
        overflowPopup.items = hidden
    }

    onWidthChanged: root.recomputeOverflow()
    Connections {
        target: GlobalMenuService
        function onMenusChanged() {
            root.recomputeOverflow()
            root.openIndex = -1
        }
        function onAppIdChanged() {
            root.openIndex = -1
        }
    }
    Component.onCompleted: root.recomputeOverflow()

    Repeater {
        id: repeaterMain
        model: GlobalMenuService.menus

        delegate: Text {
            id: menuLabel
            required property var modelData
            required property int index
            visible: index < root.overflowStart
            text: modelData.label
            color: "#FFFFFF"
            font.pixelSize: 13
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (root.openIndex !== -1 && root.openIndex !== menuLabel.index) {
                        var p = menuLabel.mapToItem(null, 0, menuLabel.height)
                        root.openMenu(menuLabel.index, p.x, menuLabel.modelData.items)
                    }
                }
                onClicked: {
                    if (root.openIndex === menuLabel.index) {
                        root.openIndex = -1
                    } else {
                        var p = menuLabel.mapToItem(null, 0, menuLabel.height)
                        root.openMenu(menuLabel.index, p.x, menuLabel.modelData.items)
                    }
                }
            }
        }
    }

    Text {
        id: overflowBtn
        visible: root.overflowStart < GlobalMenuService.menus.length
        text: "··"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (root.openIndex !== -1) {
                    var p = overflowBtn.mapToItem(null, 0, overflowBtn.height)
                    root.openOverflow(p.x)
                }
            }
            onClicked: {
                if (root.openIndex === -2) {
                    root.openIndex = -1
                } else {
                    var p = overflowBtn.mapToItem(null, 0, overflowBtn.height)
                    root.openOverflow(p.x)
                }
            }
        }
    }

    PopupMenu {
        id: popup
        opened: root.openIndex >= 0
        onCloseRequested: root.openIndex = -1
    }

    PopupMenu {
        id: overflowPopup
        opened: root.openIndex === -2
        onCloseRequested: root.openIndex = -1
    }
}
