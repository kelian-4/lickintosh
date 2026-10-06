import QtQuick
import QtQuick.Layouts

Item {
    id: root

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
        CalendarModule {}
        Divider {}
        TasksModule {}
        Divider {}
        FocusModule {}
        Divider {}
        ProfilePhotoModule {}
    }
}
