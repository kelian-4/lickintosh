import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services

/*
    Port de modules/dashboard/dash/User.qml (caelestia-dots/shell,
    GPLv3), adapte pour que la photo occupe tout l'espace du module
    (demande explicite) plutot que d'etre un simple carre a gauche
    laissant du vide a droite comme dans la version precedente :

    - La photo (pfpContainer chez caelestia) remplit desormais tout le
      module (anchors.fill: parent).
    - Le logo (leur "logoShape"), le badge nom du WM (leur
      "wmContainer") et le badge horloge+uptime (leur "uptimeShape")
      flottent chacun sur un coin de la photo, par-dessus, au lieu de
      se chevaucher entre eux hors de la photo.

    Non repris : les formes M3Shapes (Pill/Gem/ClamShell/Diamond) sont
    un plugin natif Caelestia absent de ce depot -> remplacees par de
    simples Rectangle radius=hauteur/2.

    Uptime et nom du WM : service GeneralState deja existant dans ce
    depot (GeneralState.uptimePretty / .wmName, alimentes par
    `uptime -p` / `hyprctl version`, deja utilises par
    ui/settings/pages/GeneralPage.qml) plutot qu'une logique dupliquee.

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

    component CornerBadge: Rectangle {
        radius: height / 2
        color: "#CC1A1A1A"
        border.color: "#33FFFFFF"
        border.width: 1
    }

    // La photo remplit tout le module.
    Rectangle {
        id: pfpClip
        anchors.fill: parent
        radius: 16
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
            font.pixelSize: 32
            font.bold: true
        }
    }

    // logoShape : flotte sur le coin haut-gauche de la photo.
    CornerBadge {
        id: logoShape
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        width: 28
        height: 28

        VectorImage {
            anchors.centerIn: parent
            width: 15
            height: 15
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/logo.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#B39DDB"
            }
        }
    }

    // wmContainer : flotte sur le coin haut-droit de la photo.
    CornerBadge {
        id: wmContainer
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        implicitWidth: wmLabel.implicitWidth + 16
        implicitHeight: 24

        RowLayout {
            id: wmLabel
            anchors.centerIn: parent
            spacing: 4
            Text { text: "✦"; color: "#B39DDB"; font.pixelSize: 9 }
            Text {
                text: GeneralState.wmName !== "" ? GeneralState.wmName : "—"
                color: "#FFFFFF"
                font.pixelSize: 11
                font.bold: true
                font.family: "SF Pro Rounded"
            }
        }
    }

    // uptimeShape : flotte sur le coin bas-droit de la photo, icone +
    // texte dans le meme badge (plus d'espace libre a cote pour un
    // texte separe, la photo occupant tout le module).
    CornerBadge {
        id: uptimeShape
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 8
        implicitWidth: uptimeLabel.implicitWidth + 16
        implicitHeight: 24
        visible: GeneralState.uptimePretty !== ""

        RowLayout {
            id: uptimeLabel
            anchors.centerIn: parent
            spacing: 4

            VectorImage {
                Layout.preferredWidth: 11
                Layout.preferredHeight: 11
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/clock.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "#8FD19E"
                }
            }
            Text {
                text: "up " + GeneralState.uptimePretty
                color: "#FFFFFF"
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
            }
        }
    }
}
