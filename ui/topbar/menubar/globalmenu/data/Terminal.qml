pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvel onglet", mods: "CTRL SHIFT", key: "T" },
                { label: "Nouvelle fenêtre", mods: "CTRL SHIFT", key: "N" },
                { label: "Fermer l'onglet", mods: "CTRL SHIFT", key: "W" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL SHIFT", key: "C" },
                { label: "Coller", mods: "CTRL SHIFT", key: "V" },
                { label: "Rechercher", mods: "CTRL SHIFT", key: "F" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL SHIFT", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Réinitialiser zoom", mods: "CTRL", key: "0" },
                { label: "Plein écran", mods: "", key: "F11" }
            ]
        }
    ]
}
