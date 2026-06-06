import QtQuick
import QtQuick.Layouts

RowLayout {
    id: menuBarRoot
    spacing: 16

    signal appleClicked()

    property bool appleActive: false

    Text {
        id: appleBtn
        text: ""
        color: appleActive ? Qt.rgba(1,1,1,0.7) : "#FFFFFF"
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

    Text {
        text: "File"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: "Edit"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: "View"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: "Go"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: "Window"
        color: "#FFFFFF"
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }
}