import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

/*
    Refonte complete demandee par l'utilisateur, calquee sur l'app
    macOS "Nook" (captures fournies) plutot que sur caelestia : plus
    de carte avec fond/bordure propre, juste la pochette + les textes +
    les controles, sur le fond continu du dashboard (separation par un
    simple trait vertical gere par DashboardPage, pas ici).

    Pochette carree arrondie (pas de cercle ni d'arc de progression
    autour, absents des captures de reference), petit badge rond en bas
    a droite avec le nom du lecteur (Spotify/Apple Music/etc, generique
    puisqu'on n'a pas d'icone par service precise dans ce depot).
*/
Item {
    id: root
    Layout.preferredWidth: 200
    Layout.fillHeight: true

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
                VectorImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    height: width
                    visible: MprisState.artUrl === ""
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/music.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#8A8A8A"
                    }
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
                border.color: "#1A1A1A"
                border.width: 2

                VectorImage {
                    anchors.centerIn: parent
                    width: 11
                    height: 11
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/music.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#FFFFFF"
                    }
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
                CtrlIcon { icon: "backward.svg"; enabled_: MprisState.canGoPrevious; onClicked: MprisState.previous() }
                CtrlIcon { icon: MprisState.isPlaying ? "pause.svg" : "play.svg"; enabled_: MprisState.canTogglePlaying; onClicked: MprisState.togglePlaying() }
                CtrlIcon { icon: "forward.svg"; enabled_: MprisState.canGoNext; onClicked: MprisState.next() }
            }
        }
    }
}
