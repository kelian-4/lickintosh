import QtQuick
import qs.services

Item {
    id: root

    property var pages: []
    property int index: 0
    property real slideDistance: ShellMotion.pageSlide

    property int _shownIndex: -1
    property int _direction: 1

    function _component(i) {
        return i >= 0 && i < root.pages.length ? root.pages[i] : null
    }

    onIndexChanged: {
        if (root._shownIndex < 0 || root.index === root._shownIndex) return
        root._direction = root.index > root._shownIndex ? 1 : -1
        swap.restart()
    }

    Component.onCompleted: root._shownIndex = root.index

    Loader {
        id: loader
        width: root.width
        height: root.height
        sourceComponent: root._component(root._shownIndex)
    }

    SequentialAnimation {
        id: swap

        ParallelAnimation {
            NumberAnimation {
                target: loader
                property: "opacity"
                to: 0
                duration: ShellMotion.page(0.5)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.effectsCurve
            }
            NumberAnimation {
                target: loader
                property: "x"
                to: -root._direction * root.slideDistance
                duration: ShellMotion.page(0.5)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.effectsCurve
            }
        }

        ScriptAction {
            script: {
                loader.x = root._direction * root.slideDistance
                root._shownIndex = root.index
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: loader
                property: "opacity"
                to: 1
                duration: ShellMotion.page()
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.effectsCurve
            }
            NumberAnimation {
                target: loader
                property: "x"
                to: 0
                duration: ShellMotion.page()
                easing.type: Easing.BezierSpline
                easing.bezierCurve: ShellMotion.spatialCurve
            }
        }
    }
}
