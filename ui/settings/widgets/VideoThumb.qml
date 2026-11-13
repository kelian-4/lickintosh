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
                id: _frame
                anchors.fill: parent
                onStatusChanged: if (status === Loader.Error) console.warn("[wallpaper video] QtMultimedia introuvable : installer qt6-multimedia")
                source: "../../../components/VideoFrame.qml"
                onLoaded: item.source = Qt.binding(function() { return root.path })
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: _maskShape
                }
            }

            CFText {
                anchors.centerIn: parent
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: _frame.status === Loader.Error
                text: I18n.tr("Module QtMultimedia manquant")
                font.pixelSize: 11
                gray: true
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
