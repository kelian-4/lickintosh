import QtQuick
import Quickshell

Item {
    id: root

    property alias antialiasing: rectangle.antialiasing
    property alias color: shader.backgroundColor
    property alias radius: rectangle.radius
    property alias topLeftRadius: rectangle.topLeftRadius
    property alias topRightRadius: rectangle.topRightRadius
    property alias bottomLeftRadius: rectangle.bottomLeftRadius
    property alias bottomRightRadius: rectangle.bottomRightRadius

    default property alias data: contentItem.data
    property alias children: contentItem.children
    readonly property alias contentItem: contentItem

    Rectangle {
        id: rectangle
        anchors.fill: root
        color: "#ffff0000"
        border.color: "#ff00ff00"
        layer.enabled: true
        visible: false
    }

    Item {
        id: contentItemContainer
        anchors.fill: root

        Item {
            id: contentItem
            anchors.fill: parent
            anchors.margins: 0
        }
    }

    ShaderEffect {
        id: shader
        anchors.fill: root
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/cliprect.frag.qsb")
        vertexShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/grxframe.vert.qsb")
        property Rectangle rect: rectangle
        property color backgroundColor: "transparent"

        property ShaderEffectSource content: ShaderEffectSource {
            samples: 16
            hideSource: true
            sourceItem: contentItemContainer
            smooth: false
            mipmap: false
        }
    }
}
