pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var tools: [
        {
            name: "run",
            description: "Exécute une commande shell sur le système de l'utilisateur. L'utilisateur doit approuver avant exécution.",
            parameters: {
                type: "object",
                properties: {
                    command: { type: "string", description: "La commande shell à exécuter" }
                },
                required: ["command"]
            }
        },
        {
            name: "read",
            description: "Lit le contenu d'un fichier sur le système de l'utilisateur. L'utilisateur doit approuver avant lecture.",
            parameters: {
                type: "object",
                properties: {
                    path: { type: "string", description: "Chemin absolu du fichier à lire" }
                },
                required: ["path"]
            }
        },
        {
            name: "write",
            description: "Écrit un fichier ENTIER, l'écrase s'il existe déjà. L'utilisateur doit approuver avant écriture.",
            parameters: {
                type: "object",
                properties: {
                    path:    { type: "string", description: "Chemin absolu du fichier à écrire" },
                    content: { type: "string", description: "Contenu complet à écrire dans le fichier" }
                },
                required: ["path", "content"]
            }
        },
        {
            name: "edit",
            description: "Modifie une partie d'un fichier existant en remplaçant un texte exact par un autre. Le texte à remplacer doit correspondre EXACTEMENT (espaces, indentation) au contenu actuel du fichier, sinon l'édition échoue. L'utilisateur doit approuver avant modification.",
            parameters: {
                type: "object",
                properties: {
                    path:     { type: "string", description: "Chemin absolu du fichier à modifier" },
                    old_text: { type: "string", description: "Texte exact actuel à remplacer" },
                    new_text: { type: "string", description: "Texte de remplacement" }
                },
                required: ["path", "old_text", "new_text"]
            }
        }
    ]

    function forAnthropic() {
        return root.tools.map(function(t) {
            return { name: t.name, description: t.description, input_schema: t.parameters }
        })
    }

    function forOpenAI() {
        return root.tools.map(function(t) {
            return { type: "function", function: { name: t.name, description: t.description, parameters: t.parameters } }
        })
    }

    function forGemini() {
        return [{
            functionDeclarations: root.tools.map(function(t) {
                return { name: t.name, description: t.description, parameters: t.parameters }
            })
        }]
    }

    function toAction(name, args) {
        if (name === "run")   return { type: "run", cmd: args.command || "" }
        if (name === "read")  return { type: "read", cmd: args.path || "" }
        if (name === "write") return { type: "write", path: args.path || "", newContent: args.content || "" }
        if (name === "edit")  return { type: "edit", path: args.path || "", edits: [{ oldText: args.old_text || "", newText: args.new_text || "" }] }
        return null
    }
}
