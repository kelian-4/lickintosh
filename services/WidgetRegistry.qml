pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "widgetRegistry"

    readonly property var types: [
        { type: "clock",    title: "Clock",       file: "ClockWidget",    sizes: ["s"] },
        { type: "calendar", title: "Calendar",    file: "CalendarWidget", sizes: ["s", "m", "l"] },
        { type: "weather",  title: "Weather",     file: "WeatherWidget",  sizes: ["s", "m", "l"] },
        { type: "tasks",    title: "Tasks",       file: "TasksWidget",    sizes: ["s", "m", "l"] },
        { type: "notes",    title: "Notes",       file: "NotesWidget",    sizes: ["s", "m", "l"] },
        { type: "battery",  title: "Battery",     file: "BatteryWidget",  sizes: ["s", "m"] },
        { type: "media",    title: "Now Playing", file: "MediaWidget",    sizes: ["s", "m", "l"] }
    ]

    readonly property var sizeLabels: ({ s: "Small", m: "Medium", l: "Large" })

    function info(type) {
        for (var i = 0; i < root.types.length; i++) {
            if (root.types[i].type === type) return root.types[i]
        }
        return null
    }

    function fileOf(type) {
        var i = root.info(type)
        return i ? i.file : ""
    }

    function sizesOf(type) {
        var i = root.info(type)
        return i ? i.sizes : ["s"]
    }
}
