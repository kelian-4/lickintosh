import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui.primitives

Item {
    id: root
    signal closeRequested()
    property bool needsKeyboard: false
    property var menuHandle: null
    implicitHeight: content.implicitHeight + 16

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
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

        Repeater {
            model: root.menuHandle ? opener.children : []

            Item {
                id: entryRoot
                Layout.fillWidth: true
                height: modelData.isSeparator ? 9 : 34

                Rectangle {
                    visible: modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: "#20ffffff"
                }

                Rectangle {
                    visible: !modelData.isSeparator
                    anchors.fill: parent
                    radius: 6
                    color: entryMouse.containsMouse && modelData.enabled ? "#14ffffff" : "transparent"

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
                                visible: modelData.checkState === 2
                                text: "\u2713"
                                font.pixelSize: 12
                            }
                        }

                        CFText {
                            text: modelData.text
                            font.pixelSize: 13
                            gray: !modelData.enabled
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        CFText {
                            visible: modelData.hasChildren
                            text: "\u203a"
                            gray: true
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.triggered()
                            root.closeRequested()
                        }
                    }
                }
            }
        }
    }
}
