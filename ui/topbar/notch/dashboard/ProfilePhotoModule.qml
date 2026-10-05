import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/*
    Nouveau module, demande explicite : sur l'app macOS "Nook" (capture
    de reference), l'extremite droite du dashboard est une simple photo
    de profil circulaire, sans badge ni texte autour (contrairement a
    l'ancien UserModule retire, qui ajoutait logo/WM/uptime en plus de
    la photo). Detection de l'avatar reprise telle quelle de l'ancien
    UserModule.qml (~/.face, ~/.face.icon, AccountsService — identique
    a ui/lockscreen/LockContext.qml), pas de raison de la re-ecrire.
*/
Item {
    id: root
    Layout.preferredWidth: 56
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

    Rectangle {
        id: photoClip
        anchors.centerIn: parent
        width: 48
        height: 48
        radius: width / 2
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
            font.pixelSize: 18
            font.bold: true
        }
    }
}
