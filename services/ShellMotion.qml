pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var spatialCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var effectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]

    property int spatialDuration: 500
    property int effectsDuration: 200
    property int tileDuration: 300
    property real tileOvershoot: 0.5
    property real moveOvershoot: 1.0
    property real speed: 1.0

    function spatial(factor) {
        return Math.round(root.spatialDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function tile(factor) {
        return Math.round(root.tileDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function effects(factor) {
        return Math.round(root.effectsDuration * root.speed * (factor === undefined ? 1 : factor))
    }
}
