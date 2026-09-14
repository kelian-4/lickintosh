pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.glass
import qs.services

/*
    LockMediaPlayer — mini lecteur média du lockscreen, façon macOS
    (pochette + titre/artiste + contrôles play/pause/suivant/précédent).

    Contrairement à LockStatusIndicators (volontairement passif), ce
    composant EST interactif : contrôler la lecture depuis l'écran de
    verrouillage est le comportement macOS standard, et ne présente pas
    le même risque qu'exposer des réglages système (wifi/bluetooth).

    S'appuie sur qs.services.MprisState (déjà l'API du reste du projet),
    pas de logique MPRIS dupliquée ici.
*/
Item {
    id: root

    readonly property bool hasPlayer: MprisState.hasPlayer
    visible: root.hasPlayer
    implicitWidth: 280
    implicitHeight: visible ? 64 : 0

    opacity: root.hasPlayer ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    CFClippingRect {
        id: pill
        anchors.fill: parent
        radius: 16

        BoxGlass {
            anchors.fill: parent
            radius: pill.radius
            color: Qt.rgba(1, 1, 1, 0.10)
            light: Qt.rgba(1, 1, 1, 0.28)
            rimStrength: 0.7
            highlightEnabled: true
        }

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // --- Pochette --------------------------------------------
            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                CFClippingRect {
                    anchors.fill: parent
                    radius: 8

                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: MprisState.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 0.10)
                        visible: artImg.status !== Image.Ready

                        CFVI {
                            anchors.centerIn: parent
                            icon: "notch/music.svg"
                            size: 18
                            gray: true
                        }
                    }
                }
            }

            // --- Titre / artiste + contrôles --------------------------
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 44 - 10 - 10 - controlsRow.width
                spacing: 2

                CFText {
                    width: parent.width
                    text: MprisState.trackTitle.length > 0 ? MprisState.trackTitle : qsTr("Non lu")
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                CFText {
                    width: parent.width
                    text: MprisState.trackArtist
                    gray: true
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }

            Row {
                id: controlsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                CFVI {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "music/backward.svg"
                    size: 16
                    gray: !MprisState.canGoPrevious
                    opacity: MprisState.canGoPrevious ? 1 : 0.35

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: MprisState.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisState.previous()
                    }
                }

                CFVI {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: MprisState.isPlaying ? "music/pause.svg" : "music/play.svg"
                    size: 20
                    gray: !MprisState.canTogglePlaying
                    opacity: MprisState.canTogglePlaying ? 1 : 0.35

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: MprisState.canTogglePlaying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisState.togglePlaying()
                    }
                }

                CFVI {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "music/forward.svg"
                    size: 16
                    gray: !MprisState.canGoNext
                    opacity: MprisState.canGoNext ? 1 : 0.35

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: MprisState.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisState.next()
                    }
                }
            }
        }
    }
}
