import QtQuick

Item {
    id: root

    property var window: null
    property bool hovered: false
    signal closeRequested()

    implicitHeight: 24

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: if (root.window) root.window.startSystemMove()
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 13
            height: 13
            radius: 7
            color: "#FF5F57"

            CFVI {
                anchors.centerIn: parent
                icon: "x-bold.svg"
                size: 8
                visible: root.hovered
                color: "#801A0000"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered = true
                onExited: root.hovered = false
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            width: 13
            height: 13
            radius: 7
            color: "#FEBC2E"

            CFVI {
                anchors.centerIn: parent
                icon: "windows/minimize.svg"
                size: 8
                visible: root.hovered
                color: "#80663D00"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered = true
                onExited: root.hovered = false
                onClicked: if (root.window) root.window.minimized = true
            }
        }
    }
}
