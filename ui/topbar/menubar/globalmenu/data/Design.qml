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
                { label: "Exporter", mods: "CTRL SHIFT", key: "E" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" }
            ]
        },
        {
            label: "Sélection",
            items: [
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Désélectionner", mods: "CTRL SHIFT", key: "A" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "", key: "plus" },
                { label: "Zoom arrière", mods: "", key: "minus" },
                { label: "Ajuster à la fenêtre", mods: "SHIFT CTRL", key: "J" }
            ]
        }
    ]
}
