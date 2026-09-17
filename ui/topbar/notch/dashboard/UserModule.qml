import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services

/*
    Calqué sur modules/dashboard/dash/User.qml de caelestia : vignette
    (fond d'écran actuel plutôt que photo de profil, faute d'avatar
    utilisateur configuré côté OS) avec un badge "Hyprland" flottant qui
    chevauche le coin haut-droit, et un badge horloge + uptime qui
    chevauche le coin bas-gauche — reproduction des MaterialShape
    (Pill/ClamShell) de caelestia via de simples Rectangle, ce module
    n'ayant pas accès à leur système M3Shapes.
*/
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 64
    radius: 16
    color: "#1A1A1A"
    clip: false

    readonly property string _home: Quickshell.env("HOME") || ""
    property string uptimeText: ""

    Process {
        id: _uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim().replace(/^up /, "")
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: _uptimeProc.running = true }

    Item {
        id: thumb
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        width: height

        Rectangle {
            id: thumbClip
            anchors.fill: parent
            radius: 12
            color: "#2A2A3A"
            clip: true

            Image {
                anchors.fill: parent
                source: ShellConfig.options.wallpaper.path !== "" ? "file://" + ShellConfig.options.wallpaper.path : ""
                fillMode: Image.PreserveAspectCrop
                visible: ShellConfig.options.wallpaper.path !== ""
            }

            VectorImage {
                anchors.centerIn: parent
                width: 20
                height: 20
                visible: ShellConfig.options.wallpaper.path === ""
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/logo.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "#8A8A8A"
                }
            }
        }

        // Badge "Hyprland" — chevauche le coin haut-droit de la vignette.
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -hyprRow.implicitWidth * 0.35
            anchors.topMargin: -8
            implicitWidth: hyprRow.implicitWidth + 14
            implicitHeight: 20
            radius: 10
            color: "#2A2A4A"
            border.color: "#1A1A1A"
            border.width: 2

            RowLayout {
                id: hyprRow
                anchors.centerIn: parent
                spacing: 3
                Text { text: "✦"; color: "#B39DDB"; font.pixelSize: 8 }
                Text { text: "Hyprland"; color: "#B39DDB"; font.pixelSize: 10; font.family: "SF Pro Rounded" }
            }
        }

        // Badge horloge + uptime — chevauche le coin bas-gauche.
        Rectangle {
            id: uptimeBadge
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: -10
            anchors.bottomMargin: -8
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: "#2A3A2A"
            border.color: "#1A1A1A"
            border.width: 2

            VectorImage {
                anchors.centerIn: parent
                width: 11
                height: 11
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/clock.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "#8FD19E"
                }
            }
        }
    }

    Text {
        anchors.left: thumb.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        text: root.uptimeText !== "" ? ("up " + root.uptimeText) : ""
        color: "#B0B0B0"
        font.pixelSize: 12
        font.family: "SF Pro Rounded"
        elide: Text.ElideRight
    }
}
