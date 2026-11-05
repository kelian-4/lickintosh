pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau message", mods: "CTRL", key: "N" },
                { label: "Relever les messages", mods: "", key: "F5" },
                { separator: true },
                { label: "Imprimer", mods: "CTRL", key: "P" },
                { separator: true },
                { label: "Fermer", mods: "CTRL", key: "W" },
                { label: "Quitter", mods: "CTRL", key: "Q" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { label: "Rétablir", mods: "CTRL SHIFT", key: "Z" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Rechercher", mods: "CTRL", key: "F" },
                { label: "Recherche globale", mods: "CTRL", key: "K" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Plein écran", mods: "", key: "F11" },
                { separator: true },
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Taille réelle", mods: "CTRL", key: "0" }
            ]
        },
        {
            label: "Message",
            items: [
                { label: "Répondre", mods: "CTRL", key: "R" },
                { label: "Répondre à tous", mods: "CTRL SHIFT", key: "R" },
                { label: "Transférer", mods: "CTRL", key: "L" },
                { separator: true },
                { label: "Archiver", mods: "", key: "A" },
                { label: "Marquer comme lu", mods: "", key: "M" },
                { label: "Supprimer", mods: "", key: "Delete" },
                { separator: true },
                { label: "Message suivant non lu", mods: "", key: "F" },
                { label: "Message précédent", mods: "", key: "B" }
            ]
        }
    ]
}
