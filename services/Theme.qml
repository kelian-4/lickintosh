pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/*
    Thème global du shell : mode d'apparence courant + palette.

    Mode (persisté dans ShellConfig.options.appearance.mode) :
        "glass"          Liquid Glass (rendu actuel, par défaut)
        "light"          thème clair Tahoe
        "dark"           thème sombre Tahoe
        "blur:<id>"      préréglage de flou fourni par Hyprland (voir blurPresets)

    Usage :
        import qs.services
        color: Theme.textPrimary
        Theme.setMode("dark")

    ---------------------------------------------------------------------
    SOURCES DES VALEURS (à relire avant de les figer)
    ---------------------------------------------------------------------
    [HIG]   Apple Human Interface Guidelines > Color > Specifications
            https://developer.apple.com/design/human-interface-guidelines/color
            (mise à jour juin 2025 / déc. 2025). Bleu système :
            clair (0,136,255) = #0088FF, sombre (0,145,255) = #0091FF.
            Apple précise que ces valeurs "peuvent changer d'une version
            à l'autre" : elles servent de référence, pas de vérité absolue.
    [MESURE] Sortie de NSColor sur macOS 11.2.3 et 12.0.1 (valeurs
            identiques entre les deux) :
            https://gist.github.com/andrejilderda/8677c565cddc969e6aae7df48622d47c
            labelColor 0.847 / secondaryLabelColor 0.498 (clair) et 0.549
            (sombre) / tertiaryLabelColor 0.259 (clair) et 0.247 (sombre) /
            quaternaryLabelColor et separatorColor 0.098, noir en clair et
            blanc en sombre ; windowBackgroundColor #ECECEC (clair) et
            #323232 (sombre) ; controlBackgroundColor #FFFFFF / #1E1E1E.
            ATTENTION : mesuré sur Big Sur / Monterey, pas sur Tahoe.
    [LEGACY] Valeurs d'origine du shell (rendu verre), conservées telles
            quelles pour que le mode "glass" ne change pas d'un pixel.
    [DERIVE] Choisi ici, sans source Apple : à comparer avec tes captures
            de référence Tahoe.
    ---------------------------------------------------------------------

    POINT DE BRANCHEMENT POUR LES LAYER RULES (autre agent) :
        Theme.compositorBlur  true quand le mode est "blur:<id>"
        Theme.blurPreset      id du préréglage ("" sinon)
        Theme.blurPresetData  table complète du préréglage
    Les layer rules (blur, ignore_alpha sur les namespaces "quickshell:*")
    ne sont PAS écrites ici. Elles doivent se réappliquer sur l'événement
    Hyprland "configreloaded" (un reload remet les règles à zéro).
*/
Singleton {
    id: root

    reloadableId: "theme"

    // ------------------------------------------------------------------
    // Préréglages de flou Hyprland 0.57
    // Chaque clé est vérifiée dans hyprland-wiki (configuring/core/
    // config-options.md > Blur). `acrylic` est volontairement absent :
    // essayé puis écarté. LISTE PROVISOIRE : à valider avec l'utilisateur.
    // ------------------------------------------------------------------
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

    // ------------------------------------------------------------------
    // Mode courant
    // ------------------------------------------------------------------
    readonly property string rawMode: ShellConfig.options.appearance.mode

    readonly property string mode: {
        var m = root.rawMode
        if (m === "glass" || m === "light" || m === "dark")
            return m
        if (m.indexOf("blur:") === 0 && root.presetById(m.substring(5)) !== null)
            return m
        return "glass"
    }

    readonly property bool isGlass: root.mode === "glass"
    readonly property bool isLight: root.mode === "light"
    readonly property bool isDark:  root.mode === "dark"
    readonly property bool isBlur:  root.mode.indexOf("blur:") === 0

    // Rendu LiquidGlass (shaders) actif seulement en mode "glass".
    readonly property bool glassShaders: root.isGlass
    // Encre sombre sur fond clair (seul le mode "light").
    readonly property bool lightScheme: root.isLight

    readonly property bool compositorBlur: root.isBlur
    readonly property string blurPreset: root.isBlur ? root.mode.substring(5) : ""
    readonly property var blurPresetData: root.isBlur ? root.presetById(root.blurPreset) : null

    function setMode(m) {
        ShellConfig.options.appearance.mode = m
    }

    // ------------------------------------------------------------------
    // Palettes
    // ------------------------------------------------------------------
    readonly property var palettes: ({
        // [LEGACY] rendu verre actuel.
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
            bar:            "transparent"
        },
        // Flou compositeur : mêmes encres que le verre, fonds translucides
        // pour laisser voir le flou de Hyprland. [DERIVE] pour les alphas.
        blur: {
            textPrimary:    "#ffffff",
            textSecondary:  "#a0ffffff",
            textTertiary:   "#80ffffff",
            textQuaternary: "#50ffffff",
            separator:      "#18ffffff",
            accent:         "#1c7aff",
            onAccent:       "#ffffff",
            window:         "#990d0d0d",
            panel:          "#40161616",
            panelRim:       "#20ffffff",
            card:           "#28000000",
            cardRim:        "#20ffffff",
            fillHover:      "#10ffffff",
            fillRow:        "#0cffffff",
            fillSubtle:     "#12ffffff",
            fillControl:    "#18ffffff",
            controlRim:     "#14ffffff",
            controlTrack:   "#30000000",
            scrollbar:      "#50ffffff",
            shadow:         "#40000000",
            bar:            "#59000000"
        },
        // Thème clair. Encres : [MESURE] labelColor (alpha 0.847), secondary
        // 0.498, tertiary 0.259, quaternary/séparateur 0.098 sur noir.
        // Accent [HIG] #0088FF. Fenêtre [MESURE] #ECECEC, carte [MESURE]
        // controlBackgroundColor #FFFFFF. Le reste est [DERIVE].
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
            bar:            "#e6f4f4f4"
        },
        // Thème sombre. Encres : [MESURE] labelColor (0.847), secondary
        // 0.549, tertiary 0.247, quaternary/séparateur 0.098 sur blanc.
        // Accent [HIG] #0091FF. Fenêtre [MESURE] #323232. Le reste est
        // [DERIVE] (la carte est un voile blanc à 6 % sur la fenêtre).
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
            bar:            "#e6262626"
        }
    })

    readonly property string paletteKey: root.isBlur ? "blur" : root.mode
    readonly property var current: root.palettes[root.paletteKey]

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
    readonly property color bar:            root.current.bar

    // ------------------------------------------------------------------
    // Portée thémée.
    // Une surface migrée déclare `readonly property bool themed: true` sur
    // sa racine. Tout CFText / CFVI / BoxGlass descendant suit alors le mode
    // courant. Les surfaces non migrées (sans marqueur) gardent exactement
    // leur rendu verre actuel, quel que soit le mode : on migre surface par
    // surface en ajoutant ce marqueur, sans casser les autres.
    // ------------------------------------------------------------------
    function themed(item) {
        var p = item
        while (p) {
            if (p.themed === true)
                return true
            p = p.parent
        }
        return false
    }

    // Encres par défaut d'un CFText / CFVI.
    function ink(item, secondary) {
        if (root.themed(item))
            return secondary ? root.textSecondary : root.textPrimary
        return secondary ? "#a0ffffff" : "#ffffff"
    }

    // BoxGlass : shader LiquidGlass ? (mode glass, ou surface non migrée)
    function useGlass(item) {
        return root.glassShaders || !root.themed(item)
    }
    function boxColor(item, c) {
        return root.themed(item) ? root.adaptBox(c) : c
    }
    function boxRim(item, c) {
        return root.themed(item) ? root.adaptRim(c) : c
    }

    // Luminance perceptuelle approchée d'une couleur (0 = noir, 1 = blanc).
    function luma(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }

    // Repli pour un composant pas encore migré qui passe une teinte codée
    // en dur à BoxGlass : en mode "glass" la teinte est gardée telle quelle,
    // sinon elle est ré-exprimée pour le mode courant.
    //   - fond substantiel (alpha >= 0.45) -> matière de panneau du thème
    //   - voile blanc (surbrillance) en mode clair -> voile noir équivalent
    function adaptBox(c) {
        if (root.isGlass)
            return c
        if (c.a >= 0.45)
            return root.panel
        if (root.isLight && root.luma(c) > 0.5)
            return Qt.rgba(0, 0, 0, c.a * 0.6)
        return c
    }

    // Même principe pour l'éclat de bord (rim) de BoxGlass.
    function adaptRim(c) {
        if (root.isGlass || root.isBlur || root.isDark)
            return c
        return Qt.rgba(0, 0, 0, c.a * 0.5)
    }

    // ------------------------------------------------------------------
    // Application du préréglage de flou à Hyprland (à chaud)
    //   hyprctl eval 'hl.config({ decoration = { blur = { ... } } })'
    //   (syntaxe : wiki > Using hyprctl > eval, Config options > Syntax)
    // Un `reload` remet les options aux valeurs du fichier de config :
    //   - on réapplique donc sur l'événement "configreloaded"
    //   - on sort d'un préréglage avec `hyprctl reload`
    // ------------------------------------------------------------------
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
        return "hl.config({ decoration = { blur = { " + parts.join(", ") + " } } })"
    }

    // Une seule instance doit parler à Hyprland : le shell principal. L'app
    // Réglages (instance séparée) met ceci à false au démarrage.
    property bool applyToCompositor: true

    function sync() {
        if (!root.applyToCompositor)
            return
        if (root.isBlur && root.blurPresetData !== null) {
            root._run(["hyprctl", "eval", root.blurLua(root.blurPresetData)])
            ShellConfig.options.appearance.blurApplied = true
        } else if (ShellConfig.options.appearance.blurApplied) {
            ShellConfig.options.appearance.blurApplied = false
            root._run(["hyprctl", "reload"])
        }
    }

    property string lastError: ""

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

    Timer {
        id: syncTimer
        interval: 60
        onTriggered: root.sync()
    }

    // Réapplique au changement de mode, une fois la configuration chargée.
    onModeChanged: if (ShellConfig.ready) syncTimer.restart()

    Connections {
        target: ShellConfig
        function onReadyChanged() {
            if (ShellConfig.ready)
                syncTimer.restart()
        }
    }

    // Un rechargement de la config Hyprland efface les options appliquées à
    // chaud : on les remet si un préréglage est actif.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.isBlur)
                syncTimer.restart()
        }
    }
}
