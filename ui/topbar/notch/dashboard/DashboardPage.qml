import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string expandedKind: ""
    property bool expandedOpen: false
    property real originX: 0
    property real originWidth: 0
    property real progress: root.expandedOpen ? 1 : 0

    Behavior on progress { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function openExpanded(kind, source) {
        var p = source.mapToItem(root, 0, 0)
        root.originX = p.x
        root.originWidth = source.width
        root.expandedKind = kind
        root.expandedOpen = true
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
        CalendarModule { id: calendar; onActivated: root.openExpanded("calendar", calendar) }
        Divider {}
        TasksModule { id: tasks; onActivated: root.openExpanded("tasks", tasks) }
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
        x: root.originX * (1 - root.progress)
        width: root.originWidth + (root.width - root.originWidth) * root.progress
        height: root.height

        Rectangle {
            anchors.fill: parent
            color: "#0A0A0A"
        }

        MouseArea {
            anchors.fill: parent
        }

        CalendarExpanded {
            visible: root.expandedKind === "calendar"
            x: -overlay.x
            width: root.width
            height: root.height
            onCloseRequested: root.expandedOpen = false
        }

        TasksExpanded {
            visible: root.expandedKind === "tasks"
            x: -overlay.x
            width: root.width
            height: root.height
            onCloseRequested: root.expandedOpen = false
        }
    }
}
