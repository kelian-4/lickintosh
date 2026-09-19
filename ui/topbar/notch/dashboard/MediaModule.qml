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
      valeur = position/duree de lecture, UNIQUEMENT quand un lecteur est
      actif. Sans lecteur, un simple anneau plein et vif remplace l'arc
      (un arc a une valeur proche de 0 serait quasi invisible) — c'est
      ce que montre l'image de reference (cercle bleu net autour de
      l'icone de repli, pas un demi-arc discret).
    - Pochette qui tourne lentement en boucle tant que ca joue (leur
      CoverArt utilise un blob "Cookie12Sided" de M3Shapes, indisponible
      ici -> remplace par un simple cercle, meme logique de rotation).
    - Icone de repli sans pochette : notch/star.svg (le plus proche
      disponible de l'astérisque bleu de l'image de reference).
    - Textes de repli "Unknown title/album/artist" dans tous les cas
      sans metadonnee (conforme a l'image de reference, qui les affiche
      meme sans lecteur actif — plus simple que la distinction "No
      media" vs "Unknown X" du vrai fichier source, qui ne correspond
      pas a ce que montre l'image).
    - Controles precedent/lecture-pause/suivant.
    - Pas de bongo cat (AnimatedImage sur Config.paths.mediaGif) : ce
      depot n'a pas cet asset gif, visible dans l'image de reference en
      bas de la pochette.

    Fond de carte (#1A1A1A, radius) ajouté pour être cohérent avec
    Calendar/Weather — chaque module du dashboard a le même traitement
    "bloc" dans le vrai Dash.qml (component Rect: StyledRect partagé),
    ce module en était dépourvu par erreur.
*/
Rectangle {
    id: root
    color: "#1A1A1A"
    radius: 20

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

            // Etat "aucune lecture" : simple anneau plein et vif (pas un
            // arc de progression a une valeur proche de 0, quasi invisible)
            // -> correspond a l'image de reference (cercle bleu net autour
            // de l'icone de repli, pas un demi-arc discret).
            Rectangle {
                visible: !MprisState.hasPlayer
                anchors.centerIn: cover
                width: cover.width + root.arcCoverGap * 2 + 6
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#1C7AFF"
                border.width: 3
            }

            CircularProgress {
                id: prog
                visible: MprisState.hasPlayer
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
                anchors.margins: 6 + root.arcCoverGap + 6
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
                    width: parent.width * 0.4
                    height: width
                    visible: MprisState.artUrl === ""
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/star.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#1C7AFF"
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: MprisState.trackTitle !== "" ? MprisState.trackTitle : "Unknown title"
            color: "#FFFFFF"
            font.pixelSize: 13; font.bold: true; font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: MprisState.trackAlbum !== "" ? MprisState.trackAlbum : "Unknown album"
            color: "#9AA0A6"
            font.pixelSize: 10; font.family: "SF Pro Rounded"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: MprisState.trackArtist !== "" ? MprisState.trackArtist : "Unknown artist"
            color: "#9AA0A6"
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
