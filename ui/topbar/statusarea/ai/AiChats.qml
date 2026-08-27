pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var chats: []
    property bool loaded: false

    property string _home: ""
    property string _dir: _home !== "" ? _home + "/.config/macos-shell/ai-chats" : ""
    property string _indexPath: _dir !== "" ? _dir + "/index.json" : ""

    Process {
        id: _getHome
        command: ["sh", "-c", "echo $HOME"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._home = text.trim()
                _loadIndex.running = true
            }
        }
    }

    Process {
        id: _loadIndex
        command: ["sh", "-c",
            "mkdir -p '" + root._dir + "' && cat '" + root._indexPath + "' 2>/dev/null || echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text)
                    if (Array.isArray(arr)) root.chats = arr
                } catch(e) {}
                root.loaded = true
            }
        }
    }

    function _saveIndex() {
        if (root._indexPath === "") return
        var b64 = root._toBase64(JSON.stringify(root.chats))
        _saveIndexProc.command = ["sh", "-c", "printf '%s' '" + b64 + "' | base64 -d > '" + root._indexPath + "'"]
        _saveIndexProc.running = true
    }

    Process { id: _saveIndexProc; command: []; running: false }

    function _newId() {
        return "chat_" + Date.now() + "_" + Math.floor(Math.random() * 10000)
    }

    function _chatPath(id) {
        return root._dir + "/" + id + ".json"
    }

    function _titleFrom(messages) {
        for (var i = 0; i < messages.length; i++) {
            if (messages[i].role === "user") {
                var t = messages[i].content.trim().replace(/\s+/g, " ")
                return t.length > 48 ? t.substring(0, 48) + "…" : (t || "Sans titre")
            }
        }
        return "Nouvelle conversation"
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

    function saveChat(messages, model, existingId) {
        if (!messages || messages.length === 0) return ""
        var id = existingId || root._newId()
        var now = Date.now()

        var existing = root.chats.find(function(c) { return c.id === id })
        var title = existing ? existing.title : root._titleFrom(messages)

        var meta = { id: id, title: title, updatedAt: now, messageCount: messages.length, titlePending: !existing }
        var list = root.chats.filter(function(c) { return c.id !== id })
        list.unshift(meta)
        root.chats = list
        root._saveIndex()

        var body = { messages: messages, model: model || "", savedAt: now }
        var b64 = root._toBase64(JSON.stringify(body))
        var proc = _writeChatComponent.createObject(root, { _path: root._chatPath(id), _b64: b64 })
        proc.running = true
        return id
    }

    function updateChatTitle(id, title) {
        var t = title.trim().replace(/\s+/g, " ").replace(/^["'“”]+|["'“”]+$/g, "")
        if (t.length > 48) t = t.substring(0, 48) + "…"
        if (t === "") return
        root.chats = root.chats.map(function(c) {
            if (c.id !== id) return c
            var updated = Object.assign({}, c)
            updated.title = t
            updated.titlePending = false
            return updated
        })
        root._saveIndex()
    }

    property Component _writeChatComponent: Component {
        Process {
            id: writeProc
            property string _path: ""
            property string _b64: ""
            command: ["sh", "-c", "printf '%s' '" + _b64 + "' | base64 -d > '" + _path + "'"]
            onExited: function() { writeProc.destroy() }
        }
    }

    function deleteChat(id) {
        root.chats = root.chats.filter(function(c) { return c.id !== id })
        root._saveIndex()
        var proc = _deleteChatComponent.createObject(root, { _path: root._chatPath(id) })
        proc.running = true
    }

    function clearAllChats() {
        var ids = root.chats.map(function(c) { return c.id })
        root.chats = []
        root._saveIndex()
        for (var i = 0; i < ids.length; i++) {
            var proc = _deleteChatComponent.createObject(root, { _path: root._chatPath(ids[i]) })
            proc.running = true
        }
    }

    property Component _deleteChatComponent: Component {
        Process {
            id: delProc
            property string _path: ""
            command: ["sh", "-c", "rm -f '" + _path + "'"]
            onExited: function() { delProc.destroy() }
        }
    }

    function loadChat(id, callback) {
        var proc = _readChatComponent.createObject(root, { _path: root._chatPath(id), _callback: callback })
        proc.running = true
    }

    property Component _readChatComponent: Component {
        Process {
            id: readProc
            property string _path: ""
            property var _callback: null
            command: ["sh", "-c", "cat '" + _path + "' 2>/dev/null || echo '{}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var result = null
                    try {
                        var o = JSON.parse(text)
                        if (o.messages) result = o
                    } catch(e) {}
                    if (readProc._callback) readProc._callback(result)
                    readProc.destroy()
                }
            }
        }
    }
}
