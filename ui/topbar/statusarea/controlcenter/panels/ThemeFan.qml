pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

Item {
    id: fan

    property bool open: false
    property real originX: width / 2
    property real originY: 0

    readonly property real pillW: 270
    readonly property real pillH: 46
    readonly property real gap: 10
    readonly property real slotX: (width - fan.pillW) / 2

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

    readonly property real topY: 28
    readonly property real hyprLabelY: fan.topY + fan.modes.length * (fan.pillH + fan.gap) + 18
    readonly property real hyprY: fan.hyprLabelY + 22

    component Fly: Item {
        id: fly
        property int order: 0
        property int count: 1
        property real targetX: 0
        property real targetY: 0
        property real t: fan.open ? 1 : 0
        Behavior on t {
            SequentialAnimation {
                PauseAnimation { duration: fan.open ? fly.order * 55 : (fly.count - 1 - fly.order) * 25 }
                NumberAnimation {
                    duration: fan.open ? 520 : 260
                    easing.type: fan.open ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.1
                }
            }
        }
        x: (fan.originX - fan.pillW / 2) + (fly.targetX - (fan.originX - fan.pillW / 2)) * fly.t
        y: (fan.originY - fan.pillH / 2) + (fly.targetY - (fan.originY - fan.pillH / 2)) * fly.t
        width: fan.pillW
        height: fan.pillH
        opacity: Math.max(0, Math.min(1, fly.t * 1.8))
        scale: 0.55 + 0.45 * Math.max(0, Math.min(1, fly.t))
        visible: fly.t > 0.002
    }

    Repeater {
        model: fan.modes

        delegate: Fly {
            id: modeFly
            required property var modelData
            required property int index
            order: modeFly.index
            count: fan.modes.length
            targetX: fan.slotX
            targetY: fan.topY + modeFly.index * (fan.pillH + fan.gap)

            ThemePill {
                anchors.fill: parent
                label: I18n.tr(modeFly.modelData.label)
                icon: modeFly.modelData.icon
                picked: Theme.mode === modeFly.modelData.mode
                onActivated: Theme.setMode(modeFly.modelData.mode)
            }
        }
    }

    CFText {
        x: fan.slotX + 6
        y: 6
        text: I18n.tr("Appearance")
        font.pixelSize: 13
        font.weight: Font.Bold
        opacity: fan.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }

    CFText {
        x: fan.slotX + 6
        y: fan.hyprLabelY
        text: I18n.tr("Thème de flou Hyprland")
        font.pixelSize: 13
        font.weight: Font.Bold
        opacity: fan.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 320 } }
    }

    Repeater {
        model: fan.hyprItems

        delegate: Fly {
            id: hyprFly
            required property var modelData
            required property int index
            order: hyprFly.index + 3
            count: fan.hyprItems.length + 3
            targetX: fan.slotX
            targetY: fan.hyprY + hyprFly.index * (fan.pillH + fan.gap)

            ThemePill {
                anchors.fill: parent
                label: hyprFly.modelData.label
                picked: hyprFly.modelData.id === "" ? !Theme.compositorBlur : Theme.blurPreset === hyprFly.modelData.id
                onActivated: Theme.setBlurPreset(hyprFly.modelData.id)
            }
        }
    }
}
