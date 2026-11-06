import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    property var info: ({})

    readonly property string fullName: root.info.fullname && root.info.fullname.length > 0 ? root.info.fullname : (root.info.user || "")
    readonly property string avatarPath: root.info.avatar || ""

    readonly property var personalRows: [
        { label: I18n.tr("Nom complet"),          value: root.info.fullname || "—" },
        { label: I18n.tr("Identifiant"),          value: root.info.user || "—" },
        { label: I18n.tr("Identifiant numérique"), value: root.info.uid || "—" },
        { label: I18n.tr("Groupes"),              value: root.info.groups || "—" },
        { label: I18n.tr("Dossier personnel"),    value: root.info.home || "—" },
        { label: I18n.tr("Interpréteur"),         value: root.info.shell || "—" }
    ]

    readonly property var systemRows: [
        { label: I18n.tr("Nom de la machine"), value: root.info.host || "—" },
        { label: I18n.tr("Système"),           value: root.info.os || "—" },
        { label: I18n.tr("Noyau"),             value: root.info.kernel || "—" },
        { label: I18n.tr("Session"),           value: root.info.session || "—" }
    ]

    Process {
        running: true
        command: ["sh", "-c", [
            "u=$(id -un)",
            "echo user=$u",
            "echo uid=$(id -u)",
            "echo groups=$(id -Gn | tr ' ' ',' | sed 's/,/, /g')",
            "echo fullname=$(getent passwd \"$u\" | cut -d: -f5 | cut -d, -f1)",
            "echo home=$HOME",
            "echo shell=$SHELL",
            "echo host=$(hostname)",
            "echo os=$(. /etc/os-release 2>/dev/null; echo \"$PRETTY_NAME\")",
            "echo kernel=$(uname -r)",
            "echo session=$XDG_SESSION_TYPE ${XDG_CURRENT_DESKTOP:+($XDG_CURRENT_DESKTOP)}",
            "if [ -f \"$HOME/.face\" ]; then echo avatar=$HOME/.face; elif [ -f \"/var/lib/AccountsService/icons/$u\" ]; then echo avatar=/var/lib/AccountsService/icons/$u; fi"
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = {}
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var k = lines[i].indexOf("=")
                    if (k > 0)
                        out[lines[i].substring(0, k)] = lines[i].substring(k + 1).trim()
                }
                root.info = out
            }
        }
    }

    component InfoRow: RowLayout {
        id: row

        required property string label
        required property string value

        Layout.fillWidth: true
        spacing: 12

        CFText {
            text: row.label
            font.pixelSize: 14
        }

        Item { Layout.fillWidth: true }

        CFText {
            Layout.maximumWidth: 380
            text: row.value
            font.pixelSize: 14
            gray: true
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignRight
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 10

        CFClippingRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            radius: 44

            Rectangle {
                anchors.fill: parent
                color: Theme.fillControl

                CFText {
                    anchors.centerIn: parent
                    text: root.fullName.length > 0 ? root.fullName.charAt(0).toUpperCase() : ""
                    font.pixelSize: 38
                    font.weight: Font.DemiBold
                    visible: avatar.status !== Image.Ready
                }
            }

            Image {
                id: avatar
                anchors.fill: parent
                source: root.avatarPath.length > 0 ? Qt.url("file://" + encodeURI(root.avatarPath)) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize.width: 256
            }
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            text: root.fullName
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            text: root.info.user && root.info.host ? root.info.user + "@" + root.info.host : ""
            font.pixelSize: 13
            gray: true
        }
    }

    ContentSection {
        title: I18n.tr("Informations personnelles")

        Repeater {
            model: root.personalRows

            InfoRow {
                required property var modelData
                label: modelData.label
                value: modelData.value
            }
        }
    }

    ContentSection {
        title: I18n.tr("Cet ordinateur")

        Repeater {
            model: root.systemRows

            InfoRow {
                required property var modelData
                label: modelData.label
                value: modelData.value
            }
        }
    }
}
