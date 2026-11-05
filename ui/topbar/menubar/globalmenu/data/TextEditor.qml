pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau", mods: "CTRL", key: "N" },
                { label: "Nouvelle fenêtre", mods: "CTRL SHIFT", key: "N" },
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { separator: true },
                { label: "Enregistrer", mods: "CTRL", key: "S" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S" },
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
                { label: "Remplacer", mods: "CTRL", key: "H" },
                { label: "Aller à la ligne", mods: "CTRL", key: "G" }
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
