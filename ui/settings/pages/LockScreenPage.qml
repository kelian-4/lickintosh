import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.glass
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var cfg: ShellConfig.options.lockscreen

    readonly property string previewPath: {
        const p = ShellConfig.options.wallpaper.lockscreenPath
        return p.length > 0
            ? p
            : Quickshell.shellDir + "/assets/wallpapers/macOS Tahoe 26 Dark Wallpaper.png"
    }

    ContentSection {
        title: I18n.tr("Aperçu")

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
                        text: I18n.tr("lundi 21 septembre")
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
                            text: I18n.tr("Notification")
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
                            text: I18n.tr("♪  Mini lecteur")
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

    ContentSection {
        title: I18n.tr("Apparence de l'horloge")

        ConfigSwitch {
            text: I18n.tr("Afficher l'horloge en grand")
            checked: root.cfg.clockLarge
            onToggled: function(v) { root.cfg.clockLarge = v }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            CFText {
                text: I18n.tr("Style")
                font.pixelSize: 14
                color: Theme.textPrimary
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
                            color: Theme.textPrimary
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
            text: I18n.tr("Épaisseur")
            from: 0
            to: 100
            decimals: 0
            valueSuffix: " %"
            value: root.cfg.clockWeight * 100
            onMoved: function(v) { root.cfg.clockWeight = v / 100 }
        }
    }

    ContentSection {
        title: I18n.tr("Démarrage")

        ConfigSwitch {
            text: I18n.tr("Verrouiller l'écran au démarrage de la session")
            description: I18n.tr("Le verrouillage n'est lancé qu'une fois par session, pas à chaque rechargement du shell.")
            checked: root.cfg.lockAtStartup
            onToggled: function(v) { root.cfg.lockAtStartup = v }
        }
    }

    ContentSection {
        title: I18n.tr("Notifications")

        ConfigSwitch {
            text: I18n.tr("Afficher les notifications sur l'écran de verrouillage")
            checked: root.cfg.showNotifications
            onToggled: function(v) { root.cfg.showNotifications = v }
        }

        ConfigSwitch {
            text: I18n.tr("Afficher l'aperçu du contenu")
            enabled: root.cfg.showNotifications
            checked: root.cfg.showNotificationPreviews
            onToggled: function(v) { root.cfg.showNotificationPreviews = v }
        }
    }

    ContentSection {
        title: I18n.tr("Mini lecteur")

        ConfigSwitch {
            text: I18n.tr("Afficher le mini lecteur multimédia")
            checked: root.cfg.showMediaPlayer
            onToggled: function(v) { root.cfg.showMediaPlayer = v }
        }
    }
}
