pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvel onglet", mods: "CTRL SHIFT", key: "T", icon: "notch/plus-square.svg" },
                { label: "Nouvelle fenêtre", mods: "CTRL SHIFT", key: "N", icon: "notch/layout.svg" },
                { label: "Fermer l'onglet", mods: "CTRL SHIFT", key: "W", icon: "notch/x.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL SHIFT", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL SHIFT", key: "V", icon: "notch/clipboard.svg" },
                { label: "Rechercher", mods: "CTRL SHIFT", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL SHIFT", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Réinitialiser zoom", mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { label: "Plein écran", mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        }
    ]
}
