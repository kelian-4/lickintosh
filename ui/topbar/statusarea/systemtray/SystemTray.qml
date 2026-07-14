import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.ui.primitives

RowLayout {
    id: root
    spacing: 8

    property var hostWindow: null
    property int maxVisibleItems: 3
    property bool expanded: false
    property real maxWidth: 200

    readonly property int iconSlotWidth: 30
    readonly property var allItems: SystemTray.items.values
    readonly property bool hasOverflow: root.allItems.length > root.maxVisibleItems
    readonly property var visibleItems: root.hasOverflow ? [] : root.allItems
    readonly property int maxOverflowCount: Math.max(1, Math.floor(root.maxWidth / root.iconSlotWidth))
    readonly property var overflowItems: root.hasOverflow ? root.allItems.slice(0, root.maxOverflowCount) : []

    Repeater {
        model: root.visibleItems
        delegate: SysTrayItem {
            required property var modelData
            item: modelData
            hostWindow: root.hostWindow
        }
    }

    Item {
        id: overflowClip
        clip: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: overflowRow.implicitHeight
        Layout.preferredWidth: root.expanded ? Math.min(overflowRow.implicitWidth, root.maxWidth) : 0

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: overflowRow
            spacing: 8
            height: parent.height

            Repeater {
                model: root.overflowItems
                delegate: SysTrayItem {
                    required property var modelData
                    item: modelData
                    hostWindow: root.hostWindow
                }
            }
        }
    }

    Item {
        id: chevronBtn
        visible: root.hasOverflow
        width: 16
        height: 16
        Layout.alignment: Qt.AlignVCenter

        CFVI {
            anchors.centerIn: parent
            icon: "chevron-left.svg"
            size: 14
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: 150 }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }
}
