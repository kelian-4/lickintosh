import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Effects

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

    property Item backdrop: null
    readonly property bool glassed: backdrop !== null
    readonly property real shapeRatio: Math.max(0, Math.min(1,
        Math.min(radius, Math.min(width, height) / 2) / Math.max(1, Math.sqrt(width * height) / 2)))
    readonly property real shapePower: shapeRatio <= 0.001
        ? 400
        : Math.min(400, Math.max(2, 0.6931471805599453 / -Math.log(1 - 0.2928932188134524 * shapeRatio)))

    Behavior on color { PropertyAnimation { duration: animationSpeed; easing.type: Easing.InSine } }
    
    GlassRim {
        id: boxContainer
        anchors.fill: parent
        visible: !box.glassed
        baseColor: box.transparent ? "transparent" : box.color
        radius: box.radius
        glowColor: box.highlightEnabled ? box.light : "#00000000"
        lightDir: box.lightDir
        glowEdgeBand: box.rimSize
    }

    Loader {
        anchors.fill: parent
        active: box.glassed

        sourceComponent: LiquidGlass {
            backdrop: box.backdrop
            powerFactor: box.shapePower
            noise: 0.0
            supersample: 2.0
        }
    }
}
