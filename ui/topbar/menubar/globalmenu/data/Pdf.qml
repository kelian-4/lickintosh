pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Page suivante", mods: "", key: "Page_Down", icon: "notch/skip-forward.svg" },
                { label: "Page précédente", mods: "", key: "Page_Up", icon: "notch/skip-back.svg" }
            ]
        }
    ]
}
