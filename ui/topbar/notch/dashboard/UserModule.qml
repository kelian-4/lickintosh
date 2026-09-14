import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/*
    Calqué sur modules/dashboard/dash/User.qml de caelestia : avatar +
    badge de session + uptime. Détection de l'avatar reprise à
    l'identique de ui/lockscreen/LockContext.qml (même ordre de
    fallback : ~/.face, ~/.face.icon, AccountsService) pour rester
    cohérent avec ce que le projet fait déjà ailleurs.
*/
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    radius: 12
    color: "#1A1A1A"

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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: "#2A2A2A"
            clip: true
            Image {
                anchors.fill: parent
                source: root.avatarSource ? "file://" + root.avatarSource : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.avatarSource !== ""
            }
            Text {
                anchors.centerIn: parent
                visible: root.avatarSource === ""
                text: root._user.charAt(0).toUpperCase()
                color: "#8A8A8A"
                font.pixelSize: 14
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Rectangle {
                Layout.preferredWidth: badgeRow.implicitWidth + 16
                Layout.preferredHeight: 16
                radius: 8
                color: "#2A2A4A"
                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 3
                    Text { text: "✦"; color: "#B39DDB"; font.pixelSize: 8 }
                    Text { text: "Hyprland"; color: "#B39DDB"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.uptimeText !== "" ? ("up " + root.uptimeText) : ""
                color: "#8A8A8A"
                font.pixelSize: 9
                font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
        }
    }
}
