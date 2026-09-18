import QtQuick
import QtQuick.Layouts
import qs.components

// Vignette d'un fond d'ecran dans la grille de selection.
// Le decodage est borne par sourceSize a la taille d'affichage reelle :
// une grille de 40 vignettes decodees en resolution native saturerait la
// memoire pour rien (meme raison que dans SpotlightWindow.qml).
Item {
    id: root

    property string path: ""
    property bool selected: false
    property string label: String(path).split("/").pop()

    signal clicked()

    implicitWidth: 148
    implicitHeight: 104

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 82

            CFClippingRect {
                anchors.fill: parent
                radius: 8
                color: "#20ffffff"

                Image {
                    anchors.fill: parent
                    source: root.path !== "" ? "file://" + root.path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize: Qt.size(296, 164)
                }
            }

            // Anneau de selection dessine par dessus, hors du clip pour
            // qu'il reste net (le contenu du CFClippingRect passe par un
            // ShaderEffectSource, une bordure dedans serait resamplee).
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: 10
                color: "transparent"
                border.width: 2
                border.color: "#1C7AFF"
                visible: root.selected
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#30ffffff"
                visible: _ma.containsMouse && !root.selected
            }

            MouseArea {
                id: _ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }

        CFText {
            text: root.label
            font.pixelSize: 11
            gray: !root.selected
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
