pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvelle fenêtre", mods: "CTRL", key: "N" },
                { label: "Nouveau dossier", mods: "CTRL SHIFT", key: "N", icon: "notch/folder-plus.svg" },
                { label: "Nouvel onglet", mods: "CTRL", key: "T" },
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { label: "Ouvrir avec", mods: "", key: "", disabled: true },
                { label: "Fermer la fenêtre", mods: "CTRL", key: "W" },
                { separator: true },
                { label: "Informations", mods: "CTRL", key: "I", icon: "notch/info.svg" },
                { label: "Renommer", mods: "", key: "F2", icon: "notch/edit.svg" },
                { label: "Dupliquer", mods: "CTRL", key: "D", icon: "notch/copy.svg" },
                { label: "Aperçu rapide", mods: "", key: "", disabled: true, icon: "notch/eye.svg" },
                { label: "Imprimer", mods: "", key: "", disabled: true },
                { separator: true },
                { label: "Partager", mods: "", key: "", disabled: true },
                { separator: true },
                { label: "Mettre à la corbeille", mods: "", key: "Delete", icon: "notch/trash-2.svg" },
                { label: "Éjecter", mods: "", key: "", disabled: true }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Annuler", mods: "CTRL", key: "Z" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Fichiers cachés", mods: "CTRL", key: "H" },
                { label: "Actualiser", mods: "", key: "F5" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Dossier personnel", mods: "ALT", key: "Home", icon: "notch/home.svg" },
                { label: "Dossier parent", mods: "ALT", key: "Up" },
                { label: "Saisir un chemin", mods: "CTRL", key: "L" }
            ]
        }
    ]
}
