import QtQuick
import qs.components

Item {
    id: b

    property string glyph: ""
    property string xglyph: ""
    property real level: 2
    property bool flag: false
    property string icon: ""
    property color col: "white"
    property color fillColor: Qt.rgba(1, 1, 1, 0.12)
    property real gw: 20
    property real gh: 20
    property bool enabledBtn: true
    signal clicked()

    scale: ma.pressed ? 0.86 : 1.0
    opacity: b.enabledBtn ? (ma.pressed ? 0.6 : 1) : 0.4
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(b.width, b.height)
        height: width
        radius: width / 2
        color: b.fillColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    PlayerGlyph {
        visible: b.glyph !== ""
        anchors.centerIn: parent
        width: b.gw
        height: b.gh
        kind: b.glyph
        col: b.col
    }

    ExtraAGlyph {
        visible: b.xglyph !== ""
        anchors.centerIn: parent
        width: b.gw
        height: b.gh
        kind: b.xglyph
        level: b.level
        flag: b.flag
        color: b.col
    }

    CFVI {
        visible: b.icon !== ""
        anchors.centerIn: parent
        size: Math.round(b.gw)
        icon: b.icon
        color: b.col
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: b.enabledBtn
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
