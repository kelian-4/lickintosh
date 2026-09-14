import QtQuick
import QtQuick.Layouts
import qs.services

// Onglet "Media" : calqué sur modules/dashboard/Media.qml de
// caelestia — grand cercle pointillé + icône quand rien ne joue,
// pochette + contrôles en grand quand un lecteur est actif. Version
// simplifiée (pas de paroles ni de visualiseur audio).
Item {
    id: root

    // -- Rien ne joue : gros cercle pointillé + message --
    ColumnLayout {
        anchors.centerIn: parent
        visible: !MprisState.hasPlayer
        spacing: 18

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 96
            height: 96
            radius: 48
            color: "transparent"
            border.color: "#3A3A3A"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: "#5A5A5A"
                font.pixelSize: 34
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Aucune lecture en cours"
            color: "#FFFFFF"
            font.pixelSize: 16
            font.bold: true
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Lance une lecture pour la voir apparaître ici"
            color: "#7A7A7A"
            font.pixelSize: 11
            font.family: "SF Pro Rounded"
        }
    }

    // -- Lecture en cours : pochette + infos + contrôles --
    RowLayout {
        anchors.fill: parent
        visible: MprisState.hasPlayer
        spacing: 24

        Rectangle {
            Layout.preferredWidth: 190
            Layout.preferredHeight: 190
            Layout.alignment: Qt.AlignVCenter
            radius: 16
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
            spacing: 8

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: MprisState.trackTitle
                color: "#FFFFFF"
                font.pixelSize: 20
                font.bold: true
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: MprisState.trackArtist + (MprisState.trackAlbum ? " — " + MprisState.trackAlbum : "")
                color: "#B0B0B0"
                font.pixelSize: 13
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
                visible: text !== ""
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                height: 4
                radius: 2
                color: "#3A3A3A"
                visible: MprisState.length > 0
                Rectangle {
                    width: parent.width * (MprisState.length > 0 ? Math.min(1, MprisState.position / MprisState.length) : 0)
                    height: parent.height
                    radius: parent.radius
                    color: "#1C7AFF"
                }
            }

            RowLayout {
                Layout.topMargin: 10
                spacing: 26

                Text {
                    text: "⏮"
                    color: MprisState.canGoPrevious ? "#FFFFFF" : "#4A4A4A"
                    font.pixelSize: 20
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canGoPrevious; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.previous() }
                }
                Text {
                    text: MprisState.isPlaying ? "⏸" : "▶"
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canTogglePlaying; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.togglePlaying() }
                }
                Text {
                    text: "⏭"
                    color: MprisState.canGoNext ? "#FFFFFF" : "#4A4A4A"
                    font.pixelSize: 20
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: MprisState.canGoNext; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.next() }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
