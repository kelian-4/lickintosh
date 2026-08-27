import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var resultCallback: null

    property var queueChangedCallback: null

    property var blockedCallback: null

    property var queue: []
    readonly property var current: queue.length > 0 ? queue[0] : null
    property bool busy: false

    property string _editPath: ""
    property var    _editList: []

    function _notifyQueue() { if (root.queueChangedCallback) root.queueChangedCallback() }
    function _emit(text)    { if (root.resultCallback) root.resultCallback(text) }
    function _blocked(cmd, reason) { if (root.blockedCallback) root.blockedCallback(cmd, reason) }

    function isDangerous(cmd) {
        var c = cmd.trim()

        var criticalRoots = ["/", "/boot", "/etc", "/dev", "/usr", "/bin", "/sbin", "/lib", "/sys", "/proc"]
        if (/\brm\b/i.test(c) && /-[a-z]*r/i.test(c) && /-[a-z]*f/i.test(c)) {
            for (var i = 0; i < criticalRoots.length; i++) {
                var root_ = criticalRoots[i]
                var esc = root_.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
                var re = new RegExp("(^|\\s)" + esc + "\\/?(\\*|\\s|$)")
                if (re.test(c)) return "suppression récursive forcée dans " + root_
            }
            if (/(^|\s)~\/?(\s|$)/.test(c)) return "suppression récursive forcée du dossier personnel entier"
            if (/(^|\s)\$home\/?(\s|$)/i.test(c)) return "suppression récursive forcée du dossier personnel entier"
        }

        if (/:\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:/.test(c))
            return "fork bomb"

        if (/(^|\s)mkfs(\.\w+)?(\s|$)/i.test(c))
            return "formatage de partition/disque"

        if (/(^|\s)dd\b.*\bof=\/dev\/(sd|nvme|hd|vd)/i.test(c))
            return "écriture brute sur un disque entier"

        if (/>\s*\/dev\/(sd|nvme|hd|vd)[a-z0-9]*\b/i.test(c))
            return "écriture directe sur un périphérique disque"

        if (/^(sudo\s+)?userdel\b/i.test(c))
            return "suppression d'un compte utilisateur système"

        if (/^(sudo\s+)?passwd\b/i.test(c))
            return "modification d'un mot de passe système"

        if (/\bchmod\s+(-[a-z]*r[a-z]*\s+)?000\s+\/(\s|$)/i.test(c))
            return "retrait de tous les droits sur la racine"
        if (/\bchown\s+.*-r.*\s+\/(\s|$)/i.test(c))
            return "changement de propriétaire récursif sur la racine"
        if (/>\s*\/etc\/(passwd|shadow|sudoers)\b/i.test(c))
            return "écrasement d'un fichier système sensible"
        if (/\bwipefs\b/i.test(c))
            return "effacement des signatures de systèmes de fichiers"

        return ""
    }

    function parseActions(content) {
        var blocks = []
        var re = /```(run|read|write|edit)([^\n]*)\n([\s\S]*?)```/g
        var m
        while ((m = re.exec(content)) !== null) {
            var kind    = m[1]
            var argLine = m[2].trim()
            var body    = m[3].replace(/\n$/, "")

            if (kind === "run") {
                var c = body.trim()
                if (c !== "") blocks = blocks.concat(root._enqueueOrBlock({ type: "run", cmd: c }) || [])
            } else if (kind === "read") {
                var p0 = body.trim()
                if (p0 !== "") blocks = blocks.concat(root._enqueueOrBlock({ type: "read", cmd: p0 }) || [])
            } else if (kind === "write") {
                var pathW = _extractPath(argLine)
                if (pathW) blocks = blocks.concat(root._enqueueOrBlock({ type: "write", path: pathW, newContent: body }) || [])
            } else if (kind === "edit") {
                var pathE = _extractPath(argLine)
                if (pathE) {
                    var edits = _parseEditBlocks(body)
                    if (edits.length > 0) blocks = blocks.concat(root._enqueueOrBlock({ type: "edit", path: pathE, edits: edits }) || [])
                }
            }
        }
        if (blocks.length > 0) {
            root.queue = root.queue.concat(blocks)
            _notifyQueue()
        }
        return blocks.length
    }

    function enqueueFromToolCall(name, args) {
        var action = AiToolSchema.toAction(name, args)
        if (!action) return false
        var result = root._enqueueOrBlock(action)
        if (result && result.length > 0) {
            root.queue = root.queue.concat(result)
            _notifyQueue()
            return true
        }
        return false
    }

    function _describeForBlock(action) {
        if (action.type === "run")   return action.cmd
        if (action.type === "write") return "write " + action.path
        if (action.type === "edit")  return "edit " + action.path
        return action.type
    }

    function _enqueueOrBlock(action) {
        if (action.type === "run") {
            var reason = root.isDangerous(action.cmd)
            if (reason !== "") { root._blocked(action.cmd, reason); return [] }
        } else if (action.type === "write" || action.type === "edit") {
            var reasonP = root._dangerousPath(action.path)
            if (reasonP !== "") { root._blocked(root._describeForBlock(action), reasonP); return [] }
        }
        return [action]
    }

    function _dangerousPath(path) {
        var blocked = ["/etc/passwd", "/etc/shadow", "/etc/sudoers", "/boot"]
        for (var i = 0; i < blocked.length; i++) {
            if (path === blocked[i] || path.indexOf(blocked[i] + "/") === 0)
                return "écriture dans un fichier/dossier système protégé (" + blocked[i] + ")"
        }
        return ""
    }

    function _extractPath(argLine) {
        var m = /path=(\S+)/.exec(argLine)
        return m ? m[1] : ""
    }

    function _parseEditBlocks(body) {
        var out = []
        var re = /<<<OLD\n([\s\S]*?)\n===\n([\s\S]*?)\n>>>/g
        var m
        while ((m = re.exec(body)) !== null) {
            out.push({ oldText: m[1], newText: m[2] })
        }
        return out
    }

    function dequeue() {
        if (root.queue.length === 0) return
        root.queue = root.queue.slice(1)
        _notifyQueue()
    }

    function clearQueue() {
        root.queue = []
        _notifyQueue()
    }

    function rejectCurrent() {
        var item = root.current
        if (!item) return
        dequeue()
        _emit("(action rejetée par l'utilisateur : " + _describe(item) + ")")
    }

    function _describe(item) {
        if (item.type === "run")   return "run: " + item.cmd
        if (item.type === "read")  return "read: " + item.cmd
        if (item.type === "write") return "write: " + item.path
        if (item.type === "edit")  return "edit: " + item.path
        return item.type
    }

    Process {
        id: proc
        command: []
        property string pendingErr: ""

        stdout: StdioCollector {
            id: outCollector
            onStreamFinished: proc._handleDone(text)
        }
        stderr: StdioCollector {
            id: errCollector
            onStreamFinished: proc.pendingErr = text
        }

        function _handleDone(outText) {
            root.busy = false
            var result = outText.trim()
            var err = proc.pendingErr.trim()
            proc.pendingErr = ""
            if (err !== "") result += (result !== "" ? "\n" : "") + "stderr: " + err
            if (result === "") result = "(aucune sortie)"

            if (root._editPath !== "") {
                _applyEditFromRead(result)
                return
            }
            dequeue()
            root._emit(result)
        }
    }

    function _shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function _run(cmd) {
        root.busy = true
        proc.command = ["sh", "-c", cmd]
        proc.running = true
    }

    function approveCurrent() {
        var item = root.current
        if (!item || root.busy) return

        if (item.type === "run") {
            _run(item.cmd)
        } else if (item.type === "read") {
            _run("cat -- " + _shellQuote(item.cmd) + " 2>&1 | head -c 20000")
        } else if (item.type === "write") {
            _doWrite(item.path, item.newContent)
        } else if (item.type === "edit") {
            root._editPath = item.path
            root._editList = item.edits
            _run("cat -- " + _shellQuote(item.path) + " 2>&1")
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

    function _doWrite(path, content) {
        var b64 = root._toBase64(content)
        var cmd = "mkdir -p -- \"$(dirname " + _shellQuote(path) + ")\" && printf '%s' " + _shellQuote(b64) +
        " | base64 -d > " + _shellQuote(path) + " && echo 'Fichier écrit : " + path + "'"
        _run(cmd)
    }

    function _applyEditFromRead(readResult) {
        var path  = root._editPath
        var edits = root._editList
        root._editPath = ""
        root._editList = []

        if (readResult.indexOf("stderr:") === 0 || readResult.indexOf("No such file") !== -1) {
            dequeue()
            root._emit("Échec de lecture de " + path + " avant édition :\n" + readResult)
            return
        }

        var content = readResult
        var applied = 0
        var failedIdx = []
        for (var i = 0; i < edits.length; i++) {
            var idx = content.indexOf(edits[i].oldText)
            if (idx === -1) { failedIdx.push(i + 1); continue }
            content = content.substring(0, idx) + edits[i].newText + content.substring(idx + edits[i].oldText.length)
            applied++
        }

        if (applied === 0) {
            dequeue()
            root._emit("Échec : aucun des blocs 'edit' ne correspond au contenu actuel de " + path + ". Fichier non modifié.")
            return
        }

        var b64  = root._toBase64(content)
        var msg  = "Fichier modifié : " + path + " (" + applied + "/" + edits.length + " remplacement(s) appliqué(s))"
        if (failedIdx.length > 0) msg += " — bloc(s) #" + failedIdx.join(", #") + " non trouvé(s), ignoré(s)"

        root.busy = true
        var writeCmd = "printf '%s' " + _shellQuote(b64) + " | base64 -d > " + _shellQuote(path) + " && echo " + _shellQuote(msg)
        proc.command = ["sh", "-c", writeCmd]
        proc.running = true
    }
}
