pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    reloadableId: "theme"

    property bool applyToCompositor: true
    property bool settled: false
    property string lastError: ""

    readonly property var blurBase: ({
        enabled: true,
        size: 8,
        passes: 3,
        noise: 0.0117,
        brightness: 1.0,
        contrast: 0.8916,
        vibrancy: 0.1696,
        new_optimizations: true,
        xray: false
    })

    readonly property var blurPresets: [
        { id: "kawase", name: "Flou classique", description: "Kawase, le flou par défaut de Hyprland.", variant: "kawase", overrides: ({}) },
        { id: "haze",   name: "Brume",          description: "Flou diffus à reflets nacrés.",            variant: "haze",   overrides: ({}) },
        { id: "frost",  name: "Givre",          description: "Flou en cristaux de glace.",               variant: "frost",  overrides: ({}) },
        { id: "prism",  name: "Prisme",         description: "Réfraction en facettes triangulaires.",    variant: "prism",  overrides: ({}) },
        { id: "aurora", name: "Aurore",         description: "Voiles de lumière animés.",                variant: "aurora", overrides: ({}) }
    ]

    function presetById(id) {
        for (var i = 0; i < root.blurPresets.length; i++) {
            if (root.blurPresets[i].id === id)
                return root.blurPresets[i]
        }
        return null
    }

    readonly property string rawMode: ShellConfig.options.appearance.mode
    readonly property string rawPreset: ShellConfig.options.appearance.blurPreset

    readonly property string mode: (root.rawMode === "light" || root.rawMode === "dark") ? root.rawMode : "glass"

    readonly property string blurPreset: {
        if (root.presetById(root.rawPreset) !== null)
            return root.rawPreset
        if (root.rawMode.indexOf("blur:") === 0 && root.presetById(root.rawMode.substring(5)) !== null)
            return root.rawMode.substring(5)
        return ""
    }

    readonly property var blurPresetData: root.presetById(root.blurPreset)
    readonly property bool compositorBlur: root.blurPreset !== ""
    readonly property real blurWindowOpacity: Math.max(0.3, Math.min(1.0, ShellConfig.options.appearance.blurWindowOpacity))

    readonly property bool isGlass: root.mode === "glass"
    readonly property bool isLight: root.mode === "light"
    readonly property bool isDark:  root.mode === "dark"

    function setMode(m) {
        ShellConfig.options.appearance.mode = m
    }

    function setBlurPreset(id) {
        ShellConfig.options.appearance.blurPreset = id
    }

    function setBlurWindowOpacity(v) {
        ShellConfig.options.appearance.blurWindowOpacity = v
    }

    readonly property var palettes: ({
        glass: {
            textPrimary:    "#ffffff",
            textSecondary:  "#a0ffffff",
            textTertiary:   "#80ffffff",
            textQuaternary: "#50ffffff",
            separator:      "#18ffffff",
            accent:         "#1c7aff",
            onAccent:       "#ffffff",
            window:         "#0d0d0d",
            panel:          "#30161616",
            panelRim:       "#20ffffff",
            card:           "#18000000",
            cardRim:        "#20ffffff",
            fillHover:      "#10ffffff",
            fillRow:        "#0cffffff",
            fillSubtle:     "#12ffffff",
            fillControl:    "#18ffffff",
            controlRim:     "#14ffffff",
            controlTrack:   "#20000000",
            scrollbar:      "#50ffffff",
            shadow:         "#40000000",
            glassTint:      "transparent"
        },
        light: {
            textPrimary:    Qt.rgba(0, 0, 0, 0.847),
            textSecondary:  Qt.rgba(0, 0, 0, 0.498),
            textTertiary:   Qt.rgba(0, 0, 0, 0.259),
            textQuaternary: Qt.rgba(0, 0, 0, 0.098),
            separator:      Qt.rgba(0, 0, 0, 0.098),
            accent:         "#0088ff",
            onAccent:       "#ffffff",
            window:         "#ececec",
            panel:          "#f4f4f4",
            panelRim:       Qt.rgba(0, 0, 0, 0.098),
            card:           "#ffffff",
            cardRim:        Qt.rgba(0, 0, 0, 0.098),
            fillHover:      Qt.rgba(0, 0, 0, 0.06),
            fillRow:        Qt.rgba(0, 0, 0, 0.04),
            fillSubtle:     Qt.rgba(0, 0, 0, 0.05),
            fillControl:    Qt.rgba(0, 0, 0, 0.07),
            controlRim:     Qt.rgba(0, 0, 0, 0.098),
            controlTrack:   Qt.rgba(0, 0, 0, 0.12),
            scrollbar:      Qt.rgba(0, 0, 0, 0.35),
            shadow:         Qt.rgba(0, 0, 0, 0.18),
            glassTint:      Qt.rgba(1, 1, 1, 0.45)
        },
        dark: {
            textPrimary:    Qt.rgba(1, 1, 1, 0.847),
            textSecondary:  Qt.rgba(1, 1, 1, 0.549),
            textTertiary:   Qt.rgba(1, 1, 1, 0.247),
            textQuaternary: Qt.rgba(1, 1, 1, 0.098),
            separator:      Qt.rgba(1, 1, 1, 0.098),
            accent:         "#0091ff",
            onAccent:       "#ffffff",
            window:         "#323232",
            panel:          "#282828",
            panelRim:       Qt.rgba(1, 1, 1, 0.098),
            card:           Qt.rgba(1, 1, 1, 0.06),
            cardRim:        Qt.rgba(1, 1, 1, 0.098),
            fillHover:      Qt.rgba(1, 1, 1, 0.08),
            fillRow:        Qt.rgba(1, 1, 1, 0.05),
            fillSubtle:     Qt.rgba(1, 1, 1, 0.07),
            fillControl:    Qt.rgba(1, 1, 1, 0.10),
            controlRim:     Qt.rgba(1, 1, 1, 0.098),
            controlTrack:   Qt.rgba(1, 1, 1, 0.16),
            scrollbar:      Qt.rgba(1, 1, 1, 0.35),
            shadow:         Qt.rgba(0, 0, 0, 0.45),
            glassTint:      Qt.rgba(0, 0, 0, 0.40)
        }
    })

    readonly property var current: root.palettes[root.mode]

    readonly property color textPrimary:    root.current.textPrimary
    readonly property color textSecondary:  root.current.textSecondary
    readonly property color textTertiary:   root.current.textTertiary
    readonly property color textQuaternary: root.current.textQuaternary
    readonly property color separator:      root.current.separator
    readonly property color accent:         root.current.accent
    readonly property color onAccent:       root.current.onAccent
    readonly property color window:         root.current.window
    readonly property color panel:          root.current.panel
    readonly property color panelRim:       root.current.panelRim
    readonly property color card:           root.current.card
    readonly property color cardRim:        root.current.cardRim
    readonly property color fillHover:      root.current.fillHover
    readonly property color fillRow:        root.current.fillRow
    readonly property color fillSubtle:     root.current.fillSubtle
    readonly property color fillControl:    root.current.fillControl
    readonly property color controlRim:     root.current.controlRim
    readonly property color controlTrack:   root.current.controlTrack
    readonly property color scrollbar:      root.current.scrollbar
    readonly property color shadow:         root.current.shadow
    readonly property color glassTint:      root.current.glassTint
    readonly property color bar:            "transparent"

    function themed(item) {
        if (!item)
            return true
        var w = item.Window ? item.Window.window : null
        if (w && w.themed === false)
            return false
        var p = item
        while (p) {
            if (p.themed === false)
                return false
            p = p.parent
        }
        return true
    }

    function ink(item, secondary) {
        if (root.themed(item))
            return secondary ? root.textSecondary : root.textPrimary
        return secondary ? "#a0ffffff" : "#ffffff"
    }

    function pick(lightValue, legacy) {
        return root.isLight ? lightValue : legacy
    }

    function popup(legacy) {
        return root.isLight ? "#f2f6f6f8" : legacy
    }

    function luma(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }

    function adaptBox(c) {
        if (c.a >= 0.45)
            return c
        if (root.luma(c) > 0.5)
            return Qt.rgba(0, 0, 0, c.a * 0.6)
        return c
    }

    function boxColor(item, c) {
        return root.isLight && root.themed(item) ? root.adaptBox(c) : c
    }

    function boxRim(item, c) {
        return root.isLight && root.themed(item) ? Qt.rgba(0, 0, 0, c.a * 0.5) : c
    }

    function _luaValue(v) {
        if (typeof v === "string")
            return "\"" + v + "\""
        return String(v)
    }

    function blurLua(preset) {
        var merged = {}
        var k
        for (k in root.blurBase)
            merged[k] = root.blurBase[k]
        for (k in preset.overrides)
            merged[k] = preset.overrides[k]
        merged.variant = preset.variant

        var parts = []
        for (k in merged)
            parts.push(k + " = " + root._luaValue(merged[k]))

        var a = root.blurWindowOpacity.toFixed(2)
        var name = "lickintosh-blur-" + Date.now()

        return "hl.config({ decoration = { blur = { " + parts.join(", ") + " } } })\n"
            + "pcall(function() if _G.lickintosh_rule then _G.lickintosh_rule:set_enabled(false) end end)\n"
            + "_G.lickintosh_rule = hl.window_rule({ name = \"" + name + "\", match = { class = \".*\" }, opacity = \"" + a + " override " + a + " override 1.0 override\" })"
    }

    function sync() {
        if (!root.applyToCompositor)
            return
        if (root.compositorBlur && root.blurPresetData !== null) {
            root._run(["hyprctl", "eval", root.blurLua(root.blurPresetData)])
            ShellConfig.options.appearance.blurApplied = true
        } else if (ShellConfig.options.appearance.blurApplied) {
            ShellConfig.options.appearance.blurApplied = false
            root._run(["hyprctl", "reload"])
        }
    }

    readonly property string iconTheme: root.isLight ? "MacTahoe-light" : "MacTahoe-dark"

    function applySystem() {
        if (!root.applyToCompositor)
            return
        var scheme = root.isLight ? "prefer-light" : "prefer-dark"
        var script = "gsettings set org.gnome.desktop.interface color-scheme \"$1\"; "
            + "for d in \"$HOME/.local/share/icons\" \"$HOME/.icons\" /usr/share/icons; do "
            + "if [ -d \"$d/$2\" ]; then gsettings set org.gnome.desktop.interface icon-theme \"$2\"; "
            + "for q in \"$HOME/.config/qt6ct/qt6ct.conf\" \"$HOME/.config/qt5ct/qt5ct.conf\"; do "
            + "[ -f \"$q\" ] && sed -i \"s/^icon_theme=.*/icon_theme=$2/\" \"$q\"; done; "
            + "[ -f \"$HOME/.config/kdeglobals\" ] && sed -i \"/^\\[Icons\\]/,/^\\[/ s/^Theme=.*/Theme=$2/\" \"$HOME/.config/kdeglobals\"; "
            + "break; fi; done"
        systemProc.running = false
        systemProc.command = ["sh", "-c", script, "sh", scheme, root.iconTheme]
        systemProc.running = true
    }

    function migrate() {
        if (!root.applyToCompositor)
            return
        var m = ShellConfig.options.appearance.mode
        if (m.indexOf("blur:") === 0) {
            if (root.presetById(m.substring(5)) !== null)
                ShellConfig.options.appearance.blurPreset = m.substring(5)
            ShellConfig.options.appearance.mode = "glass"
        }
    }

    function _run(cmd) {
        hyprProc.running = false
        hyprProc.command = cmd
        hyprProc.running = true
    }

    Process {
        id: hyprProc
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out.length > 0 && out !== "ok") {
                    root.lastError = out
                    console.warn("Theme: hyprctl a répondu : " + out)
                } else {
                    root.lastError = ""
                }
            }
        }
    }

    Process {
        id: systemProc
    }

    Timer {
        id: syncTimer
        interval: 150
        onTriggered: root.sync()
    }

    Timer {
        id: systemTimer
        interval: 60
        onTriggered: root.applySystem()
    }

    Timer {
        id: settleTimer
        interval: 800
        onTriggered: root.settled = true
    }

    onModeChanged: if (root.settled) systemTimer.restart()
    onBlurPresetChanged: if (ShellConfig.ready) syncTimer.restart()
    onBlurWindowOpacityChanged: if (ShellConfig.ready && root.compositorBlur) syncTimer.restart()

    Connections {
        target: ShellConfig
        function onReadyChanged() {
            if (!ShellConfig.ready)
                return
            root.migrate()
            syncTimer.restart()
            settleTimer.restart()
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.compositorBlur)
                syncTimer.restart()
        }
    }
}
