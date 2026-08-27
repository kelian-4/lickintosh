pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string provider:    "anthropic"
    property string cloudModel:  "claude-sonnet-5"
    property string ollamaModel: ""
    property string ollamaHost:  "http://localhost:11434"
    property var    ollamaModels: []

    property var keys: ({})
    property bool keyringAvailable: false
    property bool keysLoaded: false

    property var customProviders: []

    property string whisperModel: "base"
    property string whisperLang:  "fr"
    property string whisperModelPath: ""

    property string systemPrompt: ""

    readonly property string keyringSchemeAttr: "quickshell-ai-provider"
    readonly property string keyringLabel: "Quickshell AI panel key"

    function getKey(pid) {
        return root.keys[pid] || ""
    }

    function setKey(pid, val) {
        var k = Object.assign({}, root.keys)
        k[pid] = val
        root.keys = k
        if (root.keyringAvailable) {
            _storeKeyInKeyring(pid, val)
        } else {
            _saveTimer.restart()
        }
    }

    function removeKey(pid) {
        var k = Object.assign({}, root.keys)
        delete k[pid]
        root.keys = k
        if (root.keyringAvailable) {
            _removeKeyFromKeyring(pid)
        } else {
            _saveTimer.restart()
        }
    }

    function set(key, value) {
        root[key] = value
        _saveTimer.restart()
    }

    function addCustomProvider(id, endpoint, format, model) {
        var list = root.customProviders.filter(function(p) { return p.id !== id })
        list.push({ id: id, endpoint: endpoint, format: format, model: model })
        root.customProviders = list
        _saveTimer.restart()
    }

    function removeCustomProvider(id) {
        root.customProviders = root.customProviders.filter(function(p) { return p.id !== id })
        _saveTimer.restart()
    }

    property string _home: ""
    property string _path: _home !== "" ? _home + "/.config/macos-shell/ai.json" : ""

    Process {
        id: _getHome
        command: ["sh", "-c", "echo $HOME"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._home = text.trim()
                _checkKeyring.running = true
            }
        }
    }

    Process {
        id: _checkKeyring
        command: ["sh", "-c", "command -v secret-tool >/dev/null 2>&1 && echo yes || echo no"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.keyringAvailable = text.trim() === "yes"
                _load.running = true
            }
        }
    }

    Process {
        id: _load
        command: ["sh", "-c",
            "mkdir -p \"$(dirname '" + root._path + "')\" && cat '" + root._path + "' 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(text)
                    if (o.provider)         root.provider         = o.provider
                    if (o.cloudModel)       root.cloudModel       = o.cloudModel
                    if (o.ollamaModel)      root.ollamaModel      = o.ollamaModel
                    if (o.ollamaHost)       root.ollamaHost       = o.ollamaHost
                    if (o.customProviders)  root.customProviders  = o.customProviders
                    if (o.whisperModel)     root.whisperModel     = o.whisperModel
                    if (o.whisperLang)      root.whisperLang      = o.whisperLang
                    if (o.systemPrompt !== undefined) root.systemPrompt = o.systemPrompt
                    if (!root.keyringAvailable && o.keys) root.keys = o.keys
                } catch(e) {}

                if (root.keyringAvailable) {
                    _loadKeysFromKeyring()
                } else {
                    root.keysLoaded = true
                }
            }
        }
    }

    function _allProviderIdsForKeyring() {
        var ids = ["anthropic", "openai", "google"]
        for (var i = 0; i < root.customProviders.length; i++) ids.push(root.customProviders[i].id)
        return ids
    }

    function _loadKeysFromKeyring() {
        var ids = root._allProviderIdsForKeyring()
        _keyringLoadQueue = ids.slice()
        _loaded = {}
        _loadNextKeyringEntry()
    }

    property var _keyringLoadQueue: []
    property var _loaded: ({})

    function _loadNextKeyringEntry() {
        if (root._keyringLoadQueue.length === 0) {
            root.keys = root._loaded
            root.keysLoaded = true
            return
        }
        var pid = root._keyringLoadQueue.shift()
        _keyringGet.command = ["secret-tool", "lookup", root.keyringSchemeAttr, pid]
        _keyringGet._pid = pid
        _keyringGet.running = true
    }

    Process {
        id: _keyringGet
        property string _pid: ""
        property bool _settled: false
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (_keyringGet._settled) return
                _keyringGet._settled = true
                var v = text.replace(/\n$/, "")
                if (v !== "") root._loaded[_keyringGet._pid] = v
                root._loadNextKeyringEntry()
            }
        }
        onExited: function(exitCode) {
            if (_keyringGet._settled) return
            _keyringGet._settled = true
            root._loadNextKeyringEntry()
        }
        onRunningChanged: {
            if (running) _keyringGet._settled = false
        }
    }

    function _storeKeyInKeyring(pid, val) {
        var safeVal = val.replace(/'/g, "'\\''")
        var safePid = pid.replace(/'/g, "'\\''")
        var safeLabel = root.keyringLabel.replace(/'/g, "'\\''")
        var cmd = "printf '%s' '" + safeVal + "' | secret-tool store --label='" + safeLabel + "' " + root.keyringSchemeAttr + " '" + safePid + "'"
        var proc = _keyStoreComponent.createObject(root, { _cmd: cmd })
        proc.running = true
    }

    function _removeKeyFromKeyring(pid) {
        var safePid = pid.replace(/'/g, "'\\''")
        var cmd = "secret-tool clear " + root.keyringSchemeAttr + " '" + safePid + "'"
        var proc = _keyStoreComponent.createObject(root, { _cmd: cmd })
        proc.running = true
    }

    property Component _keyStoreComponent: Component {
        Process {
            id: storeProc
            property string _cmd: ""
            command: ["sh", "-c", _cmd]
            running: false
            onExited: function() { storeProc.destroy() }
        }
    }

    function _toBase64(str) {
        var bytes = []
        for (var i = 0; i < str.length; i++) {
            var code = str.charCodeAt(i)
            if (code < 0x80) {
                bytes.push(code)
            } else if (code < 0x800) {
                bytes.push(0xc0 | (code >> 6))
                bytes.push(0x80 | (code & 0x3f))
            } else if (code >= 0xd800 && code <= 0xdbff && i + 1 < str.length) {
                var low = str.charCodeAt(i + 1)
                if (low >= 0xdc00 && low <= 0xdfff) {
                    var cp = 0x10000 + ((code - 0xd800) << 10) + (low - 0xdc00)
                    bytes.push(0xf0 | (cp >> 18))
                    bytes.push(0x80 | ((cp >> 12) & 0x3f))
                    bytes.push(0x80 | ((cp >> 6) & 0x3f))
                    bytes.push(0x80 | (cp & 0x3f))
                    i++
                } else {
                    bytes.push(0xe0 | (code >> 12))
                    bytes.push(0x80 | ((code >> 6) & 0x3f))
                    bytes.push(0x80 | (code & 0x3f))
                }
            } else {
                bytes.push(0xe0 | (code >> 12))
                bytes.push(0x80 | ((code >> 6) & 0x3f))
                bytes.push(0x80 | (code & 0x3f))
            }
        }
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        var out = ""
        for (var j = 0; j < bytes.length; j += 3) {
            var b0 = bytes[j]
            var b1 = j + 1 < bytes.length ? bytes[j + 1] : -1
            var b2 = j + 2 < bytes.length ? bytes[j + 2] : -1
            out += chars.charAt(b0 >> 2)
            out += chars.charAt(((b0 & 3) << 4) | (b1 >= 0 ? (b1 >> 4) : 0))
            out += b1 >= 0 ? chars.charAt(((b1 & 15) << 2) | (b2 >= 0 ? (b2 >> 6) : 0)) : "="
            out += b2 >= 0 ? chars.charAt(b2 & 63) : "="
        }
        return out
    }

    Process {
        id: _save
        command: []
        running: false
    }

    Timer {
        id: _saveTimer
        interval: 800
        repeat:   false
        onTriggered: {
            if (root._path === "") return
            var o = {
                provider:         root.provider,
                cloudModel:       root.cloudModel,
                ollamaModel:      root.ollamaModel,
                ollamaHost:       root.ollamaHost,
                customProviders:  root.customProviders,
                whisperModel:     root.whisperModel,
                whisperLang:      root.whisperLang,
                systemPrompt:     root.systemPrompt
            }
            if (!root.keyringAvailable) o.keys = root.keys
            var b64 = root._toBase64(JSON.stringify(o))
            _save.command = ["sh", "-c", "printf '%s' '" + b64 + "' | base64 -d > '" + root._path + "'"]
            _save.running = true
        }
    }

    function refreshOllamaModels() {
        _ollamaList.running = true
    }

    Process {
        id: _ollamaList
        command: ["sh", "-c", "ollama list 2>/dev/null | tail -n +2 | awk '{print $1}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n").filter(function(l) { return l !== "" })
                root.ollamaModels = lines
                if (lines.length > 0 && root.ollamaModel === "")
                    root.set("ollamaModel", lines[0])
                if (lines.length > 0 && root.ollamaModel !== "" && lines.indexOf(root.ollamaModel) === -1)
                    root.set("ollamaModel", lines[0])
            }
        }
    }

    Timer { interval: 500; running: true; repeat: false; onTriggered: root.refreshOllamaModels() }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.refreshOllamaModels() }
}
