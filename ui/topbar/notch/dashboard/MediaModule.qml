import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.VectorImage
import Quickshell
import qs.services

/*
    Port de modules/dashboard/dash/Media.qml + CoverArt.qml (caelestia-
    dots/shell, GPLv3) :
    - CircularProgress en demi-cercle (sweepAngle 180, comme
      Tokens.sizes.dashboard.mediaProgressSweep) autour de la pochette,
      valeur = position/duree de lecture.
    - Pochette qui tourne lentement en boucle tant que ca joue (leur
      CoverArt utilise un blob "Cookie12Sided" de M3Shapes, indisponible
      ici -> remplace par un simple cercle, meme logique de rotation).
    - Fallback texte identique a leur logique exacte : "No media" si
      aucun lecteur actif, "Unknown title/album/artist" si un lecteur
      est actif mais sans metadonnee sur ce champ precis.
    - Controles precedent/lecture-pause/suivant.
    - Pas de bongo cat (AnimatedImage sur Config.paths.mediaGif) : ce
      depot n'a pas cet asset gif.
*/
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 130

    readonly property real playerProgress: MprisState.hasPlayer && MprisState.length > 0
        ? (MprisState.position % MprisState.length) / MprisState.length
        : 0
    readonly property real arcCoverGap: 4

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
        spacing: 6

        Item {
            id: coverWrap
            Layout.fillWidth: true
            Layout.preferredHeight: width

            CircularProgress {
                id: prog
                anchors.centerIn: cover
                implicitSize: cover.width + root.arcCoverGap + strokeWidth * 2
                fgColour: "#1C7AFF"
                bgColour: "#2A2A2A"
                strokeWidth: 6
                startAngle: -90 - 90
                sweepAngle: 180
                value: root.playerProgress
                hasEndIndicator: MprisState.hasPlayer
            }

            Item {
                id: cover
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: prog.strokeWidth + root.arcCoverGap + 6
                height: width

                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: width / 2
                    color: "#2A2A3A"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: MprisState.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: MprisState.artUrl !== ""
                    }

                    RotationAnimation on rotation {
                        running: MprisState.isPlaying
                        from: 0
                        to: 360
                        duration: 23500
                        loops: Animation.Infinite
                    }
                }

                VectorImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.35
                    height: width
                    visible: MprisState.artUrl === ""
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/disc.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#8A8A8A"
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: !MprisState.hasPlayer ? "No media" : (MprisState.trackTitle !== "" ? MprisState.trackTitle : "Unknown title")
            color: "#1C7AFF"
            font.pixelSize: 13; font.bold: true; font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: !MprisState.hasPlayer ? "No media" : (MprisState.trackAlbum !== "" ? MprisState.trackAlbum : "Unknown album")
            color: "#9AA0A6"
            font.pixelSize: 10; font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: !MprisState.hasPlayer ? "No media" : (MprisState.trackArtist !== "" ? MprisState.trackArtist : "Unknown artist")
            color: "#5B8DEF"
            font.pixelSize: 10; font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            CtrlIcon { icon: "backward.svg"; enabled_: MprisState.canGoPrevious; onClicked: MprisState.previous() }
            CtrlIcon { icon: MprisState.isPlaying ? "pause.svg" : "play.svg"; enabled_: MprisState.canTogglePlaying; onClicked: MprisState.togglePlaying() }
            CtrlIcon { icon: "forward.svg"; enabled_: MprisState.canGoNext; onClicked: MprisState.next() }
        }
    }
}
