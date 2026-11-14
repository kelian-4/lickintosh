import QtQuick

Item {
    id: root

    property string path: ""
    property size targetSize: Qt.size(0, 0)
    property int duration: 350

    property bool frontIsA: true
    readonly property var front: frontIsA ? slotA : slotB
    readonly property var incoming: frontIsA ? slotB : slotA

    onPathChanged: {
        if (path === front.path && !fade.running) return
        if (front.path === "") {
            front.path = path
            front.opacity = 1
            return
        }
        fade.stop()
        incoming.opacity = 0
        incoming.z = 1
        front.z = 0
        incoming.path = path
    }

    Component.onCompleted: {
        if (path !== "" && front.path === "") {
            front.path = path
            front.opacity = 1
        }
    }

    NumberAnimation {
        id: fade
        target: root.incoming
        property: "opacity"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.InOutQuad
        onFinished: {
            root.front.path = ""
            root.frontIsA = !root.frontIsA
        }
    }

    WallpaperSlot {
        id: slotA
        anchors.fill: parent
        targetSize: root.targetSize
        onReady: root.slotReady(slotA)
    }

    WallpaperSlot {
        id: slotB
        anchors.fill: parent
        targetSize: root.targetSize
        onReady: root.slotReady(slotB)
    }

    function slotReady(slot) {
        if (slot === incoming && slot.path !== "" && !fade.running && slot.opacity < 1) fade.restart()
    }
}
