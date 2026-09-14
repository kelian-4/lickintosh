import QtQuick
import QtQuick.Layouts
import qs.services

// Calqué sur modules/dashboard/dash/Media.qml de caelestia : pochette,
// titre/artiste, contrôles play/prev/next. Version compacte (sans
// l'anneau de progression circulaire autour de la pochette ni le
// bongo cat animé de leur version, pour tenir dans le format réduit
// de la notch).
Rectangle {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 120
    radius: 12
    color: "#1A1A1A"
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.width - 16
            radius: 8
            color: "#0A0A0A"
            clip: true

            Image {
                anchors.fill: parent
                source: MprisState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MprisState.artUrl !== ""
            }
            Text {
                anchors.centerIn: parent
                visible: MprisState.artUrl === ""
                text: "♪"
                color: "#3A3A3A"
                font.pixelSize: 24
            }
        }

        Text {
            Layout.fillWidth: true
            text: MprisState.hasPlayer ? MprisState.trackTitle : "Aucune lecture"
            color: "#FFFFFF"
            font.pixelSize: 10
            font.bold: true
            font.family: "SF Pro Rounded"
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: MprisState.trackArtist
            color: "#8A8A8A"
            font.pixelSize: 9
            font.family: "SF Pro Rounded"
            elide: Text.ElideRight
            visible: text !== ""
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            Text {
                text: "⏮"
                color: MprisState.canGoPrevious ? "#FFFFFF" : "#4A4A4A"
                font.pixelSize: 12
                MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: MprisState.canGoPrevious; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.previous() }
            }
            Text {
                text: MprisState.isPlaying ? "⏸" : "▶"
                color: "#FFFFFF"
                font.pixelSize: 13
                MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: MprisState.canTogglePlaying; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.togglePlaying() }
            }
            Text {
                text: "⏭"
                color: MprisState.canGoNext ? "#FFFFFF" : "#4A4A4A"
                font.pixelSize: 12
                MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: MprisState.canGoNext; cursorShape: Qt.PointingHandCursor; onClicked: MprisState.next() }
            }
        }
    }
}
