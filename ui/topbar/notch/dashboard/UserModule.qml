import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services

/*
    Port fidele de modules/dashboard/dash/User.qml (caelestia-dots/shell,
    GPLv3), relu integralement pour cette version (pas depuis la memoire) :
    memes relations d'ancrage, memes formules de marges, juste passees a
    l'echelle de ce module compact (le leur vise Tokens.sizes.dashboard.
    userWidth = 340px sur un dashboard plein ecran ; le notre fait ~200-
    280px dans la notch) via un facteur d'echelle unique (0.6) applique a
    toutes les valeurs de Tokens.padding/spacing qu'ils utilisent, pour
    garder exactement les memes proportions plutot que des valeurs
    inventees.

    Valeurs Tokens reelles (plugin/src/Caelestia/Config/tokens.hpp),
    x0.6, arrondies : extraSmall 4->3, small 8->5, medium 12->7,
    largeIncreased 20->12, extraLarge 28->17, extraLargeIncreased 32->19,
    large (marge interieure du module) 16->10, logoSize/uptimeSize
    30->18.

    Ancrages EXACTEMENT ceux du fichier reel :
    - pfpContainer.leftMargin = -(largeIncreased+extraLarge)/2 (chevauche
      logoShape)
    - uptimeShape : left=pfpContainer.right, leftMargin=-extraLargeIncreased
      (chevauche le bord droit de la photo), bottomMargin=-small
    - bubble1 : left=pfpContainer.right, leftMargin=+small (a l'EXTERIEUR
      de la photo, pas un chevauchement — verifie sur le fichier source,
      contrairement a ma version precedente qui chevauchait a tort le
      coin haut-droit)
    - bubble2 : left=bubble1.right, verticalCenter=wmContainer.bottom
    - wmContainer : left=bubble2.left, leftMargin=-medium, y=extraSmall

    Non repris (plugin natif Caelestia absent de ce depot, pas
    d'equivalent QML) : formes M3Shapes (Pill/Gem/ClamShell) -> Rectangle
    radius approprie ; MaterialIcon "select_window" -> notch/layout.svg
    (icone la plus proche disponible) ; le selecteur de photo de profil
    au clic (FileDialog) -> non applicable, pas de tel dialogue dans ce
    projet.

    Uptime et nom du WM : service GeneralState deja existant dans ce
    depot (GeneralState.uptimePretty / .wmName) plutot qu'une logique
    dupliquee.
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

    // Tokens caelestia x0.6 (cf. commentaire de tete).
    readonly property int tExtraSmall: 3
    readonly property int tSmall: 5
    readonly property int tMedium: 7
    readonly property int tLargeIncreased: 12
    readonly property int tExtraLarge: 17
    readonly property int tExtraLargeIncreased: 19
    readonly property int tLarge: 10
    readonly property int tBadgeSize: 28

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.tLarge

        Item {
            id: pfpContainer
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: logoShape.right
            anchors.leftMargin: -(root.tLargeIncreased + root.tExtraLarge) / 2
            width: height

            Rectangle {
                id: pfpClip
                anchors.fill: parent
                radius: width * 0.38
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
                    font.pixelSize: parent.height * 0.4
                    font.bold: true
                }
            }
        }

        // logoShape (Gem chez eux) : x=extraSmall, taille=logoSize+small*2.
        Rectangle {
            id: logoShape
            x: root.tExtraSmall
            anchors.verticalCenter: parent.verticalCenter
            width: root.tBadgeSize
            height: root.tBadgeSize
            radius: width * 0.32
            color: "#2A2A4A"

            VectorImage {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: width
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/logo.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "#B39DDB"
                }
            }
        }

        // uptimeShape (ClamShell chez eux) : left=pfpContainer.right avec
        // grande marge negative -> chevauche le bord droit de la photo.
        Rectangle {
            id: uptimeShape
            anchors.bottom: parent.bottom
            anchors.left: pfpContainer.right
            anchors.bottomMargin: -root.tSmall
            anchors.leftMargin: -root.tExtraLargeIncreased
            width: root.tBadgeSize
            height: root.tBadgeSize
            radius: width / 2
            color: "#2A3A2A"
            border.color: "#1A1A1A"
            border.width: 2

            VectorImage {
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
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
            id: uptimeText
            anchors.left: uptimeShape.right
            anchors.verticalCenter: uptimeShape.verticalCenter
            anchors.leftMargin: root.tSmall
            visible: GeneralState.uptimePretty !== ""
            text: "up " + GeneralState.uptimePretty
            color: "#B0B0B0"
            font.pixelSize: 11
            font.family: "SF Pro Rounded"
            width: Math.max(0, content.width - x - root.tExtraLarge)
            elide: Text.ElideRight
        }

        // Chaine de bulles menant au badge WM — a l'EXTERIEUR de la photo
        // (marges positives depuis pfpContainer.right), pas un
        // chevauchement, conformement au fichier source reel.
        Rectangle {
            id: bubble1
            anchors.left: pfpContainer.right
            anchors.top: bubble2.bottom
            anchors.leftMargin: root.tSmall
            anchors.topMargin: -root.tExtraSmall
            width: 6
            height: 6
            radius: 3
            color: "#2A2A4A"
        }

        Rectangle {
            id: bubble2
            anchors.left: bubble1.right
            anchors.verticalCenter: wmContainer.bottom
            anchors.leftMargin: root.tExtraSmall
            width: 9
            height: 9
            radius: 4.5
            color: "#2A2A4A"
        }

        Rectangle {
            id: wmContainer
            anchors.left: bubble2.left
            anchors.leftMargin: -root.tMedium
            y: root.tExtraSmall
            radius: height / 2
            color: "#2A2A4A"
            implicitWidth: wmLabel.implicitWidth + root.tMedium * 2
            implicitHeight: wmLabel.implicitHeight + root.tSmall * 2

            Row {
                id: wmLabel
                anchors.centerIn: parent
                spacing: root.tExtraSmall

                VectorImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 11
                    height: 11
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/layout.svg")
                    preferredRendererType: VectorImage.CurveRenderer
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: "#B39DDB"
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (GeneralState.wmName !== "" ? GeneralState.wmName : "—") + "..."
                    color: "#B39DDB"
                    font.pixelSize: 10
                    font.family: "SF Pro Rounded"
                    width: Math.min(implicitWidth, content.width - wmContainer.x - root.tMedium * 2 - 11 - wmLabel.spacing - root.tExtraLarge)
                    elide: Text.ElideRight
                }
            }
        }
    }
}
