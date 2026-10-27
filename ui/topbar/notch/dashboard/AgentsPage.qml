import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root

    component ActionButton: Rectangle {
        id: button

        property string icon: ""
        property string label: ""
        signal clicked()

        Layout.preferredWidth: content.implicitWidth + 28
        Layout.preferredHeight: 32
        radius: 16
        color: mouse.containsMouse ? "#2A2A2A" : "#1F1F1F"

        Behavior on color { ColorAnimation { duration: ShellMotion.effects(0.5) } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 6

            TintedIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 14
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + button.icon)
                tint: "#FFFFFF"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.label
                color: "#FFFFFF"
                font.pixelSize: 13
                font.family: "SF Pro Rounded"
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 24

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                text: "Coucou"
                color: "#FFFFFF"
                font.pixelSize: 16
                font.bold: true
                font.family: "SF Pro Rounded"
            }

            Text {
                Layout.fillWidth: true
                text: "Suit les sessions de tes agents de code et te laisse valider leurs demandes depuis l'île de Coucou."
                color: "#8A8A8A"
                font.pixelSize: 12
                font.family: "SF Pro Rounded"
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: CoucouState.command !== "" ? CoucouState.command : "Aucun binaire configuré"
                color: "#5A5A5A"
                font.pixelSize: 10
                font.family: "SF Pro Rounded"
                elide: Text.ElideMiddle
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            ActionButton {
                icon: "play.svg"
                label: "Lancer"
                onClicked: CoucouState.launch()
            }

            ActionButton {
                icon: "external-link.svg"
                label: "Île"
                onClicked: {
                    CoucouState.toggleIsland()
                    NotchState.close()
                }
            }

            ActionButton {
                icon: "message-circle.svg"
                label: "Chat"
                onClicked: {
                    CoucouState.openChat()
                    NotchState.close()
                }
            }
        }
    }
}
