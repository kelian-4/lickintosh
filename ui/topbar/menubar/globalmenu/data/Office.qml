pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau", mods: "CTRL", key: "N" },
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { label: "Enregistrer", mods: "CTRL", key: "S" },
                { label: "Imprimer", mods: "CTRL", key: "P" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { label: "Rétablir", mods: "CTRL", key: "Y" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { label: "Rechercher", mods: "CTRL", key: "F" }
            ]
        },
        {
            label: "Insertion",
            items: [
                { label: "Lien", mods: "CTRL", key: "K" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" }
            ]
        }
    ]
}
