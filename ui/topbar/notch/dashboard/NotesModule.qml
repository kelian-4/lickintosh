import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root
    Layout.preferredWidth: 240
    Layout.fillHeight: true

    property string selectedId: ""

    readonly property var current: {
        const list = NotesState.notes
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === root.selectedId) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }

    function title(note) {
        const first = note.text.split("\n")[0].trim()
        return first !== "" ? first : "Nouvelle note"
    }

    function flush() {
        if (!saveTimer.running) return
        saveTimer.stop()
        if (root.current) NotesState.updateNote(root.current.id, editor.text)
    }

    function select(id) {
        root.flush()
        root.selectedId = id
        editor.text = root.current ? root.current.text : ""
    }

    function create() {
        root.flush()
        root.selectedId = NotesState.createNote()
        editor.text = ""
        editor.forceActiveFocus()
    }

    function remove() {
        if (!root.current) return
        saveTimer.stop()
        const id = root.current.id
        root.selectedId = ""
        NotesState.removeNote(id)
        editor.text = root.current ? root.current.text : ""
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
        onTriggered: if (root.current) NotesState.updateNote(root.current.id, editor.text)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Notes · " + NotesState.notes.length
                color: "#8A8A8A"
                font.pixelSize: 12
                font.bold: true
                font.family: "SF Pro Text"
            }

            Item {
                visible: root.current !== null
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16

                TintedIcon {
                    anchors.centerIn: parent
                    size: 11
                    source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/x.svg")
                    tint: "#8A8A8A"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.remove()
                }
            }

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                radius: 8
                color: "#1C7AFF"

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "SF Pro Text"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.create()
                }
            }
        }

        ListView {
            id: chips
            visible: NotesState.notes.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            orientation: ListView.Horizontal
            spacing: 4
            clip: true
            model: NotesState.notes
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool active: root.current !== null && root.current.id === chip.modelData.id

                width: Math.min(96, label.implicitWidth + 16)
                height: 22
                radius: 11
                color: chip.active ? "#1F1F1F" : "#141414"

                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    id: label
                    anchors.centerIn: parent
                    width: parent.width - 16
                    text: root.title(chip.modelData)
                    color: chip.active ? "#FFFFFF" : "#8A8A8A"
                    font.pixelSize: 11
                    font.family: "SF Pro Text"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.select(chip.modelData.id)
                }
            }
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
                    placeholderText: root.current ? "Écrire une note…" : "Appuie sur + pour créer une note"
                    placeholderTextColor: "#6A6A6A"
                    readOnly: root.current === null
                    selectByMouse: true
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    onTextChanged: if (activeFocus) saveTimer.restart()
                    onActiveFocusChanged: if (!activeFocus) root.flush()
                }
            }
        }
    }
}
