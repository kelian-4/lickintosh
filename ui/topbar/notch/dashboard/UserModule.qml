import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io

/*
    Port de modules/dashboard/dash/User.qml (caelestia-dots/shell,
    GPLv3) : icone/logo a gauche (leur "logoShape", forme Gem) chevauche
    par la photo de profil (leur "pfpContainer", forme Pill), un badge
    horloge+uptime (leur "uptimeShape", forme ClamShell) qui chevauche
    le coin bas-gauche de la photo, et une chaine de deux bulles menant
    a un badge "nom du WM" (leur "wmContainer") au-dessus.

    Non repris : les formes M3Shapes (Pill/Gem/ClamShell/Diamond/Sunny)
    sont un plugin natif Caelestia absent de ce depot -> remplacees par
    de simples Rectangle radius=hauteur/2 (cercle/pilule), meme
    composition et memes marges negatives de chevauchement.

    Detection de l'avatar reprise telle quelle de la version precedente
    de ce fichier (meme ordre de fallback ~/.face, ~/.face.icon,
    AccountsService que ui/lockscreen/LockContext.qml) : c'est ce que
    pfpContainer affiche chez caelestia (une vraie photo de profil, pas
    le fond d'ecran), a ne pas re-inventer.
*/
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _user: Quickshell.env("USER") || ""
    property string avatarSource: ""
    property string uptimeText: ""

    Process {
        running: root._home.length > 0
        command: ["sh", "-c",
            "for f in " +
            "\"" + root._home + "/.face\" " +
            "\"" + root._home + "/.face.icon\" " +
            "\"/var/lib/AccountsService/icons/" + root._user + "\"" +
            "; do [ -r \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length > 0) root.avatarSource = path
            }
        }
    }

    Process {
        id: _uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim().replace(/^up /, "")
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: _uptimeProc.running = true }

    // logoShape (Gem) : plus petit, place a x=0.
    Rectangle {
        id: logoShape
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 8
        color: "#2A2A4A"

        VectorImage {
            anchors.centerIn: parent
            width: 14
            height: 14
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/logo.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#B39DDB"
            }
        }
    }

    // pfpContainer (Pill) : chevauche logoShape via une marge negative,
    // occupe toute la hauteur disponible comme dans l'original.
    Item {
        id: pfpContainer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: logoShape.right
        anchors.leftMargin: -18
        width: height

        Rectangle {
            id: pfpClip
            anchors.fill: parent
            radius: 12
            color: "#2A2A3A"
            clip: true

            Image {
                anchors.fill: parent
                source: root.avatarSource !== "" ? "file://" + root.avatarSource : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.avatarSource !== ""
            }
            Text {
                anchors.centerIn: parent
                visible: root.avatarSource === ""
                text: root._user.charAt(0).toUpperCase()
                color: "#8A8A8A"
                font.pixelSize: 20
                font.bold: true
            }
        }
    }

    // uptimeShape (ClamShell) : chevauche le coin bas-gauche de pfpContainer.
    Rectangle {
        id: uptimeShape
        anchors.bottom: parent.bottom
        anchors.left: pfpContainer.right
        anchors.bottomMargin: -4
        anchors.leftMargin: -20
        width: 24
        height: 24
        radius: 12
        color: "#2A3A2A"
        border.color: "#1A1A1A"
        border.width: 2

        VectorImage {
            anchors.centerIn: parent
            width: 12
            height: 12
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/clock.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#8FD19E"
            }
        }
    }

    Text {
        anchors.left: uptimeShape.right
        anchors.verticalCenter: uptimeShape.verticalCenter
        anchors.leftMargin: 6
        text: root.uptimeText !== "" ? ("up " + root.uptimeText) : ""
        color: "#B0B0B0"
        font.pixelSize: 11
        font.family: "SF Pro Rounded"
        elide: Text.ElideRight
        width: Math.max(0, root.width - x - 8)
    }

    // Chaine de bulles (bubble1 -> bubble2 -> wmContainer) menant au
    // badge "nom du WM" au-dessus de pfpContainer, comme dans l'original.
    Rectangle {
        id: bubble1
        anchors.left: pfpContainer.right
        anchors.top: bubble2.bottom
        anchors.leftMargin: 4
        anchors.topMargin: -3
        width: 5
        height: 5
        radius: 2.5
        color: "#2A2A4A"
    }

    Rectangle {
        id: bubble2
        anchors.left: bubble1.right
        anchors.bottom: wmContainer.verticalCenter
        anchors.leftMargin: 3
        anchors.bottomMargin: 2
        width: 7
        height: 7
        radius: 3.5
        color: "#2A2A4A"
    }

    Rectangle {
        id: wmContainer
        anchors.left: bubble2.left
        anchors.leftMargin: -6
        y: 2
        radius: 10
        color: "#2A2A4A"
        implicitWidth: wmLabel.implicitWidth + 16
        implicitHeight: wmLabel.implicitHeight + 8

        Row {
            id: wmLabel
            anchors.centerIn: parent
            spacing: 3
            Text { text: "✦"; color: "#B39DDB"; font.pixelSize: 8 }
            Text {
                text: "Hyprland..."
                color: "#B39DDB"
                font.pixelSize: 10
                font.family: "SF Pro Rounded"
                width: Math.min(implicitWidth, root.width - wmContainer.x - 24)
                elide: Text.ElideRight
            }
        }
    }
}
