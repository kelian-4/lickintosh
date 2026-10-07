pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "tasksState"

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string filePath: root.cacheDir + "/spotlight_todos.json"

    property var tasks: []

    readonly property var pending: root.tasks.filter(function(t) { return !t.done })
    readonly property var done:    root.tasks.filter(function(t) { return t.done })

    function parse(raw) {
        try {
            var data = JSON.parse(raw && raw.trim() !== "" ? raw : "[]")
            root.tasks = Array.isArray(data) ? data : []
        } catch (e) {
            root.tasks = []
        }
    }

    function save() {
        tasksFile.setText(JSON.stringify(root.tasks))
    }

    function addTask(text) {
        if (!text || text.trim() === "") return
        var list = root.tasks.slice()
        list.unshift({ id: Date.now(), text: text, done: false })
        root.tasks = list
        root.save()
    }

    function toggleTask(id) {
        var list = []
        for (var i = 0; i < root.tasks.length; i++) {
            var t = root.tasks[i]
            list.push(t.id === id ? { id: t.id, text: t.text, done: !t.done } : t)
        }
        root.tasks = list
        root.save()
    }

    function removeTask(id) {
        root.tasks = root.tasks.filter(function(t) { return t.id !== id })
        root.save()
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.cacheDir]
    }

    FileView {
        id: tasksFile
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.tasks = []
    }
}
