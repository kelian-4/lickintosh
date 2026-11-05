pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvelle fenêtre", mods: "CTRL", key: "N", icon: "notch/layout.svg" },
                { label: "Nouveau dossier", mods: "CTRL SHIFT", key: "N", icon: "notch/folder-plus.svg" },
                { label: "Nouvel onglet", mods: "CTRL", key: "T", icon: "notch/plus-square.svg" },
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Ouvrir avec", mods: "", key: "", disabled: true, icon: "notch/file.svg" },
                { label: "Fermer la fenêtre", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { separator: true },
                { label: "Informations", mods: "CTRL", key: "I", icon: "notch/info.svg" },
                { label: "Renommer", mods: "", key: "F2", icon: "notch/edit.svg" },
                { label: "Dupliquer", mods: "CTRL", key: "D", icon: "notch/copy.svg" },
                { label: "Aperçu rapide", mods: "", key: "", disabled: true, icon: "notch/eye.svg" },
                { label: "Imprimer", mods: "", key: "", disabled: true, icon: "notch/file-text.svg" },
                { separator: true },
                { label: "Partager", mods: "", key: "", disabled: true, icon: "notch/share.svg" },
                { separator: true },
                { label: "Mettre à la corbeille", mods: "", key: "Delete", icon: "notch/trash-2.svg" },
                { label: "Éjecter", mods: "", key: "", disabled: true, icon: "notch/disc.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Fichiers cachés", mods: "CTRL", key: "H", icon: "notch/eye.svg" },
                { label: "Actualiser", mods: "", key: "F5", icon: "notch/refresh-cw.svg" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Dossier personnel", mods: "ALT", key: "Home", icon: "notch/home.svg" },
                { label: "Dossier parent", mods: "ALT", key: "Up", icon: "notch/folder.svg" },
                { label: "Saisir un chemin", mods: "CTRL", key: "L", icon: "notch/edit-3.svg" }
            ]
        }
    ]
}
