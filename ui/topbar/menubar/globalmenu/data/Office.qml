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
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Rétablir", mods: "CTRL", key: "Y", icon: "notch/rotate-cw.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Insertion",
            items: [
                { label: "Lien", mods: "CTRL", key: "K", icon: "notch/link.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" }
            ]
        }
    ]
}
