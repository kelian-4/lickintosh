import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.glass
import qs.services
import qs.ui.settings.widgets

/*
    Réglages > Écran de verrouillage. Calquée sur la page macOS
    « Fond d'écran » : aperçu de l'écran de verrouillage, puis le
    panneau « Apparence de l'horloge » (grande horloge, 6 styles,
    épaisseur), auxquels s'ajoutent les réglages des notifications et du
    mini lecteur affichés sur le lockscreen.

    Tout est persisté dans ShellConfig.options.lockscreen ; LockSurface,
    LockNotifications et LockMediaPlayer lisent les mêmes propriétés, donc
    les changements se voient immédiatement.
*/
ContentPage {
    id: root

    readonly property var cfg: ShellConfig.options.lockscreen

    readonly property string previewPath: {
        const p = ShellConfig.options.wallpaper.lockscreenPath
        return p.length > 0
            ? p
            : Quickshell.shellDir + "/assets/wallpapers/macOS Tahoe 26 Dark Wallpaper.png"
    }

    // --- Aperçu -----------------------------------------------------
    ContentSection {
        title: "Aperçu"

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 210

            CFClippingRect {
                anchors.centerIn: parent
                height: parent.height
                width: Math.round(height * 16 / 10)
                radius: 12

                Rectangle { anchors.fill: parent; color: "#101014" }

                Image {
                    anchors.fill: parent
                    source: Qt.url("file://" + encodeURI(root.previewPath))
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 640
                    asynchronous: true
                    smooth: true
                }

                Rectangle { anchors.fill: parent; color: "#26000000" }

                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "lundi 21 septembre"
                        color: "#ccffffff"
                        font.family: "SF Pro Display"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "9:41"
                        color: "#f2ffffff"
                        font.family: LockClockStyle.styleAt(root.cfg.clockStyle).family
                        font.italic: LockClockStyle.styleAt(root.cfg.clockStyle).italic
                        font.letterSpacing: LockClockStyle.styleAt(root.cfg.clockStyle).spacing
                        font.weight: LockClockStyle.weightFor(root.cfg.clockWeight)
                        font.pixelSize: root.cfg.clockLarge ? 52 : 30
                        Behavior on font.pixelSize { NumberAnimation { duration: 160 } }
                    }
                }

                Column {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Rectangle {
                        width: 170
                        height: 26
                        radius: 8
                        color: "#38ffffff"
                        visible: root.cfg.showNotifications

                        Text {
                            anchors.centerIn: parent
                            text: "Notification"
                            color: "#f2ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        width: 170
                        height: 26
                        radius: 8
                        color: "#38ffffff"
                        visible: root.cfg.showMediaPlayer

                        Text {
                            anchors.centerIn: parent
                            text: "♪  Mini lecteur"
                            color: "#f2ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    // --- Apparence de l'horloge ---------------------------------------
    ContentSection {
        title: "Apparence de l'horloge"

        ConfigSwitch {
            text: "Afficher l'horloge en grand"
            checked: root.cfg.clockLarge
            onToggled: function(v) { root.cfg.clockLarge = v }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            CFText {
                text: "Style"
                font.pixelSize: 14
                color: "#fff"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: LockClockStyle.styles

                    delegate: Rectangle {
                        id: tile

                        required property int index
                        required property var modelData

                        readonly property bool selected: root.cfg.clockStyle === tile.index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 10
                        color: tile.selected ? "#30ffffff" : "#18ffffff"
                        border.width: tile.selected ? 2 : 1
                        border.color: tile.selected ? "#3478f6" : "#18ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "12"
                            color: "#fff"
                            font.family: tile.modelData.family
                            font.italic: tile.modelData.italic
                            font.letterSpacing: tile.modelData.spacing
                            font.weight: LockClockStyle.weightFor(root.cfg.clockWeight)
                            font.pixelSize: 24
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cfg.clockStyle = tile.index
                        }
                    }
                }
            }

            CFText {
                text: LockClockStyle.styleAt(root.cfg.clockStyle).name
                font.pixelSize: 12
                gray: true
            }
        }

        ConfigSlider {
            text: "Épaisseur"
            from: 0
            to: 100
            decimals: 0
            valueSuffix: " %"
            value: root.cfg.clockWeight * 100
            onMoved: function(v) { root.cfg.clockWeight = v / 100 }
        }
    }

    // --- Notifications -------------------------------------------------
    ContentSection {
        title: "Notifications"

        ConfigSwitch {
            text: "Afficher les notifications sur l'écran de verrouillage"
            checked: root.cfg.showNotifications
            onToggled: function(v) { root.cfg.showNotifications = v }
        }

        ConfigSwitch {
            text: "Afficher l'aperçu du contenu"
            enabled: root.cfg.showNotifications
            checked: root.cfg.showNotificationPreviews
            onToggled: function(v) { root.cfg.showNotificationPreviews = v }
        }
    }

    // --- Mini lecteur ---------------------------------------------------
    ContentSection {
        title: "Mini lecteur"

        ConfigSwitch {
            text: "Afficher le mini lecteur multimédia"
            checked: root.cfg.showMediaPlayer
            onToggled: function(v) { root.cfg.showMediaPlayer = v }
        }
    }
}
