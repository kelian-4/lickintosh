import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import qs.components.glass
import qs.components
import qs.ui.topbar.menubar.globalmenu

Scope {
    id: root

    property bool opened: false
    property int xPos: 0
    property int yPos: 36
    property list<var> items: []
    signal closeRequested()

    property int subIndex: -1
    property int subX: 0
    property int subY: 0

    onOpenedChanged: if (!root.opened) root.subIndex = -1

    function luaMods(mods) {
        if (!mods || mods === "") return ""
        return mods.trim().split(" ").join(" + ")
    }

    function dispatchArg(mods, key) {
        var modsLua = root.luaMods(mods)
        return modsLua !== ""
            ? "hl.dsp.send_shortcut({ mods = \"" + modsLua + "\", key = \"" + key + "\" })"
            : "hl.dsp.send_shortcut({ key = \"" + key + "\" })"
    }

    function trigger(modelData) {
        if (modelData.chord && modelData.chord.length > 0) {
            var parts = []
            for (var i = 0; i < modelData.chord.length; i++) {
                var step = modelData.chord[i]
                parts.push("hyprctl dispatch \x27" + root.dispatchArg(step.mods, step.key) + "\x27")
            }
            Quickshell.execDetached(["sh", "-c", parts.join(" && sleep 0.05 && ")])
        } else if (modelData.key && modelData.key !== "") {
            Quickshell.execDetached(["hyprctl", "dispatch", root.dispatchArg(modelData.mods, modelData.key)])
        } else {
            return
        }
        root.subIndex = -1
        root.closeRequested()
    }

    function openSub(index, x, y) {
        root.subIndex = index
        root.subX = x
        root.subY = y
    }

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: screen.height
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:globalmenu"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    onClicked: root.closeRequested()
                }

                BoxGlass {
                    id: menuContainer
                    x: root.xPos
                    y: root.yPos
                    width: 300
                    height: itemsColumn.implicitHeight + 12
                    z: 1
                    radius: 10
                    color: Qt.rgba(0.08, 0.08, 0.08, 0.88)
                    rimStrength: 1.7
                    light: "#20ffffff"

                    ColumnLayout {
                        id: itemsColumn
                        x: 0
                        y: 6
                        width: menuContainer.width
                        spacing: 0

                        Repeater {
                            model: root.items

                            delegate: Item {
                                id: menuRow
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: modelData.separator ? 9 : 28

                                property bool isDisabled: menuRow.modelData.disabled === true
                                property bool hasSubmenu: menuRow.modelData.submenu && menuRow.modelData.submenu.length > 0
                                property bool hasAction: (menuRow.modelData.chord && menuRow.modelData.chord.length > 0) || (menuRow.modelData.key && menuRow.modelData.key !== "")

                                Rectangle {
                                    visible: menuRow.modelData.separator === true
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 1
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                }

                                Rectangle {
                                    visible: !menuRow.modelData.separator
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    radius: 6
                                    color: (rowMouse.containsMouse && !menuRow.isDisabled) ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                }

                                RowLayout {
                                    visible: !menuRow.modelData.separator
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 8

                                    VectorImage {
                                        visible: menuRow.modelData.icon ? true : false
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        source: menuRow.modelData.icon ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + menuRow.modelData.icon) : ""
                                        preferredRendererType: VectorImage.CurveRenderer
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1
                                            colorizationColor: menuRow.isDisabled ? Qt.rgba(1, 1, 1, 0.35) : "#FFFFFF"
                                        }
                                    }

                                    CFText {
                                        Layout.fillWidth: true
                                        text: menuRow.modelData.label ? menuRow.modelData.label : ""
                                        font.pixelSize: 13
                                        gray: menuRow.isDisabled
                                    }

                                    CFText {
                                        visible: menuRow.hasSubmenu || menuRow.hasAction
                                        text: menuRow.hasSubmenu
                                              ? "›"
                                              : (menuRow.modelData.chord ? ShortcutSymbols.formatChord(menuRow.modelData.chord) : ShortcutSymbols.format(menuRow.modelData.mods, menuRow.modelData.key))
                                        font.pixelSize: 12
                                        gray: true
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    visible: !menuRow.modelData.separator
                                    anchors.fill: parent
                                    hoverEnabled: !menuRow.isDisabled
                                    enabled: !menuRow.isDisabled
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        if (menuRow.hasSubmenu && root.subIndex !== -1 && root.subIndex !== menuRow.index) {
                                            var p = menuRow.mapToItem(null, menuRow.width, 0)
                                            root.openSub(menuRow.index, p.x, p.y)
                                        }
                                    }
                                    onClicked: {
                                        if (menuRow.hasSubmenu) {
                                            var p = menuRow.mapToItem(null, menuRow.width, 0)
                                            root.openSub(menuRow.index, p.x, p.y)
                                        } else {
                                            root.trigger(menuRow.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: subLoader
                    active: root.subIndex !== -1
                    source: "PopupMenu.qml"
                    onLoaded: {
                        item.opened = Qt.binding(function() { return root.subIndex !== -1 })
                        item.xPos = Qt.binding(function() { return root.subX })
                        item.yPos = Qt.binding(function() { return root.subY })
                        item.items = Qt.binding(function() { return root.subIndex !== -1 ? root.items[root.subIndex].submenu : [] })
                        item.closeRequested.connect(function() {
                            root.subIndex = -1
                            root.closeRequested()
                        })
                    }
                }
            }
        }
    }
}
