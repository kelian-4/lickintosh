pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool enabled: true
    property bool captureWindows: true
    property real blurRadius: 0.8
    property real noise: 0.0
    property real glowWeight: 0.0
    property real tintScale: 0.25
    property real veil: 0.06
    property real fadeDuration: 160
    property real minAlpha: 0.02
    property real minSize: 28
}
