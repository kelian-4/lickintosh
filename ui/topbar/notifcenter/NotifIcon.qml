import QtQuick
import QtQuick.VectorImage
import Quickshell

Item {
    id: root

    property string icon:    ""
    property string appName: ""
    property int    size: 32

    function resolveFromDesktop(name) {
        if (!name || name === "") return ""
        var de = DesktopEntries.heuristicLookup(name)
        if (de && de.icon) {
            var p = Quickshell.iconPath(de.icon, true)
            if (p !== "") return p
            if (de.icon.indexOf("/") === 0) return de.icon
        }
        return ""
    }

    readonly property string resolvedSource: {
        if (root.icon !== "") {
            if (root.icon.startsWith("file://")) return root.icon
            if (root.icon.startsWith("/"))        return "file://" + root.icon
            var byIconName = Quickshell.iconPath(root.icon, true)
            if (byIconName !== "") return byIconName
        }
        var byAppName = root.resolveFromDesktop(root.appName)
        if (byAppName !== "") return byAppName
        return ""
    }

    readonly property bool isSvg: root.resolvedSource.toLowerCase().endsWith(".svg")

    width:  root.size
    height: root.size

    VectorImage {
        anchors.fill: parent
        visible: root.isSvg && root.resolvedSource !== ""
        source: root.isSvg ? root.resolvedSource : ""
        preferredRendererType: VectorImage.CurveRenderer
    }

    Image {
        anchors.fill: parent
        visible: !root.isSvg && root.resolvedSource !== ""
        source: !root.isSvg ? root.resolvedSource : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
    }
}
