import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root
    Layout.preferredWidth: 196
    Layout.fillHeight: true

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Item {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: artClip
                anchors.fill: parent
                radius: 12
                color: "#2A2A3A"
                clip: true

                Image {
                    anchors.fill: parent
                    source: MprisState.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: MprisState.artUrl !== ""
                }

                TintedIcon {
                    anchors.centerIn: parent
                    size: 26
                    visible: MprisState.artUrl === ""
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/music.svg")
                    tint: "#8A8A8A"
                }
            }

            Rectangle {
                visible: MprisState.identity !== ""
                anchors.right: artClip.right
                anchors.bottom: artClip.bottom
                anchors.margins: -4
                width: 20
                height: 20
                radius: 10
                color: "#E91E63"
                border.color: "#0A0A0A"
                border.width: 2

                TintedIcon {
                    anchors.centerIn: parent
                    size: 11
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/music.svg")
                    tint: "#FFFFFF"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: MprisState.trackTitle !== "" ? MprisState.trackTitle : "Unknown title"
                color: "#FFFFFF"
                font.pixelSize: 14; font.bold: true; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: MprisState.trackAlbum !== "" ? MprisState.trackAlbum : "Unknown album"
                color: "#C0C0C0"
                font.pixelSize: 11; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: MprisState.trackArtist !== "" ? MprisState.trackArtist : "Unknown artist"
                color: "#8A8A8A"
                font.pixelSize: 11; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.topMargin: 4
                spacing: 16

                CtrlButton { icon: "music/backward.svg"; active: MprisState.canGoPrevious; onClicked: MprisState.previous() }
                CtrlButton { icon: MprisState.isPlaying ? "music/pause.svg" : "music/play.svg"; active: MprisState.canTogglePlaying; onClicked: MprisState.togglePlaying() }
                CtrlButton { icon: "music/forward.svg"; active: MprisState.canGoNext; onClicked: MprisState.next() }
            }
        }
    }
}
