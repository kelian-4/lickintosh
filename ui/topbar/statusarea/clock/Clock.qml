import QtQuick

Text {
    id: clockText
    color: "#FFFFFF"
    font.pixelSize: 13
    font.bold: true
    renderType: Text.NativeRendering

    function updateTime() {
        clockText.text = Qt.formatDateTime(new Date(), "ddd d MMM HH:mm");
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.updateTime()
    }

    Component.onCompleted: updateTime()
}
