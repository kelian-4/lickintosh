import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.components

// Vignette d'un fond d'ecran dans la grille de selection.
// Le decodage est borne par sourceSize a la taille de la vignette :
// decoder 40+ images en resolution native saturerait la memoire et le
// thread de decodage asynchrone pour rien (meme raison que dans
// SpotlightWindow.qml).
//
// Coins arrondis via MultiEffect.maskEnabled plutot que CFClippingRect :
// CFClippingRect instancie son propre ShaderEffectSource (rendu
// offscreen dedie) par utilisation. Sur une grille de 20+ vignettes
// affichees simultanement dans un Flow, ca fait 20+ surfaces offscreen
// composees a chaque frame — cout disproportionne pour un simple coin
// arrondi sur une image, et une des causes du chargement percu comme
// lent de la grille entiere. MultiEffect avec un masque partage cette
// meme charge plus legerement.
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
            id: _thumbArea
            Layout.fillWidth: true
            Layout.preferredHeight: 82

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#20ffffff"
            }

            Item {
                id: _maskShape
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "#fff"
                }
            }

            Image {
                id: _img
                anchors.fill: parent
                source: root.path !== "" ? "file://" + root.path : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize: Qt.size(296, 164)
                opacity: 0

                // Fondu a l'apparition : sans lui, l'image bascule du
                // placeholder gris a l'image d'un coup des que le
                // decodage async termine, ce qui donne l'impression que
                // la grille reste vide puis "pop" brutalement.
                onStatusChanged: if (status === Image.Ready) _fadeIn.start()

                NumberAnimation on opacity {
                    id: _fadeIn
                    running: false
                    from: 0
                    to: 1
                    duration: 200
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: _maskShape
                }
            }

            // Anneau de selection, par dessus le masque pour rester net.
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
