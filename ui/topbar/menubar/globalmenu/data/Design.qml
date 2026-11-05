pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau", mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Enregistrer", mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: "Exporter", mods: "CTRL SHIFT", key: "E", icon: "notch/save.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" }
            ]
        },
        {
            label: "Sélection",
            items: [
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Désélectionner", mods: "CTRL SHIFT", key: "A", icon: "notch/check.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Ajuster à la fenêtre", mods: "SHIFT CTRL", key: "J", icon: "notch/maximize-2.svg" }
            ]
        }
    ]
}
