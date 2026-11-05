pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau", mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: "Nouvelle fenêtre", mods: "CTRL SHIFT", key: "N", icon: "notch/layout.svg" },
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { separator: true },
                { label: "Enregistrer", mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { separator: true },
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { separator: true },
                { label: "Fermer", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Quitter", mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Rétablir", mods: "CTRL SHIFT", key: "Z", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: "Remplacer", mods: "CTRL", key: "H", icon: "notch/refresh-cw.svg" },
                { label: "Aller à la ligne", mods: "CTRL", key: "G", icon: "notch/corner-down-right.svg" }
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
