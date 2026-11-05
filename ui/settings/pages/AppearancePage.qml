pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets

ContentPage {
    id: root

    property string glassTarget: "*"

    readonly property var accents: [
        { name: "Bleu",     hex: "#0088ff" },
        { name: "Violet",   hex: "#cb30e0" },
        { name: "Rose",     hex: "#ff2d55" },
        { name: "Rouge",    hex: "#ff383c" },
        { name: "Orange",   hex: "#ff8d28" },
        { name: "Jaune",    hex: "#ffcc00" },
        { name: "Vert",     hex: "#34c759" },
        { name: "Graphite", hex: "#8e8e93" }
    ]

    component StyleTile: Item {
        id: tile

        required property string label
        required property bool selected
        property string palette: "glass"
        property color windowTint: tile.pal.window
        property color sidebarTint: tile.pal.panel
        signal picked()

        readonly property var pal: Theme.palettes[tile.palette]

        implicitWidth: 132
        implicitHeight: 84 + 8 + _label.implicitHeight

        Rectangle {
            id: _preview
            width: 132
            height: 84
            radius: 10
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a6fd8" }
                GradientStop { position: 0.55; color: "#8a5bd0" }
                GradientStop { position: 1.0; color: "#e0728a" }
            }

            Rectangle {
                x: 10
                y: 10
                width: 84
                height: 52
                radius: 6
                color: tile.windowTint
                border.width: 1
                border.color: tile.pal.panelRim
                clip: true

                Rectangle {
                    width: 22
                    height: parent.height
                    color: tile.sidebarTint
                }

                Rectangle { x: 28; y: 8;  width: 40; height: 4; radius: 2; color: tile.pal.textSecondary }
                Rectangle { x: 28; y: 18; width: 52; height: 3; radius: 1.5; color: tile.pal.textTertiary }
                Rectangle { x: 28; y: 25; width: 46; height: 3; radius: 1.5; color: tile.pal.textTertiary }
                Rectangle { x: 28; y: 36; width: 20; height: 7; radius: 3.5; color: tile.pal.accent }
            }

            Rectangle {
                width: 38
                height: 5
                radius: 2.5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                color: "#66ffffff"
            }
        }

        Rectangle {
            anchors.fill: _preview
            anchors.margins: -4
            radius: 14
            color: "transparent"
            border.width: 3
            border.color: Theme.accent
            visible: tile.selected
        }

        CFText {
            id: _label
            anchors.top: _preview.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: _preview.horizontalCenter
            text: tile.label
            font.pixelSize: 12
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
            gray: !tile.selected
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.picked()
        }
    }

    component ParamSlider: ConfigSlider {
        id: ps

        property real source: 0
        signal committed(real v)

        Binding {
            target: ps
            property: "value"
            value: ps.source
        }

        onMoved: function(v) { ps.committed(v) }
    }

    component ParamSwitch: ConfigSwitch {
        id: pw

        property bool source: false
        signal committed(bool v)

        Binding {
            target: pw
            property: "checked"
            value: pw.source
        }

        onToggled: function(v) { pw.committed(v) }
    }

    component BlurParam: Loader {
        id: param

        required property var spec

        Layout.fillWidth: true
        sourceComponent: param.spec.type === "bool" ? _boolComp : _numComp

        Component {
            id: _numComp

            ParamSlider {
                text: param.spec.label
                from: param.spec.min
                to: param.spec.max
                decimals: param.spec.type === "int" ? 0 : (param.spec.max <= 2 ? 3 : 1)
                source: Number(Theme.blurValue(param.spec.key))
                onCommitted: function(v) {
                    Theme.setBlurParam(param.spec.key, param.spec.type === "int" ? Math.round(v) : v)
                }
            }
        }

        Component {
            id: _boolComp

            ParamSwitch {
                text: param.spec.label
                source: Theme.blurValue(param.spec.key) === true
                onCommitted: function(v) { Theme.setBlurParam(param.spec.key, v) }
            }
        }
    }

    ContentSection {
        title: "Style de l'interface"

        Flow {
            Layout.fillWidth: true
            spacing: 20

            StyleTile {
                label: "Liquid Glass"
                selected: Theme.mode === "glass"
                palette: "glass"
                windowTint: "#40ffffff"
                sidebarTint: "#30ffffff"
                onPicked: Theme.setMode("glass")
            }

            StyleTile {
                label: "Clair"
                selected: Theme.mode === "light"
                palette: "light"
                windowTint: "#99ffffff"
                sidebarTint: "#66ffffff"
                onPicked: Theme.setMode("light")
            }

            StyleTile {
                label: "Sombre"
                selected: Theme.mode === "dark"
                palette: "dark"
                windowTint: "#99000000"
                sidebarTint: "#66000000"
                onPicked: Theme.setMode("dark")
            }
        }
    }

    ContentSection {
        title: "Personnalisation du style"

        ParamSlider {
            text: "Intensité de la teinte du verre"
            from: 0
            to: 0.9
            decimals: 2
            source: Theme.isLight ? ShellConfig.options.appearance.glassTintLight : ShellConfig.options.appearance.glassTintDark
            onCommitted: function(v) {
                if (Theme.isLight)
                    ShellConfig.options.appearance.glassTintLight = v
                else
                    ShellConfig.options.appearance.glassTintDark = v
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Couleur d'accentuation"
                font.pixelSize: 14
            }

            Flow {
                width: parent.width
                spacing: 10

                Rectangle {
                    width: 54
                    height: 26
                    radius: 13
                    color: Theme.fillControl
                    border.width: ShellConfig.options.appearance.accentOverride === "" ? 2 : 0
                    border.color: Theme.accent

                    CFText {
                        anchors.centerIn: parent
                        text: "Défaut"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.setAccent("")
                    }
                }

                Repeater {
                    model: root.accents

                    Rectangle {
                        id: swatch

                        required property var modelData

                        width: 26
                        height: 26
                        radius: 13
                        color: swatch.modelData.hex
                        border.width: ShellConfig.options.appearance.accentOverride === swatch.modelData.hex ? 3 : 0
                        border.color: Theme.textPrimary

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setAccent(swatch.modelData.hex)
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        title: "Liquid Glass par élément"

        CFText {
            Layout.fillWidth: true
            text: "Chaque réglage s'applique à l'élément choisi. « Tous » sert de base : un élément sans réglage propre en hérite."
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: Theme.glassElements

                Rectangle {
                    id: chip

                    required property var modelData

                    width: _chipText.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: root.glassTarget === chip.modelData.id ? Theme.accent : Theme.fillControl

                    CFText {
                        id: _chipText
                        anchors.centerIn: parent
                        text: chip.modelData.name
                        font.pixelSize: 12
                        color: root.glassTarget === chip.modelData.id ? Theme.onAccent : Theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.glassTarget = chip.modelData.id
                    }
                }
            }
        }

        Repeater {
            model: Theme.elementSpecs

            ParamSlider {
                id: gs

                required property var modelData

                Layout.fillWidth: true
                text: gs.modelData.label
                from: gs.modelData.min
                to: gs.modelData.max
                decimals: gs.modelData.max <= 2 ? 2 : 1
                source: Theme.glassValue(root.glassTarget, gs.modelData.key)
                onCommitted: function(v) { Theme.setGlassParam(root.glassTarget, gs.modelData.key, v) }
            }
        }

        Rectangle {
            Layout.preferredWidth: 190
            Layout.preferredHeight: 32
            radius: 16
            color: Theme.accent

            CFText {
                anchors.centerIn: parent
                text: "Réinitialiser cet élément"
                font.pixelSize: 13
                color: Theme.onAccent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.resetGlassElement(root.glassTarget)
            }
        }
    }

    ContentSection {
        title: "Thème de flou Hyprland"

        CFText {
            Layout.fillWidth: true
            text: "Applique le flou choisi à toutes les fenêtres et aux couches Quickshell, quel que soit le style de l'interface."
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: 20

            StyleTile {
                label: "Aucun"
                selected: !Theme.compositorBlur
                palette: "glass"
                windowTint: "#40ffffff"
                sidebarTint: "#30ffffff"
                onPicked: Theme.setBlurPreset("")
            }

            Repeater {
                model: Theme.blurPresets

                StyleTile {
                    id: presetTile

                    required property var modelData

                    label: presetTile.modelData.name
                    selected: Theme.blurPreset === presetTile.modelData.id
                    palette: "glass"
                    windowTint: "#a0101010"
                    sidebarTint: "#50101010"
                    onPicked: Theme.setBlurPreset(presetTile.modelData.id)
                }
            }
        }

        CFText {
            Layout.fillWidth: true
            visible: Theme.compositorBlur && Theme.blurPresetData !== null
            text: Theme.blurPresetData ? Theme.blurPresetData.description : ""
            font.pixelSize: 12
            gray: true
            wrapMode: Text.WordWrap
        }

        CFText {
            Layout.fillWidth: true
            visible: Theme.lastError.length > 0
            text: "Hyprland a refusé le préréglage : " + Theme.lastError
            font.pixelSize: 12
            color: "#ff453a"
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: "Fenêtres et couches"

        ParamSlider {
            text: "Opacité des fenêtres actives"
            from: 0.3
            to: 1.0
            decimals: 2
            source: Theme.blurWindowOpacity
            onCommitted: function(v) { ShellConfig.options.appearance.blurWindowOpacity = v }
        }

        ParamSlider {
            text: "Opacité des fenêtres inactives"
            from: 0.3
            to: 1.0
            decimals: 2
            source: Theme.blurWindowOpacityInactive
            onCommitted: function(v) { ShellConfig.options.appearance.blurWindowOpacityInactive = v }
        }

        ParamSwitch {
            text: "Appliquer le flou aux couches Quickshell"
            description: "Barre, dock, panneaux, Spotlight, notifications et OSD."
            source: ShellConfig.options.appearance.blurLayers
            onCommitted: function(v) { ShellConfig.options.appearance.blurLayers = v }
        }

        ParamSwitch {
            text: "Flou des menus des couches"
            source: ShellConfig.options.appearance.blurLayerPopups
            onCommitted: function(v) { ShellConfig.options.appearance.blurLayerPopups = v }
        }

        ParamSlider {
            text: "Seuil de transparence des couches"
            from: 0
            to: 1
            decimals: 2
            source: ShellConfig.options.appearance.layerIgnoreAlpha
            onCommitted: function(v) { ShellConfig.options.appearance.layerIgnoreAlpha = v }
        }

        ParamSlider {
            text: "Opacité des surfaces du shell"
            from: 0
            to: 1
            decimals: 2
            source: ShellConfig.options.appearance.blurSurfaceAlpha
            onCommitted: function(v) { ShellConfig.options.appearance.blurSurfaceAlpha = v }
        }
    }

    ContentSection {
        title: "Réglages du flou"

        Repeater {
            model: Theme.blurGeneral

            BlurParam {
                required property var modelData
                spec: modelData
            }
        }
    }

    ContentSection {
        title: Theme.blurPresetData ? "Réglages " + Theme.blurPresetData.name : ""
        visible: Theme.variantSpecList.length > 0

        Repeater {
            model: Theme.variantSpecList

            BlurParam {
                required property var modelData
                spec: modelData
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 150
        Layout.preferredHeight: 32
        radius: 16
        color: Theme.accent

        CFText {
            anchors.centerIn: parent
            text: "Réinitialiser le flou"
            font.pixelSize: 13
            color: Theme.onAccent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Theme.resetBlurParams()
        }
    }
}
