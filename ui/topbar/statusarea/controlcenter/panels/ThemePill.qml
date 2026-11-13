import QtQuick
import qs.components
import qs.components.glass
import qs.services

BoxGlass {
    id: pill

    property string label: ""
    property string icon: ""
    property bool picked: false
    property Item glassBackdrop: null
    signal activated()

    readonly property color inkColor: Theme.ink(pill, false)
    readonly property bool inkLight: (inkColor.r * 0.299 + inkColor.g * 0.587 + inkColor.b * 0.114) > 0.5
    readonly property color onPicked: pill.inkLight ? "#000000" : "#ffffff"

    height: 46
    radius: height / 2
    backdrop: pill.glassBackdrop !== null ? pill.glassBackdrop : (Theme.useGlass(pill) ? registered : null)
    color: pill.picked
        ? pill.inkColor
        : Qt.rgba(pill.inkColor.r, pill.inkColor.g, pill.inkColor.b, pillMa.containsMouse ? 0.14 : 0.07)
    light: Qt.rgba(1, 1, 1, 0.34)
    rimStrength: 1.0
    Behavior on color { ColorAnimation { duration: 160 } }

    ThemeGlyph {
        visible: pill.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        kind: pill.icon
        size: 22
        col: pill.picked ? pill.onPicked : pill.inkColor
    }

    CFText {
        anchors.centerIn: parent
        width: parent.width - 100
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: pill.label
        font.family: "SF Pro Text"
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: pill.picked ? pill.onPicked : pill.inkColor
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.activated()
    }
}
