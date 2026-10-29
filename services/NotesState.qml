pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "notesState"

    readonly property string filePath: "$HOME/.config/quickshell/core/notes.json"
    property alias notes: notesAdapter.list

    FileView {
        id: notesFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: notesAdapter
            property list<var> list: []
        }
    }

    function addNote(text) {
        if (!text || text.trim() === "") return
        var list = root.notes.slice()
        list.unshift({ id: "note_" + Date.now(), text: text, createdAt: Date.now() })
        root.notes = list
    }

    function removeNote(id) {
        root.notes = root.notes.filter(function(n) { return n.id !== id })
    }

    function updateNote(id, text) {
        var list = root.notes.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], { text: text })
                root.notes = list
                return
            }
        }
    }
}
