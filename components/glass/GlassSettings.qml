pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool enabled: true
    property bool captureWindows: true
    property real blurRadius: 0.8
    property real noise: 0.0
    property real refractionA: 0.7
    property real refractionB: 2.3
    property real refractionC: 5.2
    property real refractionD: 6.9
    property real refractionPower: 1.0
    property real glowWeight: 0.25
    property real glowEdge0: 0.5
    property real glowEdge1: -0.5
    property real squarePower: 6
    property real barPower: 4
    property real refractionMode: 0
    property real backdropScale: 0.5
    property real captureMargin: 200
    property real tintScale: 0.25
    property real veil: 0.06
    property real fadeDuration: 120
    property int captureFastInterval: 40
    property int captureIdleInterval: 200
    property real minAlpha: 0.02
    property real minSize: 28
}
