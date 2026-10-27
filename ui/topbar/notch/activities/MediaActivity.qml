import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    RowLayout {
        anchors.fill: parent
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 90
            Layout.preferredHeight: 90
            radius: 10
            color: "#1E1E1E"
            clip: true

            Image {
                anchors.fill: parent
                source: MprisState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MprisState.artUrl !== ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: MprisState.hasPlayer ? MprisState.trackTitle : "Aucune lecture en cours"
                color: "#FFFFFF"
                font.pixelSize: 14
                font.bold: true
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: MprisState.trackArtist
                color: "#B0B0B0"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
                visible: text !== ""
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: "#3A3A3A"
                visible: MprisState.length > 0

                Rectangle {
                    width: parent.width * (MprisState.length > 0 ? Math.min(1, MprisState.position / MprisState.length) : 0)
                    height: parent.height
                    radius: parent.radius
                    color: "#FFFFFF"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 20

                Item { Layout.fillWidth: true }

                Text {
                    text: "⏮"
                    color: MprisState.canGoPrevious ? "#FFFFFF" : "#4A4A4A"
                    font.pixelSize: 16
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canGoPrevious; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.previous() }
                }
                Text {
                    text: MprisState.isPlaying ? "⏸" : "▶"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canTogglePlaying; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.togglePlaying() }
                }
                Text {
                    text: "⏭"
                    color: MprisState.canGoNext ? "#FFFFFF" : "#4A4A4A"
                    font.pixelSize: 16
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canGoNext; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.next() }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
