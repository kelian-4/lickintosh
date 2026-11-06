pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var styles: [
        { name: "SF Pro",           family: "SF Pro Display", italic: false, spacing: 0 },
        { name: "SF Pro Rounded",   family: "SF Pro Rounded", italic: false, spacing: 0 },
        { name: "SF Pro Italique",  family: "SF Pro Display", italic: true,  spacing: 0 },
        { name: "SF Mono",          family: "SF Mono",        italic: false, spacing: 0 },
        { name: "Serif",            family: "serif",          italic: false, spacing: 0 },
        { name: "Arrondi espacé",   family: "SF Pro Rounded", italic: false, spacing: 6 }
    ]

    function styleAt(i) {
        const n = root.styles.length
        return root.styles[Math.max(0, Math.min(n - 1, Math.round(i)))]
    }

    function weightFor(v) {
        const c = Math.max(0, Math.min(1, v))
        return Math.round((100 + c * 800) / 100) * 100
    }
}
