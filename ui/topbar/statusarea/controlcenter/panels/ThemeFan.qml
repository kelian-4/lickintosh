pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

Item {
    id: fan

    property bool open: false
    property Item glassBackdrop: null

    readonly property real pillW: 270
    readonly property real pillH: 46
    readonly property real gap: 10
    readonly property real slotX: (width - fan.pillW) / 2
    readonly property real labelH: 18

    readonly property var modes: [
        { mode: "glass", label: "Liquid Glass", icon: "glass" },
        { mode: "light", label: "Clair", icon: "light" },
        { mode: "dark", label: "Sombre", icon: "dark" }
    ]

    readonly property var hyprItems: {
        var l = [{ id: "", label: I18n.tr("Aucun") }]
        var p = Theme.blurPresets
        for (var i = 0; i < p.length; i++)
            l.push({ id: p[i].id, label: I18n.tr(p[i].name) })
        return l
    }

    readonly property int total: 2 + fan.modes.length + fan.hyprItems.length

    readonly property real labelAY: 6
    readonly property real modesY: fan.labelAY + fan.labelH + 8
    readonly property real labelBY: fan.modesY + fan.modes.length * (fan.pillH + fan.gap) + 8
    readonly property real hyprY: fan.labelBY + fan.labelH + 8

    component Drop: Item {
        id: drop
        property int order: 0
        property real targetY: 0
        property real t: fan.open ? 1 : 0
        Behavior on t {
            SequentialAnimation {
                PauseAnimation { duration: fan.open ? drop.order * 50 : (fan.total - 1 - drop.order) * 18 }
                NumberAnimation {
                    duration: fan.open ? 460 : 220
                    easing.type: fan.open ? Easing.OutCubic : Easing.InCubic
                }
            }
        }
        x: fan.slotX
        y: drop.targetY - 34 * (1 - drop.t)
        width: fan.pillW
        opacity: Math.max(0, Math.min(1, drop.t * 1.6))
        scale: 0.94 + 0.06 * Math.max(0, Math.min(1, drop.t))
        visible: drop.t > 0.002
    }

    Drop {
        order: 0
        targetY: fan.labelAY
        height: fan.labelH

        CFText {
            x: 6
            text: I18n.tr("Appearance")
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.ink(parent, true)
        }
    }

    Repeater {
        model: fan.modes

        delegate: Drop {
            id: modeDrop
            required property var modelData
            required property int index
            order: 1 + modeDrop.index
            targetY: fan.modesY + modeDrop.index * (fan.pillH + fan.gap)
            height: fan.pillH

            ThemePill {
                anchors.fill: parent
                glassBackdrop: fan.glassBackdrop
                label: I18n.tr(modeDrop.modelData.label)
                icon: modeDrop.modelData.icon
                picked: Theme.mode === modeDrop.modelData.mode
                onActivated: Theme.setMode(modeDrop.modelData.mode)
            }
        }
    }

    Drop {
        order: 1 + fan.modes.length
        targetY: fan.labelBY
        height: fan.labelH

        CFText {
            x: 6
            text: I18n.tr("Thème de flou Hyprland")
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.ink(parent, true)
        }
    }

    Repeater {
        model: fan.hyprItems

        delegate: Drop {
            id: hyprDrop
            required property var modelData
            required property int index
            order: 2 + fan.modes.length + hyprDrop.index
            targetY: fan.hyprY + hyprDrop.index * (fan.pillH + fan.gap)
            height: fan.pillH

            ThemePill {
                anchors.fill: parent
                glassBackdrop: fan.glassBackdrop
                label: hyprDrop.modelData.label
                picked: hyprDrop.modelData.id === "" ? !Theme.compositorBlur : Theme.blurPreset === hyprDrop.modelData.id
                onActivated: Theme.setBlurPreset(hyprDrop.modelData.id)
            }
        }
    }
}
