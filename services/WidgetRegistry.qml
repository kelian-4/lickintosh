pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "widgetRegistry"

    readonly property var types: [
        { type: "clock",    title: "Clock",       file: "ClockWidget",    sizes: ["s"],           icon: "notch/clock.svg",        tint: "#ff9f0a" },
        { type: "calendar", title: "Calendar",    file: "CalendarWidget", sizes: ["s", "m", "l"], icon: "notch/calender.svg",     tint: "#ff453a" },
        { type: "weather",  title: "Weather",     file: "WeatherWidget",  sizes: ["s", "m", "l"], icon: "weather/cloud-sun.svg",  tint: "#0a84ff" },
        { type: "tasks",    title: "Tasks",       file: "TasksWidget",    sizes: ["s", "m", "l"], icon: "notch/check-circle.svg", tint: "#ff9f0a" },
        { type: "notes",    title: "Notes",       file: "NotesWidget",    sizes: ["s", "m", "l"], icon: "notch/book.svg",         tint: "#ffd60a" },
        { type: "battery",  title: "Battery",     file: "BatteryWidget",  sizes: ["s", "m"],      icon: "notch/battery.svg",      tint: "#30d158" },
        { type: "media",    title: "Now Playing", file: "MediaWidget",    sizes: ["s", "m", "l"], icon: "notch/disc.svg",         tint: "#ff375f" }
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
