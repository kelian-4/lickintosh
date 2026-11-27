import QtQuick

Item {
    id: root

    property bool wanted: false
    property bool calm: true
    property bool hasContent: false
    property int interval: 400
    property int restartDelay: 8000
    property bool armed: false

    property var burstDelays: [0, 120, 300, 650]
    property int burstStep: 0

    signal requestFrame()
    signal restartRequested()

    function burst() {
        burstTimer.stop()
        root.burstStep = 0
        root.fireBurst()
    }

    function fireBurst() {
        if (!(root.armed && root.wanted && root.calm && root.hasContent))
            return
        root.requestFrame()
        if (root.burstStep + 1 < root.burstDelays.length) {
            burstTimer.interval = root.burstDelays[root.burstStep + 1] - root.burstDelays[root.burstStep]
            root.burstStep++
            burstTimer.restart()
        }
    }

    Timer {
        id: burstTimer
        repeat: false
        onTriggered: root.fireBurst()
    }

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
