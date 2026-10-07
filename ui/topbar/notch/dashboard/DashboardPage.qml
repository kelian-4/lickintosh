import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool calendarOpen: false
    property real calendarX: 0
    property real calendarWidth: 0
    property real progress: root.calendarOpen ? 1 : 0

    Behavior on progress { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function openCalendar() {
        var p = calendar.mapToItem(root, 0, 0)
        root.calendarX = p.x
        root.calendarWidth = calendar.width
        root.calendarOpen = true
    }

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: "#262626"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 14

        MediaModule {}
        Divider {}
        CalendarModule { id: calendar; onActivated: root.openCalendar() }
        Divider {}
        TasksModule {}
        Divider {}
        FocusModule {}
        Divider {}
        ProfilePhotoModule {}
    }

    Item {
        id: overlay
        visible: root.progress > 0
        opacity: Math.min(1, root.progress * 2.5)
        clip: true
        x: root.calendarX * (1 - root.progress)
        width: root.calendarWidth + (root.width - root.calendarWidth) * root.progress
        height: root.height

        Rectangle {
            anchors.fill: parent
            color: "#0A0A0A"
        }

        MouseArea {
            anchors.fill: parent
        }

        CalendarExpanded {
            x: -overlay.x
            width: root.width
            height: root.height
            onCloseRequested: root.calendarOpen = false
        }
    }
}
