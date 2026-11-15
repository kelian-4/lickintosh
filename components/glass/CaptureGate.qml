import QtQuick

Item {
    id: root

    property bool wanted: false
    property bool calm: true
    property bool hasContent: false
    property int interval: 400
    property int restartDelay: 8000
    property bool armed: false

    signal requestFrame()
    signal restartRequested()

    function evaluate() {
        if (wanted && (calm || !hasContent))
            armed = true
    }

    onWantedChanged: evaluate()
    onCalmChanged: evaluate()
    onHasContentChanged: evaluate()
    Component.onCompleted: evaluate()

    Timer {
        interval: Math.max(50, root.interval)
        running: root.armed && root.wanted && root.calm && root.hasContent
        repeat: true
        onTriggered: root.requestFrame()
    }

    Timer {
        interval: root.restartDelay
        running: root.armed && root.wanted && !root.hasContent
        repeat: true
        onTriggered: {
            if (root.calm)
                root.restartRequested()
        }
    }
}
