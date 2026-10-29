import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

Item {
    id: root
    Layout.preferredWidth: 200
    Layout.fillHeight: true

    readonly property var current: NotesState.notes.length > 0 ? NotesState.notes[0] : null

    function commit() {
        if (root.current) NotesState.updateNote(root.current.id, editor.text)
        else NotesState.addNote(editor.text)
    }

    Binding {
        target: editor
        property: "text"
        value: root.current ? root.current.text : ""
        when: !editor.activeFocus
    }

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: root.commit()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Text {
            text: "Notes"
            color: "#8A8A8A"
            font.pixelSize: 12
            font.bold: true
            font.family: "SF Pro Text"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: "#141414"
            border.width: 1
            border.color: editor.activeFocus ? "#1C7AFF" : "#262626"

            Behavior on border.color { ColorAnimation { duration: 160 } }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 6

                TextArea {
                    id: editor
                    background: null
                    padding: 2
                    wrapMode: TextEdit.Wrap
                    color: "#E6E6E6"
                    placeholderText: "Écrire une note…"
                    placeholderTextColor: "#6A6A6A"
                    selectByMouse: true
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    onTextChanged: if (activeFocus) saveTimer.restart()
                    onActiveFocusChanged: if (!activeFocus && saveTimer.running) {
                        saveTimer.stop()
                        root.commit()
                    }
                }
            }
        }
    }
}
