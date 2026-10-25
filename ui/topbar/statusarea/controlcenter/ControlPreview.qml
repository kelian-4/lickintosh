import QtQuick
import qs.components
import qs.components.glass
import qs.services

Item {
    id: root

    property var info: null
    readonly property int unit: ControlCatalog.box
    readonly property int gap: ControlCatalog.boxMargin
    readonly property color tint: {
        for (var i = 0; i < ControlCatalog.categories.length; i++) {
            if (ControlCatalog.categories[i].key === root.info.category) return ControlCatalog.categories[i].tint
        }
        return "#8e8e93"
    }

    width: root.info ? root.info.w * root.unit + (root.info.w - 1) * root.gap : root.unit
    height: root.info ? root.info.h * root.unit + (root.info.h - 1) * root.gap : root.unit

    BoxGlass {
        anchors.fill: parent
        radius: root.info && root.info.w === 4 ? 25 : 40
        color: "#20000000"
        light: "#80ffffff"
        rimStrength: 1.0
    }

    Rectangle {
        visible: root.info && root.info.w === 1 && root.info.h === 1
        anchors.centerIn: parent
        width: 40
        height: 40
        radius: 20
        color: "#30ffffff"

        CFVI {
            anchors.centerIn: parent
            size: 20
            icon: root.info ? root.info.icon : ""
        }
    }

    Row {
        visible: root.info && root.info.w === 2 && root.info.h === 1
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 10

        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: root.tint

            CFVI {
                anchors.centerIn: parent
                size: 20
                icon: root.info ? root.info.icon : ""
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.info ? root.info.title : ""
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Text {
                text: root.info ? root.info.subtitle : ""
                color: Qt.rgba(1, 1, 1, 0.6)
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }
        }
    }

    Item {
        visible: root.info && root.info.w === 4
        anchors.fill: parent

        CFSlider {
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            value: 0.6
            enabled: false
        }

        CFVI {
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: root.info && root.info.id === "volumeWidget" ? "volume/audio-volume-1.svg" : "sun-small.svg"
            size: 14
        }

        CFVI {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: root.info && root.info.id === "volumeWidget" ? "volume/audio-volume-3.svg" : "sun-huge.svg"
            size: 18
        }
    }

    Item {
        visible: root.info && root.info.w === 2 && root.info.h === 2
        anchors.fill: parent

        Rectangle {
            x: 12
            y: 12
            width: 44
            height: 44
            radius: 10
            color: "#40ffffff"

            CFVI {
                anchors.centerIn: parent
                size: 22
                icon: root.info ? root.info.icon : ""
            }
        }

        Text {
            x: 12
            y: 66
            text: root.info ? root.info.subtitle : ""
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 11
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 22

            Repeater {
                model: ["music/play.svg"]

                delegate: CFVI {
                    required property string modelData
                    size: 20
                    icon: modelData
                }
            }
        }
    }
}
