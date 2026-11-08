import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"
    property bool adding: false

    readonly property real k: Math.min(root.width / (root.size === "s" ? 140 : 330), root.height / (root.size === "l" ? 326 : 140))

    HoverHandler { id: headHover }

    function openEditor() {
        root.adding = true
        WidgetState.typing = true
        editor.forceActiveFocus()
    }

    function closeEditor() {
        root.adding = false
        editor.text = ""
        WidgetState.typing = false
    }

    function commit() {
        NotesState.addNote(editor.text)
        root.closeEditor()
    }

    Component.onDestruction: {
        if (root.adding) WidgetState.typing = false
    }

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            root.forceActiveFocus()
            mouse.accepted = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8 * root.k

        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * root.k

            Rectangle {
                Layout.preferredWidth: 18 * root.k
                Layout.preferredHeight: 18 * root.k
                radius: 5 * root.k
                color: "#ffd60a"

                Rectangle {
                    x: 3 * root.k
                    y: 4 * root.k
                    width: 12 * root.k
                    height: 1.6 * root.k
                    color: "#ffffff"
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr("Notes")
                elide: Text.ElideRight
                color: "#ffd60a"
                font.pixelSize: 14 * root.k
                font.weight: Font.Bold
                font.family: "SF Pro Display"
                renderType: Text.NativeRendering
            }

            Rectangle {
                Layout.preferredWidth: 20 * root.k
                Layout.preferredHeight: 20 * root.k
                radius: 10 * root.k
                opacity: (headHover.hovered || root.adding) ? 1 : 0
                visible: opacity > 0.01
                color: addArea.containsMouse ? Qt.rgba(1, 0.84, 0.04, 0.22) : "transparent"
                rotation: root.adding ? 45 : 0
                scale: addArea.pressed ? 0.88 : 1

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                Rectangle { anchors.centerIn: parent; width: 11 * root.k; height: 1.7 * root.k; radius: 1; color: "#ffd60a" }
                Rectangle { anchors.centerIn: parent; width: 1.7 * root.k; height: 11 * root.k; radius: 1; color: "#ffd60a" }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adding ? root.closeEditor() : root.openEditor()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: root.size === "s"
            Layout.preferredHeight: 54 * root.k
            visible: root.adding
            radius: 10 * root.k
            color: root.look.surface
            border.width: editor.activeFocus ? 1 : 0
            border.color: "#ffd60a"
            clip: true

            Flickable {
                id: editorScroll
                anchors.fill: parent
                anchors.margins: 8
                contentWidth: width
                contentHeight: editor.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: editor
                    width: editorScroll.width
                    wrapMode: TextEdit.WrapAnywhere
                    onActiveFocusChanged: {
                        if (!editor.activeFocus && root.adding) root.commit()
                    }
                    color: root.look.primary
                    selectedTextColor: "#000000"
                    selectionColor: "#ffd60a"
                    font.pixelSize: 13 * root.k
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                    onCursorRectangleChanged: {
                        if (editor.cursorRectangle.y < editorScroll.contentY)
                            editorScroll.contentY = editor.cursorRectangle.y
                        else if (editor.cursorRectangle.y + editor.cursorRectangle.height > editorScroll.contentY + editorScroll.height)
                            editorScroll.contentY = editor.cursorRectangle.y + editor.cursorRectangle.height - editorScroll.height
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            root.closeEditor()
                            event.accepted = true
                        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                            root.commit()
                            event.accepted = true
                        }
                    }

                    Text {
                        visible: editor.text === "" && !editor.preeditText
                        text: I18n.tr("New note…")
                        color: root.look.tertiary
                        font: editor.font
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: NotesState.notes.length === 0 && !root.adding
            text: I18n.tr("No Notes")
            color: root.look.secondary
            font.pixelSize: 13 * root.k
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !(root.adding && root.size === "s")
            contentWidth: width
            contentHeight: notesColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: notesColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: NotesState.notes

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: noteText.implicitHeight + 9 * root.k

                        Rectangle {
                            visible: row.index > 0
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 1
                            color: root.look.divider
                        }

                        HoverHandler { id: rowHover }

                        Text {
                            id: noteText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.rightMargin: 20 * root.k
                            anchors.bottom: parent.bottom
                            text: row.modelData.text
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: root.size === "s" ? 5 : (root.size === "m" ? 2 : 3)
                            elide: Text.ElideRight
                            lineHeight: 1.12
                            color: root.look.primary
                            font.pixelSize: 13 * root.k
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: removeButton
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            text: "\u00D7"
                            opacity: rowHover.hovered ? 1 : 0
                            color: removeArea.containsMouse ? "#ff453a" : root.look.tertiary
                            font.pixelSize: 15 * root.k
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering

                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            MouseArea {
                                id: removeArea
                                anchors.fill: parent
                                anchors.margins: -5
                                enabled: rowHover.hovered
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotesState.removeNote(row.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
