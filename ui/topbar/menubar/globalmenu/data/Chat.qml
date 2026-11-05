pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Rechercher", mods: "CTRL", key: "K", icon: "notch/search.svg" },
                { separator: true },
                { label: "Fermer la fenêtre", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Quitter", mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Taille réelle", mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        }
    ]
}
