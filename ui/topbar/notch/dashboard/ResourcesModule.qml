import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

/*
    Port de modules/dashboard/dash/Resources.qml (caelestia-dots/shell,
    GPLv3) : trois CircularProgress empilées (CPU / RAM / Disque), chacune
    avec juste une icône centrée (leur composant `Resource` ne montre ni
    pourcentage ni libellé) — cf. mapping icône/couleur exact de leur
    ColumnLayout : CPU -> "memory" (m3primary, couleur par defaut),
    Memory -> "memory_alt" (m3tertiary), Storage -> "hard_disk"
    (m3secondary). "memory_alt" et "hard_disk" n'existent pas dans le set
    d'icones feather de ce depot ; substitues par database.svg / hard-drive.svg,
    les plus proches disponibles.

    Fond de carte (#1A1A1A, radius) ajouté pour être cohérent avec
    Calendar/Weather — chaque module du dashboard a le même traitement
    "bloc" dans le vrai Dash.qml (component Rect: StyledRect partagé),
    ce module en était dépourvu par erreur.
*/
Rectangle {
    id: root
    color: "#1A1A1A"
    radius: 16

    component Resource: CircularProgress {
        id: res
        required property string icon
        Layout.fillHeight: true
        implicitSize: height
        strokeWidth: 6

        VectorImage {
            anchors.centerIn: parent
            width: parent.height * 0.32
            height: width
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + res.icon)
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: res.fgColour
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        Resource {
            icon: "cpu.svg"
            value: ResourcesState.cpuPercent / 100
        }
        Resource {
            icon: "database.svg"
            value: ResourcesState.memoryPercent / 100
            fgColour: "#EC4899"
        }
        Resource {
            icon: "hard-drive.svg"
            value: ResourcesState.storagePercent / 100
            fgColour: "#38BDF8"
        }
    }
}
