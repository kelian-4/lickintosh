import QtQuick
import qs.services
import qs.components

Item {
    id: root

    property var look: null
    property string size: "m"
    property var widgetData: null

    readonly property bool fullBleed: true
    readonly property string path: root.widgetData && root.widgetData.image ? root.widgetData.image : ""

    CFClippingRect {
        anchors.fill: parent
        radius: 22
        color: "transparent"

        Image {
            id: img
            anchors.fill: parent
            source: root.path !== "" ? "file://" + root.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
            cache: false
            sourceSize.width: Math.ceil(Math.max(root.width, root.height) * 2)
            sourceSize.height: Math.ceil(Math.max(root.width, root.height) * 2)
            visible: status === Image.Ready
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 6
        visible: img.status !== Image.Ready

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.path === "" ? I18n.tr("Aucune image") : (img.status === Image.Loading ? "" : I18n.tr("Image introuvable"))
            color: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 14
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: root.path === ""
            text: I18n.tr("Clic droit › Choisir une image")
            color: root.look ? root.look.secondary : Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 12
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }
    }
}
