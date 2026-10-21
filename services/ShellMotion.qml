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
    property int enterDuration: 500
    property int exitDuration: 400
    property int fadeDuration: 300
    property int splitDuration: 800
    property int splitStagger: 80
    property real speed: 1.0

    function spatial(factor) {
        return Math.round(root.spatialDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function enter(factor) {
        return Math.round(root.enterDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function exit(factor) {
        return Math.round(root.exitDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function split(factor) {
        return Math.round(root.splitDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function stagger(factor) {
        return Math.round(root.splitStagger * root.speed * (factor === undefined ? 1 : factor))
    }

    function fade(factor) {
        return Math.round(root.fadeDuration * root.speed * (factor === undefined ? 1 : factor))
    }

    function effects(factor) {
        return Math.round(root.effectsDuration * root.speed * (factor === undefined ? 1 : factor))
    }
}
