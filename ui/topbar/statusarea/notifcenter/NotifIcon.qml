import QtQuick
import QtQuick.VectorImage
import Quickshell
import qs.services

Item {
    id: root

    property string icon:    ""
    property string appName: ""
    property int    size: 32

    function resolveFromDesktop(name) {
        if (!name || name === "") return ""
        var fromEntry = IconResolver.forAppId(name)
        if (fromEntry !== "") return fromEntry
        var de = DesktopEntries.heuristicLookup(name)
        if (de && de.icon && de.icon.indexOf("/") === 0) return de.icon
        return ""
    }

    readonly property string resolvedSource: {
        if (root.icon !== "") {
            if (root.icon.startsWith("file://")) return root.icon
            if (root.icon.startsWith("/"))        return "file://" + root.icon
            var byIconName = IconResolver.byName(root.icon)
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
