pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { label: "Imprimer", mods: "CTRL", key: "P" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Rechercher", mods: "CTRL", key: "F" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Page suivante", mods: "", key: "Page_Down" },
                { label: "Page précédente", mods: "", key: "Page_Up" }
            ]
        }
    ]
}
