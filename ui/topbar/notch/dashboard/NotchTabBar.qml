import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property int currentIndex: 0

    readonly property var tabs: [
        { label: "Dashboard",   icon: "grid.svg" },
        { label: "Performance", icon: "bar-chart2.svg" }
    ]

    Layout.fillWidth: true
    implicitHeight: 28

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 6

        Repeater {
            model: root.tabs

            delegate: Rectangle {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: root.currentIndex === tab.index

                width: tabContent.implicitWidth + 24
                height: 28
                radius: 14
                color: tab.active ? "#1F1F1F" : "transparent"

                Row {
                    id: tabContent
                    anchors.centerIn: parent
                    spacing: 6

                    TintedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 14
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + tab.modelData.icon)
                        tint: tab.active ? "#FFFFFF" : "#8A8A8A"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.active ? "#FFFFFF" : "#8A8A8A"
                        font.pixelSize: 13
                        font.bold: tab.active
                        font.family: "SF Pro Rounded"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentIndex = tab.index
                }
            }
        }
    }
}
