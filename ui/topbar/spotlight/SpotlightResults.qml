import Quickshell
import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import qs.ui.glass

ListView {
    id: root

    required property string      searchText
    required property list<var>   answers
    required property string      fontFamily
    required property string      fontFamilyMedium
    required property int         currentIdx
    property bool                 showWhenEmpty: false

    signal itemClicked(var data)
    signal hoveredIdx(int idx)

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

    delegate: Item {
        id:       row
        required property var modelData
        required property int index
        width:    root.width
        height:   50

        property bool isApp:    typeof row.modelData.execute === "function"
        property bool isCurrent: row.index === root.currentIdx

        function activate() {
            if (row.modelData.dummy) {
                
                return
            }

            if (row.isApp) {
                row.modelData.execute()
                root.itemClicked(row.modelData)
            } else if (row.modelData.isWallpaper) {
                var p = row.modelData.path
                Quickshell.execDetached(["awww", "img", p, "--transition-bezier", ".43,1.19,1,.4", "--transition-type", "random"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.isCalc) {
                Quickshell.execDetached(["sh", "-c", "echo -n '" + row.modelData.value + "' | wl-copy"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.isWeb) {
                
                Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(row.modelData.query)])
                root.itemClicked(row.modelData)
            } else if (row.modelData.rawLine) {
                Quickshell.execDetached(["sh", "-c", "printf '%s' '" + row.modelData.rawLine.replace(/'/g, "") + "' | cliphist decode | wl-copy"])
                root.itemClicked(row.modelData)
            } else if (row.modelData.cmd) {
                Quickshell.execDetached(["sh", "-c", row.modelData.cmd])
                root.itemClicked(row.modelData)
            } else if (row.modelData.path) {
                Quickshell.execDetached(["xdg-open", row.modelData.path])
                root.itemClicked(row.modelData)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius:       12
            color:        row.isCurrent ? "#50ffffff" : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            id:     iconBg
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     12
            width: 36; height: 36; radius: 9
            color: "#20ffffff"
            clip:  true

            Image {
                id:       ico
                anchors.fill: parent
                visible:  !row.modelData.icon || !row.modelData.icon.endsWith(".svg")
                source: {
                    if (row.isApp) return Quickshell.iconPath(row.modelData.icon, true)
                    if (row.modelData.isWallpaper) return "file://" + row.modelData.path
                    if (row.modelData.icon && !row.modelData.icon.endsWith(".svg")) return Quickshell.iconPath(row.modelData.icon, true)
                    return ""
                }
                fillMode: row.modelData.isWallpaper ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                smooth:   true
                mipmap:   true
            }

            VectorImage {
                anchors.centerIn: parent
                width: 22; height: 22
                visible: row.modelData.icon && row.modelData.icon.endsWith(".svg")
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
                visible:  (!row.isApp && !row.modelData.isWallpaper && !row.modelData.icon) || (ico.status !== Image.Ready && !row.modelData.icon)
                text:     (row.modelData.name || row.modelData.title || "?")[0].toUpperCase()
                color:          "#ffffff"
                font.pixelSize: 16
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
            color:          "#ffffff"
            font.family:    root.fontFamilyMedium
            font.pixelSize: 15
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
                if (row.modelData.isWeb) return "Recherche Web"
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
