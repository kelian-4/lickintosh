import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui.primitives

Item {
    id: root
    signal closeRequested()
    property bool needsKeyboard: false
    property var menuHandle: null

    // Pile de navigation : [] = racine, [entry1] = sous-menu de entry1,
    // [entry1, entry2] = sous-menu de entry2 dans entry1, etc.
    property var _menuStack: []

    readonly property var _currentMenu: _menuStack.length > 0
                                         ? _menuStack[_menuStack.length - 1]
                                         : root.menuHandle
    readonly property string _currentTitle: _menuStack.length > 0
                                             ? (_menuStack[_menuStack.length - 1].text || "")
                                             : ""

    implicitHeight: content.implicitHeight + 16 + (root._menuStack.length > 0 ? 34 : 0)

    onMenuHandleChanged: root._menuStack = []

    QsMenuOpener {
        id: opener
        menu: root._currentMenu
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 8
        spacing: 2

        Item {
            Layout.fillWidth: true
            height: 34
            visible: root._menuStack.length > 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                spacing: 6

                CFText {
                    text: "\u2039"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                CFText {
                    text: root._currentTitle
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var s = root._menuStack.slice()
                    s.pop()
                    root._menuStack = s
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
            visible: root._menuStack.length > 0
        }

        Repeater {
            model: root._currentMenu ? opener.children : []

            Item {
                id: entryRoot
                required property var modelData
                Layout.fillWidth: true
                height: modelData.isSeparator ? 9 : 34

                Rectangle {
                    visible: entryRoot.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: "#20ffffff"
                }

                Rectangle {
                    visible: !entryRoot.modelData.isSeparator
                    anchors.fill: parent
                    radius: 6
                    color: entryMouse.containsMouse && entryRoot.modelData.enabled ? "#14ffffff" : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Item {
                            width: 16
                            height: 16
                            Layout.alignment: Qt.AlignVCenter

                            CFText {
                                anchors.centerIn: parent
                                visible: entryRoot.modelData.checkState === 2
                                text: "\u2713"
                                font.pixelSize: 12
                            }
                        }

                        CFText {
                            text: entryRoot.modelData.text
                            font.pixelSize: 13
                            gray: !entryRoot.modelData.enabled
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        CFText {
                            visible: entryRoot.modelData.hasChildren
                            text: "\u203a"
                            gray: true
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entryRoot.modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (entryRoot.modelData.hasChildren) {
                                var s = root._menuStack.slice()
                                s.push(entryRoot.modelData)
                                root._menuStack = s
                            } else {
                                entryRoot.modelData.triggered()
                                root.closeRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}
