import QtQuick
import qs.services

Row {
    id: clockRoot
    spacing: 6

    Text {
        id: dateText
        color: "#FFFFFF"
        font.pixelSize: 13
        font.bold: true
        renderType: Text.NativeRendering
        visible: ShellConfig.options.topbar.clockTextVisible && text.length > 0
    }

    Text {
        id: timeText
        color: "#FFFFFF"
        font.pixelSize: 13
        font.bold: true
        renderType: Text.NativeRendering
    }

    function updateTime() {
        var now = new Date()
        dateText.text = Qt.formatDateTime(now, "ddd d MMM")
        timeText.text = Qt.formatDateTime(now, "HH:mm")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockRoot.updateTime()
    }

    Component.onCompleted: updateTime()
}
