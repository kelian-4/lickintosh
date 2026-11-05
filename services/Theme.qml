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

    readonly property var blurGeneral: [
        { key: "size", label: "Taille du flou", type: "int", min: 1, max: 50, def: 8 },
        { key: "passes", label: "Passes", type: "int", min: 1, max: 10, def: 3 },
        { key: "noise", label: "Bruit", type: "float", min: 0, max: 1, def: 0.0117 },
        { key: "brightness", label: "Luminosité", type: "float", min: 0, max: 2, def: 1.0 },
        { key: "contrast", label: "Contraste", type: "float", min: 0, max: 2, def: 0.8916 },
        { key: "vibrancy", label: "Vibrance", type: "float", min: 0, max: 1, def: 0.1696 },
        { key: "vibrancy_darkness", label: "Vibrance des zones sombres", type: "float", min: 0, max: 1, def: 0.0 },
        { key: "xray", label: "Flou xray", type: "bool", def: false },
        { key: "new_optimizations", label: "Optimisations du flou", type: "bool", def: true },
        { key: "popups", label: "Flou des menus contextuels", type: "bool", def: false }
    ]

    readonly property var glassSpecs: [
        { key: "glass.refraction", label: "Réfraction", type: "float", min: 0, max: 20, def: 20.0 },
        { key: "glass.roughness", label: "Rugosité", type: "float", min: 0, max: 1, def: 1.0 },
        { key: "glass.size", label: "Taille du motif", type: "float", min: 4, max: 512, def: 40.0 }
    ]

    readonly property var variantTable: ({
        kawase: [],
        frost: [],
        prism: root.glassSpecs,
        haze: [
            { key: "haze.intensity", label: "Intensité du voile", type: "float", min: 0, max: 1, def: 0.35 },
            { key: "haze.iridescence", label: "Iridescence", type: "float", min: 0, max: 1, def: 0.7 }
        ],
        aurora: [
            { key: "aurora.intensity", label: "Intensité de l'aurore", type: "float", min: 0, max: 1, def: 0.35 },
            { key: "aurora.speed", label: "Vitesse", type: "float", min: 0, max: 10, def: 1.0 }
        ].concat(root.glassSpecs)
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
    readonly property real blurWindowOpacityInactive: Math.max(0.3, Math.min(1.0, ShellConfig.options.appearance.blurWindowOpacityInactive))
    readonly property var blurParams: ShellConfig.options.appearance.blurParams
    readonly property var variantSpecList: root.blurPresetData ? root.variantTable[root.blurPresetData.variant] : []
    readonly property color blurSurface: root.isLight ? Qt.rgba(1, 1, 1, ShellConfig.options.appearance.blurSurfaceAlpha) : Qt.rgba(0, 0, 0, ShellConfig.options.appearance.blurSurfaceAlpha)

    readonly property var elementSpecs: [
        { key: "refractionWidth",     label: "Réfraction",              min: 0, max: 60,  def: 18 },
        { key: "magnifyGlassStrength", label: "Grossissement",          min: 0, max: 0.5, def: 0.1 },
        { key: "rgbDriftStrength",    label: "Dispersion chromatique",  min: 0, max: 30,  def: 12 },
        { key: "highlightWidth",      label: "Largeur du reflet",       min: 0, max: 12,  def: 3.5 },
        { key: "highlightStrength",   label: "Intensité du reflet",     min: 0, max: 1,   def: 0.1 },
        { key: "saturation",          label: "Saturation",              min: 0, max: 2.5, def: 1.33 },
        { key: "materialOpacity",     label: "Opacité du matériau",     min: 0, max: 1,   def: 1 },
        { key: "centerOpacity",       label: "Opacité du centre",       min: 0, max: 1,   def: 0.98 },
        { key: "blurRadius",          label: "Rayon de flou",           min: 0, max: 8,   def: 1 },
        { key: "tintAlpha",           label: "Teinte du verre",         min: 0, max: 0.9, def: -1 },
        { key: "surfaceAlpha",        label: "Opacité en flou Hyprland", min: 0, max: 1,  def: -1 }
    ]

    readonly property var glassElements: [
        { id: "*",           name: "Tous" },
        { id: "dock",        name: "Dock" },
        { id: "spotlight",   name: "Spotlight" },
        { id: "cc",          name: "Centre de contrôle" },
        { id: "notifcenter", name: "Notifications" },
        { id: "notifpopup",  name: "Bannières" },
        { id: "osd",         name: "OSD et alertes" },
        { id: "ai",          name: "Assistant IA" },
        { id: "menus",       name: "Menus" }
    ]

    function glassDefault(key) {
        if (key === "tintAlpha")
            return root.isLight ? ShellConfig.options.appearance.glassTintLight : (root.isDark ? ShellConfig.options.appearance.glassTintDark : 0)
        if (key === "surfaceAlpha")
            return ShellConfig.options.appearance.blurSurfaceAlpha
        for (var i = 0; i < root.elementSpecs.length; i++)
            if (root.elementSpecs[i].key === key)
                return root.elementSpecs[i].def
        return 0
    }

    function glassValue(element, key) {
        var all = ShellConfig.options.appearance.glassElements
        if (all) {
            if (element && all[element] && all[element][key] !== undefined)
                return all[element][key]
            if (all["*"] && all["*"][key] !== undefined)
                return all["*"][key]
        }
        return root.glassDefault(key)
    }

    function glassOverridden(element, key) {
        var all = ShellConfig.options.appearance.glassElements
        return !!(all && all[element] && all[element][key] !== undefined)
    }

    function setGlassParam(element, key, value) {
        var all = JSON.parse(JSON.stringify(ShellConfig.options.appearance.glassElements || {}))
        if (!all[element])
            all[element] = {}
        all[element][key] = value
        ShellConfig.options.appearance.glassElements = all
    }

    function resetGlassElement(element) {
        var all = JSON.parse(JSON.stringify(ShellConfig.options.appearance.glassElements || {}))
        delete all[element]
        ShellConfig.options.appearance.glassElements = all
    }

    function glassTintFor(element) {
        var a = root.glassValue(element, "tintAlpha")
        return root.isLight ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a)
    }

    function surfaceFor(element) {
        var a = root.glassValue(element, "surfaceAlpha")
        return root.isLight ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a)
    }

    readonly property bool isGlass: root.mode === "glass"
    readonly property bool isLight: root.mode === "light"
    readonly property bool isDark:  root.mode === "dark"

    function setMode(m) {
        ShellConfig.options.appearance.mode = m
    }

    function setBlurPreset(id) {
        ShellConfig.options.appearance.blurParams = ({})
        ShellConfig.options.appearance.blurPreset = id
    }

    function setBlurParam(key, v) {
        var p = Object.assign({}, ShellConfig.options.appearance.blurParams)
        p[key] = v
        ShellConfig.options.appearance.blurParams = p
    }

    function resetBlurParams() {
        ShellConfig.options.appearance.blurParams = ({})
    }

    function effective() {
        var flat = {}
        var i
        for (i = 0; i < root.blurGeneral.length; i++)
            flat[root.blurGeneral[i].key] = root.blurGeneral[i].def
        var list = root.variantSpecList
        for (i = 0; i < list.length; i++)
            flat[list[i].key] = list[i].def
        if (root.blurPresetData) {
            for (var k in root.blurPresetData.overrides)
                flat[k] = root.blurPresetData.overrides[k]
        }
        var p = root.blurParams
        for (var key in p) {
            if (flat.hasOwnProperty(key))
                flat[key] = p[key]
        }
        return flat
    }

    function blurValue(key) {
        return root.effective()[key]
    }

    function setAccent(hex) {
        ShellConfig.options.appearance.accentOverride = hex
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
            shadow:         "#40000000"
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
            shadow:         Qt.rgba(0, 0, 0, 0.18)
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
            shadow:         Qt.rgba(0, 0, 0, 0.45)
        }
    })

    readonly property var current: root.palettes[root.mode]

    readonly property color textPrimary:    root.current.textPrimary
    readonly property color textSecondary:  root.current.textSecondary
    readonly property color textTertiary:   root.current.textTertiary
    readonly property color textQuaternary: root.current.textQuaternary
    readonly property color separator:      root.current.separator
    readonly property color accent:         ShellConfig.options.appearance.accentOverride !== "" ? ShellConfig.options.appearance.accentOverride : root.current.accent
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
    readonly property color glassTint:      root.isLight ? Qt.rgba(1, 1, 1, ShellConfig.options.appearance.glassTintLight) : (root.isDark ? Qt.rgba(0, 0, 0, ShellConfig.options.appearance.glassTintDark) : "transparent")
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

    function useGlass(item) {
        return !root.compositorBlur || !root.themed(item)
    }

    function pick(lightValue, legacy) {
        return root.isLight ? lightValue : legacy
    }

    function popup(legacy) {
        if (root.compositorBlur) {
            return root.surfaceFor("spotlight")
        }
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

    function _nest(flat) {
        var out = {}
        for (var key in flat) {
            var parts = key.split(".")
            var cur = out
            for (var i = 0; i < parts.length - 1; i++) {
                if (cur[parts[i]] === undefined)
                    cur[parts[i]] = {}
                cur = cur[parts[i]]
            }
            cur[parts[parts.length - 1]] = flat[key]
        }
        return out
    }

    function _luaTable(o) {
        var parts = []
        for (var k in o) {
            var v = o[k]
            parts.push(k + " = " + (typeof v === "object" ? root._luaTable(v) : root._luaValue(v)))
        }
        return "{ " + parts.join(", ") + " }"
    }

    readonly property var blurLayerNamespaces: ["dock", "globalmenu", "applemenu", "notifcenter", "notifpopup", "ai", "spotlight", "cc", "statusmenu", "about", "reload-popup", "osd", "btbattery", "batteryosd"]

    function layerIgnoreEffective() {
        var lowest = root.glassValue("*", "surfaceAlpha")
        for (var i = 0; i < root.glassElements.length; i++)
            lowest = Math.min(lowest, root.glassValue(root.glassElements[i].id, "surfaceAlpha"))
        return Math.max(0, Math.min(ShellConfig.options.appearance.layerIgnoreAlpha, lowest * 0.5))
    }

    function blurPayload() {
        if (root.blurPresetData === null)
            return ""
        var flat = root.effective()
        flat.enabled = true
        flat.variant = root.blurPresetData.variant
        var a = root.blurWindowOpacity.toFixed(2)
        var b = root.blurWindowOpacityInactive.toFixed(2)
        var lua = "hl.config({ decoration = { active_opacity = " + a + ", inactive_opacity = " + b + ", blur = " + root._luaTable(root._nest(flat)) + " } })\n"
            + "pcall(function() if _G.lickintosh_rule then _G.lickintosh_rule:set_enabled(false) end end)\n"
            + "_G.lickintosh_rule = hl.window_rule({ name = \"lickintosh-blur-@TS@\", match = { class = \".*\" }, opacity = \"" + a + " override " + b + " override 1.0 override\" })\n"
            + "pcall(function() for _, r in ipairs(_G.lickintosh_layers or {}) do r:set_enabled(false) end end)\n"
            + "_G.lickintosh_layers = {}\n"
        if (ShellConfig.options.appearance.blurLayers) {
            var popups = ShellConfig.options.appearance.blurLayerPopups ? "true" : "false"
            var ignore = root.layerIgnoreEffective().toFixed(2)
            for (var n = 0; n < root.blurLayerNamespaces.length; n++) {
                var ns = root.blurLayerNamespaces[n]
                lua += "table.insert(_G.lickintosh_layers, hl.layer_rule({ name = \"lickintosh-layer-" + ns + "-@TS@\", match = { namespace = \"quickshell:" + ns + "\" }, blur = true, blur_popups = " + popups + ", ignore_alpha = " + ignore + " }))\n"
            }
        }
        return lua
    }

    readonly property string blurSignature: root.compositorBlur ? root.blurPayload() : ""

    function sync() {
        if (!root.applyToCompositor)
            return
        if (root.compositorBlur && root.blurPresetData !== null) {
            root._run(["hyprctl", "eval", root.blurPayload().split("@TS@").join(String(Date.now()))])
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
                    ShellConfig.options.appearance.blurStatus = out
                    console.warn("Theme: hyprctl a répondu : " + out)
                } else {
                    root.lastError = ""
                    ShellConfig.options.appearance.blurStatus = out === "ok" ? "ok" : ""
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var err = text.trim()
                if (err.length > 0) {
                    root.lastError = err
                    ShellConfig.options.appearance.blurStatus = err
                    console.warn("Theme: hyprctl erreur : " + err)
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
    onBlurSignatureChanged: if (ShellConfig.ready) syncTimer.restart()

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
