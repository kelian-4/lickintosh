import QtQuick

Item {
    id: root

    property color color: "#ffffff"
    readonly property bool flat: true
    readonly property string element: ""
    readonly property bool ready: true
    readonly property bool captureSettled: true
    readonly property bool instantReveal: true
    readonly property size screenSize: Qt.size(4096, 4096)
    readonly property point windowPosition: Qt.point(0, 0)
    readonly property Item blurSource: source

    function registerQuad(q) {
    }

    function unregisterQuad(q) {
    }

    function invalidateRegion() {
    }

    width: 0
    height: 0

    Rectangle {
        id: fill
        visible: false
        width: 16
        height: 16
        color: root.color
    }

    ShaderEffectSource {
        id: source
        sourceItem: fill
        hideSource: true
        live: true
        width: 16
        height: 16
        visible: false
    }
}
