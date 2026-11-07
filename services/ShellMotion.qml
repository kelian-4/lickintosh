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
    property int splitDuration: 400
    property int splitStagger: 0
    property int pageDuration: 240
    property real pageSlide: 14
    property real speed: 1.0
    readonly property real motionScale: GameMode.enabled ? 0 : root.speed

    function spatial(factor) {
        return Math.round(root.spatialDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function enter(factor) {
        return Math.round(root.enterDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function exit(factor) {
        return Math.round(root.exitDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function page(factor) {
        return Math.round(root.pageDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function split(factor) {
        return Math.round(root.splitDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function stagger(factor) {
        return Math.round(root.splitStagger * root.speed * (factor === undefined ? 1 : factor))
    }

    function fade(factor) {
        return Math.round(root.fadeDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }

    function effects(factor) {
        return Math.round(root.effectsDuration * root.motionScale * (factor === undefined ? 1 : factor))
    }
}
