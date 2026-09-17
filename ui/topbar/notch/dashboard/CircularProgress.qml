import QtQuick
import QtQuick.Shapes

/*
    Port de components/controls/CircularProgress.qml (caelestia-dots/shell,
    GPLv3) : anneau de fond + arc de progression via QtQuick.Shapes /
    PathAngleArc, avec un petit point à l'extrémité de l'arc.

    Non repris (dépendances natives absentes de ce dépôt, pas d'équivalent
    QML disponible) : l'effet "wavy" (WavyLine, composant C++ propriétaire
    de Caelestia.Components) — l'arc est donc toujours lisse ici.
*/
Item {
    id: root

    property real value
    property int startAngle: -90
    property int sweepAngle: 360
    property int strokeWidth: 4
    property color fgColour: "#1C7AFF"
    property color bgColour: "#2A2A2A"
    property bool hasEndIndicator: true

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: (size - strokeWidth) / 2
    property real clampedVal: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value))
    property real implicitSize
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Behavior on clampedVal {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: fgArc
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle * root.clampedVal
            }
        }
    }

    Rectangle {
        visible: root.hasEndIndicator && root.clampedVal > 1 / 360
        width: Math.min(4, root.strokeWidth)
        height: width
        radius: width / 2
        color: root.fgColour
        readonly property real _angleRad: (root.startAngle + root.sweepAngle * root.clampedVal) * Math.PI / 180
        x: root.size / 2 + root.arcRadius * Math.cos(_angleRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(_angleRad) - height / 2
    }
}
