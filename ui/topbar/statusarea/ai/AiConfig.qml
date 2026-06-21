pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string provider:    "anthropic"
    property string cloudModel:  "claude-sonnet-4-6"
    property string ollamaModel: ""
    property string ollamaHost:  "http://localhost:11434"

    
    property string keyAnthropic:  ""
    property string keyOpenai:     ""
    property string keyGemini:     ""
    property string keyGroq:       ""
    property string keyMistral:    ""
    property string keyDeepseek:   ""
    property string keyOpenrouter: ""

    function getKey(pid) {
        if (pid === "anthropic")  return root.keyAnthropic
        if (pid === "openai")     return root.keyOpenai
        if (pid === "gemini")     return root.keyGemini
        if (pid === "groq")       return root.keyGroq
        if (pid === "mistral")    return root.keyMistral
        if (pid === "deepseek")   return root.keyDeepseek
        if (pid === "openrouter") return root.keyOpenrouter
        return ""
    }

    function setKey(pid, val) {
        if (pid === "anthropic")  root.keyAnthropic  = val
        else if (pid === "openai")     root.keyOpenai     = val
        else if (pid === "gemini")     root.keyGemini     = val
        else if (pid === "groq")       root.keyGroq       = val
        else if (pid === "mistral")    root.keyMistral    = val
        else if (pid === "deepseek")   root.keyDeepseek   = val
        else if (pid === "openrouter") root.keyOpenrouter = val
        _saveTimer.restart()
    }

    function set(key, value) {
        root[key] = value
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
                    if (o.provider)       root.provider       = o.provider
                    if (o.cloudModel)     root.cloudModel     = o.cloudModel
                    if (o.ollamaModel)    root.ollamaModel    = o.ollamaModel
                    if (o.ollamaHost)     root.ollamaHost     = o.ollamaHost
                    if (o.keyAnthropic)   root.keyAnthropic   = o.keyAnthropic
                    if (o.keyOpenai)      root.keyOpenai      = o.keyOpenai
                    if (o.keyGemini)      root.keyGemini      = o.keyGemini
                    if (o.keyGroq)        root.keyGroq        = o.keyGroq
                    if (o.keyMistral)     root.keyMistral     = o.keyMistral
                    if (o.keyDeepseek)    root.keyDeepseek    = o.keyDeepseek
                    if (o.keyOpenrouter)  root.keyOpenrouter  = o.keyOpenrouter
                } catch(e) {}
            }
        }
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
                provider:       root.provider,
                cloudModel:     root.cloudModel,
                ollamaModel:    root.ollamaModel,
                ollamaHost:     root.ollamaHost,
                keyAnthropic:   root.keyAnthropic,
                keyOpenai:      root.keyOpenai,
                keyGemini:      root.keyGemini,
                keyGroq:        root.keyGroq,
                keyMistral:     root.keyMistral,
                keyDeepseek:    root.keyDeepseek,
                keyOpenrouter:  root.keyOpenrouter
            }
            var json = JSON.stringify(o).replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
            _save.command = ["sh", "-c", "printf '%s' '" + json + "' > '" + root._path + "'"]
            _save.running = true
        }
    }
}
