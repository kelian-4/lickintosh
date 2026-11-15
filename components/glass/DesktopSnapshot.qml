import QtQuick
import qs.services

Item {
    id: root

    property bool shown: true

    visible: root.shown

    // Widgets du bureau : ils font partie de ce que le verre doit voir
    Item {
        x: WidgetState.desktopOffsetX
        y: WidgetState.desktopOffsetY

        Repeater {
            model: WidgetState.desktop

            // Chargement par URL : evite un import circulaire entre components/glass et ui/widgets
            delegate: Loader {
                id: wl
                required property var modelData
                readonly property var spec: WidgetState.entryOf("desktop", wl.modelData.id) || wl.modelData

                x: wl.spec.x
                y: wl.spec.y
                Component.onCompleted: wl.setSource(Qt.resolvedUrl("../../ui/widgets/WidgetView.qml"), { snapshot: true, widgetData: wl.spec })
                onLoaded: wl.item.widgetData = Qt.binding(function() { return wl.spec })
            }
        }
    }

    Repeater {
        model: DesktopFiles.layout

        delegate: Item {
            id: cell
            required property var modelData

            x: cell.modelData.x
            y: cell.modelData.y
            width: cell.modelData.w
            height: cell.modelData.h

            Image {
                id: glyph
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 56
                height: 56
                source: !cell.modelData.isDir && DesktopFiles.isImage(cell.modelData.name)
                    ? "file://" + cell.modelData.path
                    : DesktopFiles.iconPathFor(cell.modelData.name, cell.modelData.isDir)
                sourceSize: Qt.size(112, 112)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            Text {
                anchors.top: glyph.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                horizontalAlignment: Text.AlignHCenter
                text: DesktopFiles.labelFor(cell.modelData.name)
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: "#ffffff"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.55)
                font.pixelSize: 12
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }
        }
    }
}
