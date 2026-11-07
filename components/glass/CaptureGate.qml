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

    onWantedChanged: {
        if (!wanted)
            armed = false
        else if (calm)
            armed = true
    }

    onCalmChanged: {
        if (calm && wanted)
            armed = true
    }

    Component.onCompleted: {
        if (calm && wanted)
            armed = true
    }

    Timer {
        interval: Math.max(50, root.interval)
        running: root.armed && root.calm && root.hasContent
        repeat: true
        onTriggered: root.requestFrame()
    }

    Timer {
        interval: root.restartDelay
        running: root.armed && !root.hasContent
        repeat: true
        onTriggered: {
            if (root.calm)
                root.restartRequested()
        }
    }
}
