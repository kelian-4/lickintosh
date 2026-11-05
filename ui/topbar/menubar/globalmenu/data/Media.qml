pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir fichier", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Ouvrir URL", mods: "CTRL", key: "U", icon: "notch/link.svg" }
            ]
        },
        {
            label: "Lecture",
            items: [
                { label: "Lecture/Pause", mods: "", key: "space", icon: "notch/play.svg" },
                { label: "Suivant", mods: "", key: "N", icon: "notch/skip-forward.svg" },
                { label: "Précédent", mods: "", key: "P", icon: "notch/skip-back.svg" },
                { label: "Muet", mods: "", key: "M", icon: "notch/volume-x.svg" },
                { separator: true },
                { label: "Avancer", mods: "", key: "Right", icon: "notch/fast-forward.svg" },
                { label: "Reculer", mods: "", key: "Left", icon: "notch/rewind.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Plein écran", mods: "", key: "F", icon: "notch/maximize.svg" },
                { label: "Sous-titres", mods: "", key: "V", icon: "notch/type.svg" }
            ]
        }
    ]
}
