pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Citations originales (rédigées pour ce projet, pas de reproduction
// de texte protégé), une par jour choisie de façon déterministe pour
// rester stable toute la journée sans dépendance réseau ni API key.
Singleton {
    id: root

    reloadableId: "quoteState"

    readonly property var _quotes: [
        "Le code le plus simple est celui qu'on n'a pas eu besoin d'écrire.",
        "Un système bien pensé se répare avant de casser.",
        "La discipline d'aujourd'hui est la vitesse de demain.",
        "Ce qui se règle en cinq minutes maintenant en prend une heure plus tard.",
        "La clarté est une forme de respect envers ton futur toi.",
        "On ne maîtrise pas un outil, on apprend juste à moins se battre avec.",
        "Un petit progrès régulier bat un grand élan irrégulier.",
        "Bien nommer une chose, c'est déjà la comprendre à moitié.",
        "Le silence d'un terminal qui tourne est parfois le meilleur signal.",
        "Une bonne pause vaut mieux qu'un mauvais commit.",
        "Ranger son code, c'est ranger ses idées.",
        "Ce qu'on automatise une fois, on ne le refait plus jamais mal.",
        "La curiosité est le seul debugger qui ne ment jamais.",
        "Un plan simple exécuté vaut mieux qu'un plan parfait remis à demain.",
        "Le meilleur moment pour documenter, c'était avant d'oublier pourquoi."
    ]

    function _dayOfYear() {
        var now = new Date()
        var start = new Date(now.getFullYear(), 0, 0)
        var diff = now - start
        return Math.floor(diff / 86400000)
    }

    readonly property string today: root._quotes[root._dayOfYear() % root._quotes.length]
}
