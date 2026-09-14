pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "tasksState"

    readonly property string filePath: "$HOME/.config/quickshell/core/tasks.json"
    property alias tasks: tasksAdapter.list

    readonly property var pending: root.tasks.filter(function(t) { return !t.done })
    readonly property var done:    root.tasks.filter(function(t) { return t.done })

    FileView {
        id: tasksFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: tasksAdapter
            property list<var> list: []
        }
    }

    function addTask(text) {
        if (!text || text.trim() === "") return
        var list = root.tasks.slice()
        list.push({ id: "task_" + Date.now(), text: text, done: false, createdAt: Date.now() })
        root.tasks = list
    }

    function toggleTask(id) {
        var list = root.tasks.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], { done: !list[i].done })
                root.tasks = list
                return
            }
        }
    }

    function removeTask(id) {
        root.tasks = root.tasks.filter(function(t) { return t.id !== id })
    }
}
