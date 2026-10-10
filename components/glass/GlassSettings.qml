pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool enabled: true
    property bool captureWindows: true
    property real blurRadius: 0.8
    property real noise: 0.0
    property real refractionB: 2.8
    property real refractionD: 2.5
    property real refractionPower: 1.1
    property real glowWeight: 0.0
    property real glowEdge0: 0.15
    property real glowEdge1: 0.0
    property real rimStrength: 0.6
    property real rimWidth: 1.6
    property real sheenStrength: 0.2
    property real sheenWidth: 10
    property real tintScale: 0.25
    property real veil: 0.06
    property real fadeDuration: 160
    property real minAlpha: 0.02
    property real minSize: 28
}
