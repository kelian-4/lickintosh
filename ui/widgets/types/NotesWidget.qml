import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property string size: "s"
    property bool adding: false

    readonly property int visibleCount: root.size === "l" ? 6 : (root.size === "m" ? 2 : 1)
    readonly property var shown: NotesState.notes.slice(0, root.visibleCount)

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Notes"
                color: "#ffd60a"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
            }

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 11
                color: addArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: root.adding ? "×" : "+"
                    color: "#ffd60a"
                    font.pixelSize: 16
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adding ? root.closeEditor() : root.openEditor()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: root.size === "s"
            Layout.preferredHeight: 54
            visible: root.adding
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.10)
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
                    color: "#ffffff"
                    selectedTextColor: "#000000"
                    selectionColor: "#ffd60a"
                    font.pixelSize: 13
                    font.family: "SF Pro Rounded"
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
                        text: "New note…"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font: editor.font
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.shown.length === 0 && !root.adding
            text: "No Notes"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 13
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.adding && root.size === "s" ? [] : root.shown

            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: noteText.implicitHeight
                color: "transparent"

                Text {
                    id: noteText
                    anchors.left: parent.left
                    anchors.right: removeButton.left
                    anchors.rightMargin: 4
                    text: row.modelData.text
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: root.size === "s" ? 5 : (root.size === "m" ? 2 : 3)
                    elide: Text.ElideRight
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering
                }

                Text {
                    id: removeButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: "×"
                    color: removeArea.containsMouse ? "#ff453a" : Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 16
                    font.family: "SF Pro Rounded"
                    renderType: Text.NativeRendering

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotesState.removeNote(row.modelData.id)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
