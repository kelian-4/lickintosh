pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    reloadableId: "quoteState"

    readonly property string filePath: Quickshell.env("HOME") + "/.config/lickintosh/core/quote.json"
    readonly property string endpoint: "https://zenquotes.io/api/today"

    property string dateKey: root._key()

    onApiLanguageChanged: root.refresh()

    readonly property var _quotes: [
        I18n.tr("Le code le plus simple est celui qu'on n'a pas eu besoin d'écrire."),
        I18n.tr("Un système bien pensé se répare avant de casser."),
        I18n.tr("La discipline d'aujourd'hui est la vitesse de demain."),
        I18n.tr("Ce qui se règle en cinq minutes maintenant en prend une heure plus tard."),
        I18n.tr("La clarté est une forme de respect envers ton futur toi."),
        I18n.tr("On ne maîtrise pas un outil, on apprend juste à moins se battre avec."),
        I18n.tr("Un petit progrès régulier bat un grand élan irrégulier."),
        I18n.tr("Bien nommer une chose, c'est déjà la comprendre à moitié."),
        I18n.tr("Le silence d'un terminal qui tourne est parfois le meilleur signal."),
        I18n.tr("Une bonne pause vaut mieux qu'un mauvais commit."),
        I18n.tr("Ranger son code, c'est ranger ses idées."),
        I18n.tr("Ce qu'on automatise une fois, on ne le refait plus jamais mal."),
        I18n.tr("La curiosité est le seul debugger qui ne ment jamais."),
        I18n.tr("Un plan simple exécuté vaut mieux qu'un plan parfait remis à demain."),
        I18n.tr("Le meilleur moment pour documenter, c'était avant d'oublier pourquoi.")
    ]

    function _key() {
        var now = new Date()
        return now.getFullYear() + "-" + (now.getMonth() + 1) + "-" + now.getDate()
    }

    function _dayOfYear() {
        var now = new Date()
        var start = new Date(now.getFullYear(), 0, 0)
        return Math.floor((now - start) / 86400000)
    }

    readonly property bool apiLanguage: I18n.lang === "en"
    readonly property bool fresh: root.apiLanguage && quoteAdapter.date === root.dateKey && quoteAdapter.text !== ""
    readonly property string today: root.fresh ? quoteAdapter.text : root._quotes[root._dayOfYear() % root._quotes.length]
    readonly property string author: root.fresh ? quoteAdapter.author : ""
    readonly property bool fromApi: root.fresh

    function refresh() {
        if (root.apiLanguage && !root.fresh && !fetcher.running) fetcher.running = true
    }

    function apply(raw) {
        var data
        try {
            data = JSON.parse(raw)
        } catch (e) {
            return
        }
        if (!Array.isArray(data) || data.length === 0 || !data[0].q) return
        if (data[0].q.indexOf("Too many requests") >= 0) return
        quoteAdapter.date = root.dateKey
        quoteAdapter.text = data[0].q
        quoteAdapter.author = data[0].a || ""
    }

    FileView {
        id: quoteFile
        path: root.filePath
        onAdapterUpdated: writeAdapter()
        onLoaded: root.refresh()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
            root.refresh()
        }

        JsonAdapter {
            id: quoteAdapter
            property string date: ""
            property string text: ""
            property string author: ""
        }
    }

    Process {
        id: fetcher
        command: ["curl", "-fsS", "--max-time", "8", root.endpoint]
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: {
            root.dateKey = root._key()
            root.refresh()
        }
    }
}
