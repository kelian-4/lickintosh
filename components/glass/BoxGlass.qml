import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Effects
import qs.services

Item {
    id: box

    property color color: "#10000000"
    property bool highlightEnabled: true
    property bool transparent: false
    
    property color light: '#40ffffff'
    property vector2d   lightDir: Qt.vector2d(1, 1)
    property real  rimSize: 0.01
    property real  rimStrength: 1.0

    property var negLight: ""
    property var highlight: ""
    property var shadowOpacity: ""

    
    property real radius: 50

    property int animationSpeed: 16
    property int animationSpeed2: 16

    readonly property Item registered: GlassRegistry.lookup(QsWindow.window)
    readonly property string element: registered ? registered.element : ""
    property Item backdrop: Theme.useGlass(box) ? registered : null
    readonly property bool glassed: backdrop !== null
    readonly property bool plainBackground: box.color.a >= 0.45
        && Math.max(box.color.r, box.color.g, box.color.b) - Math.min(box.color.r, box.color.g, box.color.b) < 0.12
        && Theme.luma(box.color) < 0.4

    Behavior on color { PropertyAnimation { duration: animationSpeed; easing.type: Easing.InSine } }
    
    Rectangle {
        anchors.fill: parent
        radius: Math.min(box.radius, Math.min(width, height) / 2)
        color: Theme.surfaceFor(box.element)
        visible: Theme.plainSurfaces && Theme.themed(box)
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(box.radius, Math.min(width, height) / 2)
        color: box.transparent || box.plainBackground ? "transparent" : Theme.boxColor(box, box.color)
        visible: Theme.plainSurfaces && Theme.themed(box)
    }

    Loader {
        anchors.fill: parent
        active: !box.glassed && !(Theme.plainSurfaces && Theme.themed(box))

        sourceComponent: GlassRim {
            baseColor: box.transparent ? "transparent" : Theme.boxColor(box, box.color)
            radius: box.radius
            glowColor: box.highlightEnabled ? Theme.boxRim(box, box.light) : "#00000000"
            lightDir: box.lightDir
            glowEdgeBand: box.rimSize
        }
    }

    Loader {
        anchors.fill: parent
        active: box.glassed

        sourceComponent: TahoeGlass {
            backdrop: box.backdrop
            cornerRadius: box.radius
        }
    }
}
