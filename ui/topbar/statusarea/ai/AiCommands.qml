pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var commands: [
        { name: "model",    args: "set <nom>",                 desc: "Changer de modèle" },
        { name: "provider", args: "set <id> [key <clé>]",       desc: "Changer de provider, avec clé optionnelle" },
        { name: "key",      args: "set <provider> <clé> | remove <provider>", desc: "Définir ou supprimer une clé API" },
        { name: "add",      args: "<id> <endpoint> <format> <modèle>", desc: "Ajouter un provider personnalisé" },
        { name: "chat",     args: "list | load <id> | new | delete <id> | clear", desc: "Gérer les conversations sauvegardées" },
        { name: "clear",    args: "",                           desc: "Effacer la conversation" },
        { name: "help",     args: "",                           desc: "Liste des commandes" }
    ]

    readonly property var modelsByProvider: ({
        anthropic: ["claude-sonnet-5", "claude-opus-5", "claude-fable-5", "claude-haiku-4-5"],
        openai:    ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"],
        google:    ["gemini-3.6-flash", "gemini-3.5-flash", "gemini-3.5-flash-lite"],
        ollama:    []
    })

    readonly property var builtinProviders: ["anthropic", "openai", "google", "ollama"]
    readonly property var formats: ["anthropic", "openai-compat", "gemini"]

    function allProviders() {
        var custom = (AiConfig.customProviders || []).map(function(p) { return p.id })
        return root.builtinProviders.concat(custom)
    }

    function isCustomProvider(id) {
        return (AiConfig.customProviders || []).some(function(p) { return p.id === id })
    }

    function customProvider(id) {
        var list = AiConfig.customProviders || []
        for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i]
        return null
    }

    function modelsFor(providerId) {
        if (providerId === "ollama") return AiConfig.ollamaModels
        if (root.modelsByProvider[providerId]) return root.modelsByProvider[providerId]
        var cp = root.customProvider(providerId)
        if (cp && cp.model) return [cp.model]
        return []
    }

    function allowsFreeformModel(providerId) {
        return providerId !== "ollama"
    }

    function isSlashCommand(line) {
        return /^\/\S+/.test(line.trim())
    }

    function tokenize(line) {
        var t = line.trim()
        if (t.indexOf("/") !== 0) return null
        return t.substring(1).split(/\s+/)
    }

    function needsKey(providerId) {
        return providerId !== "ollama" && AiConfig.getKey(providerId) === ""
    }

    function suggest(text) {
        if (text.indexOf("/") !== 0) return []

        var body = text.substring(1)
        var endsWithSpace = /\s$/.test(body)
        var parts = body.split(/\s+/).filter(function(p) { return p !== "" })

        if (parts.length === 0) {
            return root.commands.map(function(c) {
                return { value: c.name, label: "/" + c.name, sub: "", desc: c.desc, insertSuffix: " ", freeform: false, terminal: c.args === "" }
            })
        }

        var cmd = parts[0].toLowerCase()
        var typing = endsWithSpace ? "" : parts[parts.length - 1]
        var fixedParts = endsWithSpace ? parts : parts.slice(0, parts.length - 1)

        if (parts.length === 1 && !endsWithSpace) {
            var frag = typing.toLowerCase()
            return root.commands
                .filter(function(c) { return c.name.indexOf(frag) === 0 })
                .map(function(c) {
                    return { value: c.name, label: "/" + c.name, sub: "", desc: c.desc, insertSuffix: " ", freeform: false, terminal: c.args === "" }
                })
        }

        if (root.commands.every(function(c) { return c.name !== cmd })) return []

        if (cmd === "model")    return root._suggestModel(fixedParts.slice(1), typing)
        if (cmd === "provider") return root._suggestProvider(fixedParts.slice(1), typing)
        if (cmd === "key")      return root._suggestKey(fixedParts.slice(1), typing)
        if (cmd === "add")      return root._suggestAdd(fixedParts.slice(1), typing)
        if (cmd === "chat")     return root._suggestChat(fixedParts.slice(1), typing)
        return []
    }

    function _filterList(list, typing, toItem) {
        var f = typing.toLowerCase()
        return list
            .filter(function(v) { return f === "" || v.toLowerCase().indexOf(f) === 0 })
            .map(toItem)
    }

    function _suggestModel(rest, typing) {
        if (rest.length === 0) {
            return root._filterList(["set"], typing, function(v) {
                return { value: v, label: "set", sub: "<nom du modèle>", desc: "Changer de modèle", insertSuffix: " ", freeform: false }
            })
        }
        if (rest[0] === "set" && rest.length === 1) {
            var list = root.modelsFor(AiConfig.provider)
            var known = root._filterList(list, typing, function(m) {
                return { value: m, label: m, sub: "", desc: m === AiConfig.cloudModel ? "modèle actif" : "connu", insertSuffix: "", freeform: false }
            })
            if (root.allowsFreeformModel(AiConfig.provider)) {
                known.push({ value: typing, label: typing !== "" ? typing : "<nom du modèle>", sub: "", desc: "autre modèle (texte libre)", insertSuffix: "", freeform: true })
            } else if (known.length === 0) {
                known.push({ value: "", label: list.length === 0 ? "Aucun modèle Ollama installé" : "Aucune correspondance", sub: "", desc: list.length === 0 ? "essaie : ollama pull <modèle>" : "", insertSuffix: "", freeform: true, nonInsertable: true })
            }
            return known
        }
        if (rest[0] === "set" && rest.length === 2) {
            return [{ value: "", label: "Entrée", sub: "", desc: "valider — modèle : " + rest[1], insertSuffix: "", freeform: true, submitNow: true }]
        }
        return []
    }

    function _suggestProvider(rest, typing) {
        if (rest.length === 0) {
            return root._filterList(["set"], typing, function(v) {
                return { value: v, label: "set", sub: "<id> [key <clé>]", desc: "Changer de provider", insertSuffix: " ", freeform: false }
            })
        }
        if (rest[0] === "set" && rest.length === 1) {
            return root._filterList(root.allProviders(), typing, function(p) {
                return { value: p, label: p, sub: "", desc: p === AiConfig.provider ? "actif" : (root.needsKey(p) ? "pas de clé" : ""), insertSuffix: " ", freeform: false }
            })
        }
        if (rest[0] === "set" && rest.length === 2) {
            var pid = rest[1].toLowerCase()
            if (root.needsKey(pid)) {
                return root._filterList(["key"], typing, function(v) {
                    return { value: v, label: "key", sub: "<clé>", desc: "Ajouter la clé API de " + pid + " maintenant", insertSuffix: " ", freeform: false }
                })
            }
            return [{ value: "", label: "Entrée", sub: "", desc: "valider — " + pid + " a déjà une clé", insertSuffix: "", freeform: true, submitNow: true }]
        }
        if (rest[0] === "set" && rest[2] === "key" && rest.length === 3) {
            return [{ value: typing, label: typing !== "" ? typing : "<colle ta clé ici>", sub: "", desc: "puis Entrée", insertSuffix: "", freeform: true }]
        }
        if (rest[0] === "set" && rest[2] === "key" && rest.length === 4) {
            return [{ value: "", label: "Entrée", sub: "", desc: "valider — provider et clé prêts", insertSuffix: "", freeform: true, submitNow: true }]
        }
        return []
    }

    function _suggestKey(rest, typing) {
        if (rest.length === 0) {
            return root._filterList(["set", "remove"], typing, function(v) {
                return v === "set"
                    ? { value: v, label: "set", sub: "<provider> <clé>", desc: "Définir une clé API", insertSuffix: " ", freeform: false }
                    : { value: v, label: "remove", sub: "<provider>", desc: "Supprimer une clé API", insertSuffix: " ", freeform: false }
            })
        }
        if (rest[0] === "set" && rest.length === 1) {
            return root._filterList(root.allProviders().filter(function(p) { return p !== "ollama" }), typing, function(p) {
                return { value: p, label: p, sub: "", desc: AiConfig.getKey(p) !== "" ? "clé déjà définie — sera remplacée" : "aucune clé", insertSuffix: " ", freeform: false }
            })
        }
        if (rest[0] === "set" && rest.length === 2) {
            return [{ value: typing, label: typing !== "" ? typing : "<colle ta clé ici>", sub: "", desc: "puis Entrée", insertSuffix: "", freeform: true }]
        }
        if (rest[0] === "set" && rest.length === 3) {
            return [{ value: "", label: "Entrée", sub: "", desc: "valider — clé enregistrée pour " + rest[1], insertSuffix: "", freeform: true, submitNow: true }]
        }
        if (rest[0] === "remove" && rest.length === 1) {
            var withKey = root.allProviders().filter(function(p) { return p !== "ollama" && AiConfig.getKey(p) !== "" })
            if (withKey.length === 0) {
                return [{ value: "", label: "Aucune clé enregistrée", sub: "", desc: "", insertSuffix: "", freeform: true, nonInsertable: true }]
            }
            return root._filterList(withKey, typing, function(p) {
                return { value: p, label: p, sub: "", desc: "supprimer sa clé", insertSuffix: "", freeform: false, terminal: true }
            })
        }
        return []
    }

    function _suggestAdd(rest, typing) {
        if (rest.length === 0) {
            return [{ value: typing, label: typing !== "" ? typing : "<identifiant>", sub: "", desc: "ex : monprovider", insertSuffix: " ", freeform: true }]
        }
        if (rest.length === 1) {
            return [{ value: typing, label: typing !== "" ? typing : "<endpoint>", sub: "", desc: "URL complète de l'API", insertSuffix: " ", freeform: true }]
        }
        if (rest.length === 2) {
            return root._filterList(root.formats, typing, function(f) {
                return { value: f, label: f, sub: "", desc: "", insertSuffix: " ", freeform: false }
            })
        }
        if (rest.length === 3) {
            return [{ value: typing, label: typing !== "" ? typing : "<nom du modèle>", sub: "", desc: "puis Entrée", insertSuffix: "", freeform: true }]
        }
        if (rest.length === 4) {
            return [{ value: "", label: "Entrée", sub: "", desc: "valider — ajoute " + rest[0], insertSuffix: "", freeform: true, submitNow: true }]
        }
        return []
    }

    function _suggestChat(rest, typing) {
        if (rest.length === 0) {
            return root._filterList(["list", "load", "new", "delete", "clear"], typing, function(v) {
                var descs = { list: "Voir les conversations sauvegardées", load: "Charger une conversation", new: "Démarrer une nouvelle conversation", delete: "Supprimer une conversation", clear: "Supprimer tout l'historique" }
                var terminal = (v === "list" || v === "new" || v === "clear")
                return { value: v, label: v, sub: "", desc: descs[v], insertSuffix: terminal ? "" : " ", freeform: false, terminal: terminal }
            })
        }
        if ((rest[0] === "load" || rest[0] === "delete") && rest.length === 1) {
            var chats = AiChats.chats
            if (chats.length === 0) {
                return [{ value: "", label: "Aucune conversation sauvegardée", sub: "", desc: "", insertSuffix: "", freeform: true, nonInsertable: true }]
            }
            return root._filterList(chats.map(function(c) { return c.id }), typing, function(id) {
                var c = chats.find(function(x) { return x.id === id })
                return { value: id, label: c.title, sub: "", desc: new Date(c.updatedAt).toLocaleDateString(), insertSuffix: "", freeform: false, terminal: true }
            })
        }
        return []
    }

    function validate(line) {
        var tokens = root.tokenize(line)
        if (!tokens || tokens.length === 0) return { ok: false, error: "Commande vide" }
        var cmd = tokens[0].toLowerCase()
        var rest = tokens.slice(1)

        if (root.commands.every(function(c) { return c.name !== cmd }))
            return { ok: false, error: "Commande inconnue : /" + cmd + " — essaie /help" }

        if (cmd === "clear" || cmd === "help") return { ok: true, cmd: cmd, rest: rest }

        if (cmd === "model") {
            if (rest[0] !== "set" || !rest[1]) return { ok: false, error: "Syntaxe : /model set <nom>" }
            if (!root.allowsFreeformModel(AiConfig.provider)) {
                var name = rest.slice(1).join(" ")
                var known = root.modelsFor(AiConfig.provider)
                if (known.indexOf(name) === -1) {
                    return { ok: false, error: "Modèle Ollama inconnu : \"" + name + "\". Modèles installés : " + (known.length ? known.join(", ") : "aucun — installe-en un avec 'ollama pull <modèle>'") }
                }
            }
            return { ok: true, cmd: cmd, rest: rest }
        }

        if (cmd === "provider") {
            if (rest[0] !== "set" || !rest[1]) return { ok: false, error: "Syntaxe : /provider set <id> [key <clé>]" }
            if (root.allProviders().indexOf(rest[1].toLowerCase()) === -1)
                return { ok: false, error: "Provider inconnu : \"" + rest[1] + "\". Choisis parmi : " + root.allProviders().join(", ") + " — ou ajoute-le avec /add" }
            if (rest.length > 2 && rest[2] !== "key")
                return { ok: false, error: "Syntaxe : /provider set " + rest[1] + " key <clé>" }
            if (rest[2] === "key" && !rest[3])
                return { ok: false, error: "Il manque la clé après 'key'" }
            return { ok: true, cmd: cmd, rest: rest }
        }

        if (cmd === "key") {
            if (rest[0] === "remove") {
                if (!rest[1]) return { ok: false, error: "Syntaxe : /key remove <provider>" }
                var pidR = rest[1].toLowerCase()
                if (AiConfig.getKey(pidR) === "") return { ok: false, error: "Aucune clé enregistrée pour \"" + pidR + "\"" }
                return { ok: true, cmd: cmd, rest: rest }
            }
            if (rest[0] !== "set" || !rest[1]) return { ok: false, error: "Syntaxe : /key set <provider> <clé> ou /key remove <provider>" }
            var pid = rest[1].toLowerCase()
            if (root.allProviders().indexOf(pid) === -1 || pid === "ollama")
                return { ok: false, error: "Provider inconnu : \"" + rest[1] + "\"" }
            if (!rest[2]) return { ok: false, error: "Il manque la clé. Syntaxe : /key set " + pid + " <clé>" }
            return { ok: true, cmd: cmd, rest: rest }
        }

        if (cmd === "add") {
            if (!rest[0]) return { ok: false, error: "Syntaxe : /add <id> <endpoint> <format> <modèle>" }
            if (root.builtinProviders.indexOf(rest[0].toLowerCase()) !== -1)
                return { ok: false, error: "\"" + rest[0] + "\" est déjà un provider intégré, choisis un autre identifiant" }
            if (!rest[1] || !/^https?:\/\//.test(rest[1]))
                return { ok: false, error: "L'endpoint doit être une URL complète (http:// ou https://)" }
            if (!rest[2] || root.formats.indexOf(rest[2]) === -1)
                return { ok: false, error: "Format inconnu : \"" + (rest[2] || "") + "\". Choisis parmi : " + root.formats.join(", ") }
            if (!rest[3]) return { ok: false, error: "Il manque le nom du modèle" }
            return { ok: true, cmd: cmd, rest: rest }
        }

        if (cmd === "chat") {
            var sub = rest[0]
            if (!sub || ["list", "load", "new", "delete", "clear"].indexOf(sub) === -1)
                return { ok: false, error: "Syntaxe : /chat list | load <id> | new | delete <id> | clear" }
            if ((sub === "load" || sub === "delete") && !rest[1])
                return { ok: false, error: "Syntaxe : /chat " + sub + " <id>" }
            if ((sub === "load" || sub === "delete") && AiChats.chats.every(function(c) { return c.id !== rest[1] }))
                return { ok: false, error: "Conversation introuvable : \"" + rest[1] + "\"" }
            return { ok: true, cmd: cmd, rest: rest }
        }

        return { ok: false, error: "Commande inconnue : /" + cmd }
    }
}
