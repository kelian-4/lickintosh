import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root

    property int currentIndex: 0
    property real indicatorX: 0
    property real indicatorWidth: 0
    property bool settled: false

    readonly property var tabs: [
        { label: "Dashboard",   icon: "grid.svg" },
        { label: "Performance", icon: "bar-chart2.svg" }
    ]

    Layout.fillWidth: true
    implicitHeight: 28

    Timer {
        interval: 60
        running: true
        onTriggered: root.settled = true
    }

    Rectangle {
        id: indicator
        x: root.indicatorX
        width: root.indicatorWidth
        height: 28
        radius: 14
        color: "#1F1F1F"

        Behavior on x {
            enabled: root.settled
            NumberAnimation {
                duration: ShellMotion.spatial(0.6)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.spatialCurve
            }
        }

        Behavior on width {
            enabled: root.settled
            NumberAnimation {
                duration: ShellMotion.spatial(0.6)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.spatialCurve
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 6

        Repeater {
            model: root.tabs

            delegate: Item {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: root.currentIndex === tab.index

                width: tabContent.implicitWidth + 24
                height: 28

                Binding { target: root; property: "indicatorX"; value: tab.x; when: tab.active }
                Binding { target: root; property: "indicatorWidth"; value: tab.width; when: tab.active }

                Row {
                    id: tabContent
                    anchors.centerIn: parent
                    spacing: 6

                    TintedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 14
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + tab.modelData.icon)
                        tint: tab.active ? "#FFFFFF" : "#8A8A8A"

                        Behavior on tint { ColorAnimation { duration: ShellMotion.effects(0.8) } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.active ? "#FFFFFF" : "#8A8A8A"
                        font.pixelSize: 13
                        font.bold: tab.active
                        font.family: "SF Pro Text"

                        Behavior on color { ColorAnimation { duration: ShellMotion.effects(0.8) } }
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
