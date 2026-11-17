import QtQuick

Item {
    id: root

    property Item blurSource: null
    property size screenSize: Qt.size(1, 1)
    readonly property bool flat: false
    readonly property string element: ""
    readonly property bool ready: blurSource !== null
    readonly property bool captureSettled: true
    readonly property bool instantReveal: true
    readonly property point windowPosition: Qt.point(0, 0)

    function registerQuad(q) {
    }

    function unregisterQuad(q) {
    }

    function invalidateRegion() {
    }

    width: 0
    height: 0
}
