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
        { type: "media",    title: "Now Playing", file: "MediaWidget",    sizes: ["s", "m", "l"], icon: "notch/disc.svg",         tint: "#ff375f" },
        { type: "digital",  title: "Digital Clock", file: "DigitalClockWidget", sizes: ["s", "m"],      icon: "notch/watch.svg",      tint: "#5e5ce6" },
        { type: "resources", title: "System Monitor", file: "ResourcesWidget", sizes: ["s", "m", "l"], icon: "notch/cpu.svg",        tint: "#64d2ff" },
        { type: "ram",      title: "RAM",         file: "RamWidget",       sizes: ["s", "m", "l"], icon: "notch/database.svg",   tint: "#30d158" },
        { type: "cpu",      title: "CPU",         file: "CpuWidget",       sizes: ["s", "m", "l"], icon: "notch/cpu.svg",        tint: "#64d2ff" },
        { type: "storage",  title: "Storage",     file: "StorageWidget",   sizes: ["s", "m"],      icon: "notch/hard-drive.svg", tint: "#ff9f0a" },
        { type: "network",  title: "Network",     file: "NetworkWidget",   sizes: ["s", "m"],      icon: "notch/globe.svg",      tint: "#0a84ff" },
        { type: "timer",    title: "Timer",       file: "TimerWidget",     sizes: ["s", "m"],           icon: "notch/clock.svg",      tint: "#ff9f0a" },
        { type: "stopwatch", title: "Stopwatch",  file: "StopwatchWidget", sizes: ["s", "m"],           icon: "notch/crosshair.svg",  tint: "#ff9f0a" },
        { type: "focus",    title: "Focus",       file: "FocusWidget",     sizes: ["s", "m"],           icon: "notch/target.svg",     tint: "#ff453a" },
        { type: "quote",    title: "Quote of the Day", file: "QuoteWidget", sizes: ["m", "l"],           icon: "notch/message-square.svg", tint: "#bf5af2" },
        { type: "volume",   title: "Volume",      file: "VolumeWidget",    sizes: ["s", "m"],           icon: "notch/volume-2.svg",   tint: "#0a84ff" },
        { type: "bluetooth", title: "Bluetooth",  file: "BluetoothWidget", sizes: ["s", "m", "l"],      icon: "notch/bluetooth.svg",  tint: "#0a84ff" }
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
