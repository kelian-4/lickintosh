import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import qs.ui.glass

ListView {
    id: root

    required property string      searchText
    required property list<var>   answers
    required property string      fontFamily
    required property string      fontFamilyMedium
    required property int         currentIdx
    property bool                 showWhenEmpty: false
    property bool                 sectioned: false

    signal itemClicked(var data)
    signal hoveredIdx(int idx)
    signal reindexRequested()
    signal randomWallpaperRequested()
    signal shellCmdRequested(string cmd)
    signal todoAddRequested(string text)
    signal todoItemActivated(var id, bool done)

    function shQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function activateIndex(idx) {
        var item = itemAtIndex(idx)
        if (item) item.activate()
    }

    onCurrentIdxChanged: {
        positionViewAtIndex(currentIdx, ListView.Contain)
    }

    spacing: 2
    implicitHeight: contentHeight
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
        values: (root.searchText === "" && !root.showWhenEmpty) ? [] : root.answers
    }

    delegate: Column {
        id:       row
        required property var modelData
        required property int index
        width:    root.width
        spacing:  0

        property bool isApp:     typeof row.modelData.execute === "function"
        property bool isCurrent: row.index === root.currentIdx
        readonly property bool showHeader: root.sectioned && !!row.modelData._section
            && (row.index === 0 || !root.answers[row.index - 1] || root.answers[row.index - 1]._section !== row.modelData._section)

        function activate() {
            if (row.modelData.dummy) {
                return
            }

            if (row.isApp) {
                row.modelData.execute()
                root.itemClicked(row.modelData)
            } else if (row.modelData.isWallpaper) {
                root.itemClicked(row.modelData)
            } else if (row.modelData.isCalc) {
                Quickshell.execDetached(["sh", "-c", "echo -n '" + row.modelData.value + "' | wl-copy"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.isWeb) {
                Quickshell.execDetached(["xdg-open", "https://search.brave.com/search?q=" + encodeURIComponent(row.modelData.query)])
                root.itemClicked(row.modelData)
            } else if (row.modelData.clipImage) {
                Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < '" + row.modelData.clipImage + "'"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.clipFile) {
                Quickshell.execDetached(["bash", "-c", "wl-copy < '" + row.modelData.clipFile + "'"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.isEmoji) {
                Quickshell.execDetached(["sh", "-c", "printf '%s' " + root.shQuote(row.modelData.value) + " | wl-copy"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.isShellCmd) {
                root.shellCmdRequested(row.modelData.value)
            } else if (row.modelData.isTodoAdd) {
                root.todoAddRequested(row.modelData.value)
            } else if (row.modelData.isTodoItem) {
                root.todoItemActivated(row.modelData.todoId, row.modelData.todoDone)
            } else if (row.modelData.randomWallpaper) {
                root.randomWallpaperRequested()
                root.itemClicked(row.modelData)
            } else if (row.modelData.reindex) {
                root.reindexRequested()
                root.itemClicked(row.modelData)
            } else if (row.modelData.cmd) {
                Quickshell.execDetached(["sh", "-c", row.modelData.cmd])
                root.itemClicked(row.modelData)
            } else if (row.modelData.path) {
                Quickshell.execDetached(["xdg-open", row.modelData.path])
                root.itemClicked(row.modelData)
            }
        }

        Text {
            visible: row.showHeader
            width: row.width
            topPadding: row.index === 0 ? 2 : 14
            bottomPadding: 4
            leftPadding: 12
            text: row.modelData._section || ""
            color: "#ffffff"
            opacity: 0.5
            font.family:    root.fontFamilyMedium
            font.pixelSize: 12
            font.weight:    Font.DemiBold
            renderType:     Text.NativeRendering
        }

        Item {
        id: content
        width:    row.width
        height:   50

        Rectangle {
            anchors.fill: parent
            radius:       12
            color:        row.isCurrent ? "#50ffffff" : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Item {
            id:     iconBg
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     12
            width: 36; height: 36

            Image {
                id:       ico
                anchors.fill: parent
                visible:  !row.modelData.icon || !row.modelData.icon.endsWith(".svg")
                property bool directLoadFailed: false
                onStatusChanged: if (status === Image.Error) directLoadFailed = true
                source: {
                    if (row.isApp) return Quickshell.iconPath(row.modelData.icon, true)
                    if (row.modelData.isWallpaper && !directLoadFailed) return "file://" + row.modelData.path
                    if (row.modelData.clipImage && !directLoadFailed) return "file://" + row.modelData.clipImage
                    if (row.modelData.isImage && !directLoadFailed) return "file://" + row.modelData.path
                    if (row.modelData.isEmoji) return row.modelData.emojiUrl
                    if (row.modelData.icon && !row.modelData.icon.endsWith(".svg")) return Quickshell.iconPath(row.modelData.icon, true)
                    return Quickshell.iconPath("image-x-generic", true)
                }
                fillMode: (row.modelData.isWallpaper || row.modelData.clipImage || row.modelData.isImage) ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                sourceSize.width:  72
                sourceSize.height: 72
                smooth:   true
                mipmap:   true
            }

            VectorImage {
                anchors.centerIn: parent
                width: 22; height: 22
                visible: !!(row.modelData.icon && row.modelData.icon.endsWith(".svg"))
                source: row.modelData.icon && row.modelData.icon.endsWith(".svg") 
                        ? (row.modelData.icon.startsWith("/") ? "file://" + row.modelData.icon : Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + row.modelData.icon))
                        : ""
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: "#ffffff"
                }
            }

            Text {
                anchors.centerIn: parent
                visible:  (!row.isApp && !row.modelData.isWallpaper && !row.modelData.clipImage && !row.modelData.isImage && !row.modelData.isEmoji && !row.modelData.icon) || (ico.status !== Image.Ready && !row.modelData.icon)
                text:     row.modelData.isEmoji ? row.modelData.value : (row.modelData.name || row.modelData.title || "?")[0].toUpperCase()
                color:          "#ffffff"
                font.pixelSize: row.modelData.isEmoji ? 20 : 16
                font.weight:    Font.Bold
                renderType:     Text.NativeRendering
            }
        }

        Text {
            anchors.top:         parent.top
            anchors.topMargin:   8
            anchors.left:        iconBg.right
            anchors.leftMargin:  10
            anchors.right:       parent.right
            anchors.rightMargin: 12
            text:           row.modelData.name || row.modelData.title || ""
            color:          row.modelData.isTodoItem && row.modelData.todoDone ? "#80ffffff" : "#ffffff"
            font.family:    root.fontFamilyMedium
            font.pixelSize: 15
            font.strikeout: !!(row.modelData.isTodoItem && row.modelData.todoDone)
            font.weight:    Font.Medium
            renderType:     Text.NativeRendering
            elide:          Text.ElideRight
        }

        Text {
            anchors.bottom:       parent.bottom
            anchors.bottomMargin: 8
            anchors.left:         iconBg.right
            anchors.leftMargin:   10
            anchors.right:        parent.right
            anchors.rightMargin:  12
            text: {
                if (row.isApp) return "Application"
                if (row.modelData.isWallpaper) return "Fond d'écran"
                if (row.modelData.isCalc) return "Calculatrice"
                if (row.modelData.isWeb) return "Recherche"
                return row.modelData.description || ""
            }
            color:          "#80ffffff"
            font.family:    root.fontFamily
            font.pixelSize: 12
            renderType:     Text.NativeRendering
            elide:          Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onEntered:  { root.hoveredIdx(row.index) }
            onClicked: {
                if (row.modelData.dummy && row.modelData.targetPrefix) {
                    searchField.applyPrefix(row.modelData.targetPrefix)
                } else {
                    row.activate()
                }
            }
        }
        }
    }
}
