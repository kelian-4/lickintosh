pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool enabled: true
    property bool captureWindows: true
    property real blurRadius: 2.0
    property real noise: 0.04
    property real glowWeight: 0.2
    property real minAlpha: 0.02
    property real minSize: 28
}
