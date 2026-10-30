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
    property bool composing: false
    property bool edited: false

    readonly property var current: {
        const list = NotesState.notes
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === root.selectedId) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }

    readonly property bool dirty: root.composing || root.edited
    readonly property bool canValidate: editor.text.trim() !== ""

    function title(note) {
        const first = note.text.split("\n")[0].trim()
        return first !== "" ? first : "Note"
    }

    function select(id) {
        root.edited = false
        root.selectedId = id
        editor.text = root.current ? root.current.text : ""
    }

    function startCompose() {
        root.edited = false
        root.composing = true
        editor.text = ""
        editor.forceActiveFocus()
    }

    function cancel() {
        root.edited = false
        root.composing = false
        editor.text = root.current ? root.current.text : ""
        editor.focus = false
    }

    function validate() {
        if (!root.canValidate) return
        if (root.composing) {
            NotesState.addNote(editor.text)
            root.composing = false
            root.selectedId = NotesState.notes[0].id
        } else {
            NotesState.updateNote(root.current.id, editor.text)
        }
        root.edited = false
        editor.text = root.current.text
        editor.focus = false
    }

    function remove() {
        if (!root.current || root.dirty) return
        const id = root.current.id
        root.edited = false
        root.selectedId = ""
        NotesState.removeNote(id)
        editor.text = root.current ? root.current.text : ""
    }

    Binding {
        target: editor
        property: "text"
        value: root.current ? root.current.text : ""
        when: !root.dirty
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
                visible: root.current !== null && !root.dirty
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
                visible: !root.dirty
                Layout.preferredHeight: 18
                Layout.preferredWidth: newLabel.implicitWidth + 16
                radius: 9
                color: "#1C7AFF"

                Text {
                    id: newLabel
                    anchors.centerIn: parent
                    text: "+ Nouvelle"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "SF Pro Text"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startCompose()
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
            opacity: root.dirty ? 0.4 : 1

            Behavior on opacity { NumberAnimation { duration: 140 } }

            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool active: !root.composing && root.current !== null && root.current.id === chip.modelData.id

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
                    enabled: !root.dirty
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
                    placeholderText: root.composing ? "Écris ta note…" : "Appuie sur + Nouvelle pour écrire une note"
                    placeholderTextColor: "#6A6A6A"
                    readOnly: !root.composing && root.current === null
                    selectByMouse: true
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    onTextEdited: root.edited = true
                    Keys.onPressed: function(event) {
                        if (root.dirty && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                            root.validate()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: root.dirty
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                radius: 11
                color: "#1F1F1F"

                Text {
                    anchors.centerIn: parent
                    text: "Annuler"
                    color: "#E6E6E6"
                    font.pixelSize: 11
                    font.family: "SF Pro Text"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancel()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                radius: 11
                color: root.canValidate ? "#1C7AFF" : "#1F1F1F"

                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "Valider"
                    color: root.canValidate ? "#FFFFFF" : "#6A6A6A"
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "SF Pro Text"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.canValidate
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.validate()
                }
            }
        }
    }
}
