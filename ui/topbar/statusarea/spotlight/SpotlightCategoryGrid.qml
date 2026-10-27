import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property var    items              // liste plate, chaque item a `_category`
    required property var    categoryOrder       // ordre des catégories pour les pastilles
    property bool             sectioned: false   // true => "Suggestions" / "Récents" (fichiers)
    property int              suggestionsCount: 6
    required property string  fontFamily
    required property string  fontFamilyMedium
    required property string  mode               // "apps" | "files"

    signal itemClicked(var data)

    property string activeCategory: ""

    onModeChanged: root.activeCategory = ""

    readonly property var availableCategories: {
        var out = []
        for (var i = 0; i < root.categoryOrder.length; i++) {
            var c = root.categoryOrder[i]
            for (var j = 0; j < root.items.length; j++) {
                if (root.items[j]._category === c) { out.push(c); break }
            }
        }
        return out
    }

    readonly property var filteredItems: root.activeCategory === ""
        ? root.items
        : root.items.filter(function(i) { return i._category === root.activeCategory })

    function activate(data) {
        if (root.mode === "apps") {
            if (typeof data.execute === "function") data.execute()
        } else if (root.mode === "files") {
            Quickshell.execDetached(["xdg-open", data.path])
        }
        root.itemClicked(data)
    }

    component Pill: Rectangle {
        id: pill
        required property string label
        required property bool   active
        signal clicked()
        width:  pillLabel.implicitWidth + 20
        height: 28
        radius: 14
        color:  pill.active ? "#40ffffff" : "#18ffffff"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            id: pillLabel
            anchors.centerIn: parent
            text: pill.label
            color: "#ffffff"
            font.family: root.fontFamilyMedium
            font.pixelSize: 12
            renderType: Text.NativeRendering
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            contentWidth: pillRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: pillRow
                spacing: 6

                Pill { label: "Tout"; active: root.activeCategory === ""; onClicked: root.activeCategory = "" }

                Repeater {
                    model: root.availableCategories
                    delegate: Pill {
                        required property string modelData
                        label:  modelData
                        active: root.activeCategory === modelData
                        onClicked: root.activeCategory = modelData
                    }
                }
            }
        }

        Flickable {
            id: scrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: scrollArea.width
                spacing: 16

                Repeater {
                    model: root.sectioned
                        ? [ { title: "Suggestions", items: root.filteredItems.slice(0, root.suggestionsCount) },
                            { title: "Récents",     items: root.filteredItems.slice(root.suggestionsCount) } ]
                        : [ { title: "", items: root.filteredItems } ]

                    delegate: ColumnLayout {
                        id: section
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        visible: section.modelData.items.length > 0

                        Text {
                            visible: section.modelData.title !== ""
                            text:    section.modelData.title
                            color:   "#ffffff"
                            opacity: 0.55
                            font.family:    root.fontFamilyMedium
                            font.pixelSize: 13
                            font.weight:    Font.DemiBold
                            renderType:     Text.NativeRendering
                            Layout.leftMargin: 4
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: section.modelData.items

                                delegate: Item {
                                    id: tile
                                    required property var modelData
                                    width: 78; height: 90

                                    Rectangle {
                                        id: iconBg
                                        anchors.top:              parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 56; height: 56
                                        color: "transparent"

                                        Image {
                                            id: ico
                                            anchors.fill:    parent
                                            property bool directLoadFailed: false
                                            onStatusChanged: if (status === Image.Error) directLoadFailed = true
                                            source: {
                                                if (tile.modelData.isImage && !directLoadFailed) return "file://" + tile.modelData.path
                                                if (tile.modelData.isWallpaper && !directLoadFailed) return "file://" + tile.modelData.path
                                                if (tile.modelData.clipImage && !directLoadFailed) return "file://" + tile.modelData.clipImage
                                                return Quickshell.iconPath(tile.modelData.icon || "image-x-generic", true)
                                            }
                                            fillMode: (tile.modelData.isImage || tile.modelData.isWallpaper || tile.modelData.clipImage) ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                            sourceSize.width:  112
                                            sourceSize.height: 112
                                            smooth:   true
                                            mipmap:   true
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: ico.status !== Image.Ready
                                            text:    (tile.modelData.name || tile.modelData.title || "?")[0].toUpperCase()
                                            color:          "#ffffff"
                                            font.pixelSize: 20
                                            font.weight:    Font.Bold
                                            renderType:     Text.NativeRendering
                                        }
                                    }

                                    Text {
                                        anchors.top:        iconBg.bottom
                                        anchors.topMargin:  6
                                        anchors.left:       parent.left
                                        anchors.right:      parent.right
                                        horizontalAlignment: Text.AlignHCenter
                                        text:           tile.modelData.name || tile.modelData.title || ""
                                        color:          "#ffffff"
                                        font.family:    root.fontFamily
                                        font.pixelSize: 11
                                        wrapMode:       Text.WordWrap
                                        maximumLineCount: 2
                                        elide:          Text.ElideRight
                                        renderType:     Text.NativeRendering
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked:    root.activate(tile.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
