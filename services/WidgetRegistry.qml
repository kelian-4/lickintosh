pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "widgetRegistry"

    readonly property var types: [
        { type: "clock",    title: I18n.tr("Clock"),       file: "ClockWidget",    sizes: ["s", "m"],           icon: "notch/clock.svg",        tint: "#ff9f0a",
          variants: [
              { key: "analog",  title: I18n.tr("Analog"),  sizes: ["s"] },
              { key: "digital", title: I18n.tr("Digital"), sizes: ["s", "m"] }
          ] },
        { type: "calendar", title: I18n.tr("Calendar"),    file: "CalendarWidget", sizes: ["s", "m", "l"], icon: "notch/calender.svg",     tint: "#ff453a" },
        { type: "weather",  title: I18n.tr("Weather"),     file: "WeatherWidget",  sizes: ["s", "m", "l"], icon: "weather/cloud-sun.svg",  tint: "#0a84ff" },
        { type: "tasks",    title: I18n.tr("Tasks"),       file: "TasksWidget",    sizes: ["s", "m", "l"], icon: "notch/check-circle.svg", tint: "#ff9f0a" },
        { type: "notes",    title: I18n.tr("Notes"),       file: "NotesWidget",    sizes: ["s", "m", "l"], icon: "notch/book.svg",         tint: "#ffd60a" },
        { type: "battery",  title: I18n.tr("Battery"),     file: "BatteryWidget",  sizes: ["s", "m", "l"],      icon: "notch/battery.svg",      tint: "#30d158" },
        { type: "media",    title: I18n.tr("Now Playing"), file: "MediaWidget",    sizes: ["s", "m", "l"], icon: "notch/disc.svg",         tint: "#ff375f" },
        { type: "timer",    title: I18n.tr("Timer"),       file: "TimerWidget",     sizes: ["s", "m"],           icon: "notch/clock.svg",      tint: "#ff9f0a" },
        { type: "stopwatch", title: I18n.tr("Stopwatch"),  file: "StopwatchWidget", sizes: ["s", "m"],           icon: "notch/crosshair.svg",  tint: "#ff9f0a" },
        { type: "focus",    title: I18n.tr("Focus"),       file: "FocusWidget",     sizes: ["s", "m"],           icon: "notch/target.svg",     tint: "#ff453a" },
        { type: "quote",    title: I18n.tr("Quote of the Day"), file: "QuoteWidget", sizes: ["m", "l"],           icon: "notch/message-square.svg", tint: "#bf5af2" },
        { type: "volume",   title: I18n.tr("Volume"),      file: "VolumeWidget",    sizes: ["s", "m"],           icon: "notch/volume-2.svg",   tint: "#0a84ff" },
        { type: "bluetooth", title: I18n.tr("Bluetooth"),  file: "BluetoothWidget", sizes: ["s", "m", "l"],      icon: "notch/bluetooth.svg",  tint: "#0a84ff" }
    ]

    readonly property var sizeLabels: ({ s: I18n.tr("Small"), m: I18n.tr("Medium"), l: I18n.tr("Large") })

    readonly property var legacy: ({
        digital:   { type: "clock",   variant: "digital" },
        resources: { type: "battery", variant: "" },
        ram:       { type: "battery", variant: "" },
        cpu:       { type: "battery", variant: "" },
        storage:   { type: "battery", variant: "" },
        network:   { type: "battery", variant: "" }
    })

    function resolve(widget) {
        var alias = root.legacy[widget.type]
        var type = alias ? alias.type : widget.type
        var variants = root.variantsOf(type)
        var variant = alias ? alias.variant : (widget.variant || "")
        if (variant === "" && variants.length > 0) variant = variants[0].key
        return { type: type, variant: variant }
    }

    function variantsOf(type) {
        var i = root.info(type)
        if (i && i.variants) return i.variants
        return [{ key: "", title: i ? i.title : type, sizes: i ? i.sizes : ["s"] }]
    }

    function tilesOf(type) {
        var variants = root.variantsOf(type)
        var tiles = []
        variants.forEach(function(v) {
            v.sizes.forEach(function(size) {
                var label = root.sizeLabels[size]
                if (variants.length > 1) label = v.sizes.length > 1 ? v.title + " " + label : v.title
                tiles.push({ size: size, variant: v.key, label: label })
            })
        })
        return tiles
    }

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

    function sizesOf(type, variant) {
        var list = root.variantsOf(type)
        for (var i = 0; i < list.length; i++) {
            if (list[i].key === variant) return list[i].sizes
        }
        return list[0].sizes
    }
}
