pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string monitorsLuaPath: "$HOME/.config/hypr/hyprlua/monitors.lua"

    property var monitors: []
    property bool loading: false

    readonly property int activeCount: {
        var n = 0
        for (var i = 0; i < root.monitors.length; i++) {
            if (!root.monitors[i].disabled) n++
        }
        return n
    }

    function refresh() {
        root.loading = true
        _listProc.running = true
    }

    Process {
        id: _listProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text)
                } catch (e) {
                    root.monitors = []
                }
                root.loading = false
            }
        }
    }

    function _quoteLua(str) {
        return "\"" + String(str).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\""
    }

    function _monitorSpecToLua(m) {
        var fields = []
        fields.push("output = " + root._quoteLua(m.output))

        if (m.disabled) {
            fields.push("disabled = true")
            return "hl.monitor({ " + fields.join(", ") + " })"
        }

        fields.push("mode = " + root._quoteLua(m.mode))
        fields.push("position = " + root._quoteLua(m.position))
        fields.push("scale = " + (m.scale === "auto" ? root._quoteLua("auto") : m.scale))

        fields.push("vrr = " + (m.vrr ? 1 : 0))
        fields.push("bitdepth = " + (m.bitdepth === 10 ? 10 : 8))

        if (m.transform !== undefined && m.transform !== 0) {
            fields.push("transform = " + m.transform)
        }
        if (m.cm && m.cm !== "auto") {
            fields.push("cm = " + root._quoteLua(m.cm))
        }
        if (m.sdrbrightness !== undefined && m.sdrbrightness !== 1) {
            fields.push("sdrbrightness = " + m.sdrbrightness)
        }
        if (m.sdrsaturation !== undefined && m.sdrsaturation !== 1) {
            fields.push("sdrsaturation = " + m.sdrsaturation)
        }
        if (m.mirror) {
            fields.push("mirror = " + root._quoteLua(m.mirror))
        }

        return "hl.monitor({ " + fields.join(", ") + " })"
    }

    function _applyLiveEval(m) {
        var luaCall = root._monitorSpecToLua(m)
        _applyProc.command = ["hyprctl", "eval", luaCall]
        _applyProc.running = true
    }

    Process {
        id: _applyProc
        onExited: function(code) {
            if (code === 0) root.refresh()
        }
    }

    function applyAndPersist(monitorSpec) {
        var list = root.monitors.slice()
        var found = false
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === monitorSpec.output) {
                list[i] = Object.assign({}, list[i], monitorSpec)
                found = true
                break
            }
        }
        if (!found) list.push(monitorSpec)
        root.monitors = list

        root._applyLiveEval(monitorSpec)
        root._writeLuaFile()
    }

    property var _pendingSpecs: []

    function _writeLuaFile() {
        var lines = []
        for (var i = 0; i < root.monitors.length; i++) {
            var m = root.monitors[i]
            var spec = {
                output: m.name || m.output,
                mode: m.width && m.height ? (m.width + "x" + m.height + "@" + (m.refreshRate ? m.refreshRate.toFixed(2) : "60")) : "preferred",
                position: (m.x !== undefined && m.y !== undefined) ? (m.x + "x" + m.y) : "auto",
                scale: m.scale || 1,
                transform: m.transform || 0,
                vrr: m.vrr ? 1 : 0,
                bitdepth: m.bitdepth === 10 ? 10 : 8,
                cm: m.cm || m.colorManagementPreset,
                sdrbrightness: m.sdrbrightness !== undefined ? m.sdrbrightness : m.sdrBrightness,
                sdrsaturation: m.sdrsaturation !== undefined ? m.sdrsaturation : m.sdrSaturation,
                mirror: m.mirror || m.mirrorOf,
                disabled: m.disabled || false
            }
            lines.push(root._monitorSpecToLua(spec))
        }
        var content = "---@module 'hl'\n\n" + lines.join("\n") + "\n"
        _luaFileView.setText(content)
    }

    FileView {
        id: _luaFileView
        path: root.monitorsLuaPath
    }

    function toggleDisabled(output, disabled) {
        root.applyAndPersist({ output: output, disabled: disabled })
    }

    Component.onCompleted: root.refresh()
}
