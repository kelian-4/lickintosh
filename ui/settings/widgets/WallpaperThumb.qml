import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.components

// Vignette d'un fond d'ecran dans la grille de selection.
//
// La grille affiche des fonds livres pouvant peser plusieurs Mo en
// pleine resolution (jusqu'a 6400x3600 pour certains PNG). Qt doit
// decompresser l'integralite d'un tel fichier avant d'appliquer
// sourceSize, et sur 20+ vignettes decodees en meme temps ca sature le
// pool de threads de decodage asynchrone : la grille entiere reste
// grise un bon moment avant de s'afficher. thumbPath (fourni par
// WallpaperPage, qui genere les miniatures via ImageMagick en arriere
// plan) pointe vers une copie deja redimensionnee, bien plus legere a
// decoder. Tant que cette miniature n'existe pas encore (generation en
// cours ou ImageMagick absent), on affiche directement l'original en
// resolution bornee par sourceSize : plus lent le temps du tout premier
// scan, mais jamais pire qu'avant ce mecanisme.
//
// Coins arrondis via MultiEffect.maskEnabled plutot que CFClippingRect :
// CFClippingRect instancie son propre ShaderEffectSource (rendu
// offscreen dedie) par utilisation. Sur 20+ vignettes simultanees dans
// un Flow, ca fait 20+ surfaces offscreen composees a chaque frame —
// disproportionne pour un simple coin arrondi. MultiEffect avec un
// masque partage cette meme charge plus legerement.
Item {
    id: root

    property string path: ""
    property string thumbPath: ""
    property int thumbsGen: 0
    property bool selected: false
    property string label: String(path).split("/").pop()

    signal clicked()

    implicitWidth: 148
    implicitHeight: 104

    // true tant qu'on n'a pas constate que la miniature est absente ou
    // invalide pour ce chemin. Remis a true a chaque nouveau batch de
    // generation (thumbsGen avance), pour retenter la miniature sans
    // attendre que l'utilisateur rouvre la page.
    property bool _useThumb: true
    onThumbsGenChanged: root._useThumb = true

    readonly property string _effectiveSource:
        (root._useThumb && root.thumbPath !== "") ? root.thumbPath : root.path

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
                source: root._effectiveSource !== "" ? "file://" + root._effectiveSource : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                // Meme sourceSize dans les deux cas (miniature ou
                // original) : sur la miniature deja a 296x164 ca ne
                // coute rien de plus, et sur l'original ca borne quand
                // meme la memoire de decodage le temps que la miniature
                // arrive.
                sourceSize: Qt.size(296, 164)
                opacity: 0

                onStatusChanged: {
                    if (status === Image.Ready) {
                        _fadeIn.start()
                    } else if (status === Image.Error && root._useThumb) {
                        // La miniature n'existe pas encore (generation
                        // en cours ou ImageMagick absent) : repli
                        // immediat sur l'original, sans quoi la
                        // vignette resterait vide indefiniment.
                        root._useThumb = false
                    }
                }

                // Fondu a l'apparition : sans lui, l'image bascule du
                // placeholder gris a l'image d'un coup des que le
                // decodage async termine, ce qui donne l'impression que
                // la grille reste vide puis "pop" brutalement.
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
