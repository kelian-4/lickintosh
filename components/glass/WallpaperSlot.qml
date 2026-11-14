import QtQuick

Loader {
    id: slot

    property string path: ""
    property size targetSize: Qt.size(0, 0)
    readonly property int imageStatus: item ? item.status : Image.Null
    signal ready()

    sourceComponent: path === "" ? null : (path.indexOf("itemgrabber") === 0 ? grabImage : fileImage)
    onImageStatusChanged: if (imageStatus === Image.Ready) ready()

    Component {
        id: fileImage
        Image {
            source: GlassWallpaper.sourceUrl(slot.path)
            sourceSize: slot.targetSize
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            onStatusChanged: if (status === Image.Ready) slot.ready()
        }
    }

    Component {
        id: grabImage
        Image {
            source: GlassWallpaper.sourceUrl(slot.path)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            onStatusChanged: if (status === Image.Ready) slot.ready()
        }
    }
}
