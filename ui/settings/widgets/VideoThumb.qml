import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.components
import qs.services

Item {
    id: root

    property string path: ""
    property bool selected: false
    property string label: String(path).split("/").pop()

    signal clicked()

    implicitWidth: 148
    implicitHeight: 104

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Item {
            id: _thumbArea
            Layout.fillWidth: true
            Layout.preferredHeight: 82

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#20ffffff"
            }

            Item {
                id: _maskShape
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "#fff"
                }
            }

            Loader {
                anchors.fill: parent
                source: "../../../components/VideoFrame.qml"
                onLoaded: item.source = Qt.binding(function() { return root.path })
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: _maskShape
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: 10
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                visible: root.selected
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#30ffffff"
                visible: _ma.containsMouse && !root.selected
            }

            MouseArea {
                id: _ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }

        CFText {
            text: root.label
            font.pixelSize: 11
            gray: !root.selected
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
