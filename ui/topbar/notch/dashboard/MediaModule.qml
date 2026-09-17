import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

/*
    Calqué sur modules/dashboard/dash/Media.qml de caelestia : pochette,
    titre/artiste/album, contrôles play/prev/next. Version compacte
    (sans l'anneau de progression circulaire autour de la pochette ni
    le bongo cat animé de leur version) — le bongo cat consomme un
    fichier gif dédié (Config.paths.mediaGif) que ce dépôt n'a pas ;
    à brancher plus tard sur le même modèle si un asset est fourni
    (AnimatedImage, playing: MprisState.isPlaying).
*/
Rectangle {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 150
    radius: 20
    color: "#1A1A1A"
    clip: true

    component CtrlIcon: Item {
        id: ctrl
        property string icon: ""
        property bool enabled_: true
        signal clicked()
        implicitWidth: 18
        implicitHeight: 18

        VectorImage {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/music/" + ctrl.icon)
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: ctrl.enabled_ ? "#FFFFFF" : "#4A4A4A"
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: ctrl.enabled_
            cursorShape: Qt.PointingHandCursor
            onClicked: ctrl.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.width - 24
            radius: 12
            color: "#0A0A0A"
            clip: true

            Image {
                anchors.fill: parent
                source: MprisState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MprisState.artUrl !== ""
            }

            Rectangle {
                anchors.centerIn: parent
                visible: MprisState.artUrl === ""
                width: parent.height * 0.62
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#2E5A8A"
                border.width: 2

                VectorImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.5
                    height: width
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/disc.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#5A9BE0"
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: MprisState.hasPlayer ? MprisState.trackTitle : "Unknown title"
            color: "#FFFFFF"
            font.pixelSize: 13
            font.bold: true
            font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: MprisState.hasPlayer && MprisState.trackAlbum !== "" ? MprisState.trackAlbum : "Unknown album"
            color: "#8A8A8A"
            font.pixelSize: 10
            font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: MprisState.hasPlayer && MprisState.trackArtist !== "" ? MprisState.trackArtist : "Unknown artist"
            color: "#8A8A8A"
            font.pixelSize: 10
            font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            CtrlIcon { icon: "backward.svg"; enabled_: MprisState.canGoPrevious; onClicked: MprisState.previous() }
            CtrlIcon { icon: MprisState.isPlaying ? "pause.svg" : "play.svg"; enabled_: MprisState.canTogglePlaying; onClicked: MprisState.togglePlaying() }
            CtrlIcon { icon: "forward.svg"; enabled_: MprisState.canGoNext; onClicked: MprisState.next() }
        }
    }
}
