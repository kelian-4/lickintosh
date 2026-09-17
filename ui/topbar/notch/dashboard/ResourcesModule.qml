import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.services

// Calqué sur modules/dashboard/dash/Resources.qml de caelestia : trois
// jauges circulaires CPU / RAM / Disque, avec juste une icône au centre
// (pas de pourcentage ni de libellé affichés — comme leur composant
// Resource, qui ne montre que la MaterialIcon). Anneau toujours dessiné
// via Canvas (QtQuick.Shapes.PathAngleArc donnerait un rendu plus
// propre mais n'a pas été validé dans cet environnement) — juste
// épaissi et agrandi par rapport à la version précédente.
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 84

    component Ring: Item {
        id: ring
        property real percent: 0
        property string icon: ""
        property color ringColor: "#4ADE80"

        implicitWidth: 68
        implicitHeight: 68

        onPercentChanged: canvas.requestPaint()
        onRingColorChanged: canvas.requestPaint()

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#2A2A2A"
            border.width: 6
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var cx = width / 2, cy = height / 2, r = width / 2 - 3
                var start = -Math.PI / 2
                var end = start + (Math.PI * 2) * Math.min(1, Math.max(0, ring.percent / 100))
                ctx.strokeStyle = ring.ringColor
                ctx.lineWidth = 6
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.stroke()
            }
        }

        VectorImage {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + ring.icon)
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: ring.ringColor
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18

        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.cpuPercent;     icon: "cpu.svg";        ringColor: "#8B7CF6" }
        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.memoryPercent;  icon: "database.svg";   ringColor: "#EC4899" }
        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.storagePercent; icon: "hard-drive.svg"; ringColor: "#3B9EFF" }
    }
}
