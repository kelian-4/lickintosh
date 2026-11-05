pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Rechercher", mods: "CTRL", key: "K" },
                { separator: true },
                { label: "Fermer la fenêtre", mods: "CTRL", key: "W" },
                { label: "Quitter", mods: "CTRL", key: "Q" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Rechercher", mods: "CTRL", key: "F" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Taille réelle", mods: "CTRL", key: "0" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11" }
            ]
        }
    ]
}
