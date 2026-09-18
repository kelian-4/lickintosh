import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services

/*
    Port de modules/dashboard/dash/User.qml (caelestia-dots/shell,
    GPLv3) : icone/logo a gauche (leur "logoShape", forme Gem) chevauche
    par la photo de profil (leur "pfpContainer", forme Pill), un badge
    horloge+uptime (leur "uptimeShape", forme ClamShell) qui chevauche
    le coin bas-droit de la photo, et un badge "nom du WM" (leur
    "wmContainer") qui chevauche le coin haut-droit.

    Simplifie par rapport a la version precedente : la chaine de deux
    bulles (bubble1/bubble2) menant au badge WM s'etendait vers la
    droite EN DEHORS de la photo au lieu de la chevaucher (erreur
    d'ancrage : marges positives depuis pfpContainer.right au lieu de
    chevaucher son coin) -> badge WM ancre directement sur le coin
    haut-droit de pfpContainer, meme logique que le badge horloge sur
    le coin bas-droit.

    Non repris : les formes M3Shapes (Pill/Gem/ClamShell/Diamond) sont
    un plugin natif Caelestia absent de ce depot -> remplacees par de
    simples Rectangle radius=hauteur/2, memes marges negatives de
    chevauchement.

    Uptime et nom du WM : reutilisent le service GeneralState deja
    existant dans ce depot (GeneralState.uptimePretty / .wmName,
    alimentes par `uptime -p` / `hyprctl version`) au lieu de dupliquer
    un Process ici comme la version precedente le faisait par erreur.

    Detection de l'avatar reprise telle quelle de la version precedente
    de ce fichier (~/.face, ~/.face.icon, AccountsService — identique a
    ui/lockscreen/LockContext.qml).
*/
Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _user: Quickshell.env("USER") || ""
    property string avatarSource: ""

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

        // wmContainer : chevauche le coin HAUT-DROIT de la photo.
        Rectangle {
            id: wmContainer
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -wmLabel.implicitWidth * 0.4
            anchors.topMargin: -10
            implicitWidth: wmLabel.implicitWidth + 14
            implicitHeight: 20
            radius: 10
            color: "#2A2A4A"
            border.color: "#1A1A1A"
            border.width: 2

            RowLayout {
                id: wmLabel
                anchors.centerIn: parent
                spacing: 3
                Text { text: "✦"; color: "#B39DDB"; font.pixelSize: 8 }
                Text {
                    text: GeneralState.wmName !== "" ? GeneralState.wmName : "—"
                    color: "#B39DDB"
                    font.pixelSize: 10
                    font.family: "SF Pro Rounded"
                }
            }
        }

        // uptimeShape (ClamShell) : chevauche le coin BAS-DROIT de la photo.
        Rectangle {
            id: uptimeShape
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -10
            anchors.bottomMargin: -8
            width: 20
            height: 20
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
        anchors.left: pfpContainer.right
        anchors.verticalCenter: uptimeShape.verticalCenter
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 10
        text: GeneralState.uptimePretty !== "" ? ("up " + GeneralState.uptimePretty) : ""
        color: "#B0B0B0"
        font.pixelSize: 12
        font.family: "SF Pro Rounded"
        elide: Text.ElideRight
    }
}
