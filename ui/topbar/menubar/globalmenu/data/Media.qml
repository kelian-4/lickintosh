pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir fichier", mods: "CTRL", key: "O" },
                { label: "Ouvrir URL", mods: "CTRL", key: "U" }
            ]
        },
        {
            label: "Lecture",
            items: [
                { label: "Lecture/Pause", mods: "", key: "space" },
                { label: "Suivant", mods: "", key: "N" },
                { label: "Précédent", mods: "", key: "P" },
                { label: "Muet", mods: "", key: "M" },
                { separator: true },
                { label: "Avancer", mods: "", key: "Right" },
                { label: "Reculer", mods: "", key: "Left" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Plein écran", mods: "", key: "F" },
                { label: "Sous-titres", mods: "", key: "V" }
            ]
        }
    ]
}
