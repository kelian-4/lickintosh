pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvel onglet", mods: "CTRL", key: "T", icon: "notch/plus-square.svg" },
                { label: "Nouvelle fenêtre", mods: "CTRL", key: "N", icon: "notch/layout.svg" },
                { label: "Fenêtre privée", mods: "CTRL SHIFT", key: "N", icon: "notch/eye-off.svg" },
                { label: "Ouvrir fichier", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { separator: true },
                { label: "Fermer l'onglet", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Fermer la fenêtre", mods: "CTRL SHIFT", key: "W", icon: "notch/x.svg" },
                { separator: true },
                { label: "Enregistrer la page", mods: "CTRL", key: "S", disabled: true, icon: "notch/save.svg" },
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Rétablir", mods: "CTRL SHIFT", key: "Z", disabled: true, icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Recharger", mods: "CTRL", key: "R", icon: "notch/refresh-cw.svg" },
                { separator: true },
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Taille réelle", mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        },
        {
            label: "Historique",
            items: [
                { label: "Afficher tout l'historique", mods: "CTRL", key: "H", icon: "notch/clock.svg" },
                { separator: true },
                { label: "Précédent", mods: "ALT", key: "Left", icon: "chevron-left.svg" },
                { label: "Suivant", mods: "ALT", key: "Right", icon: "chevron-right.svg" },
                { label: "Accueil", mods: "ALT", key: "Home", icon: "notch/home.svg" },
                { label: "Résultats de recherche", mods: "", key: "", disabled: true, icon: "search.svg" },
                { separator: true },
                { label: "Onglets récemment fermés", mods: "", key: "", disabled: true, icon: "notch/x.svg" },
                { label: "Rouvrir l'onglet fermé", mods: "CTRL SHIFT", key: "T", icon: "notch/folder.svg" },
                { label: "Rouvrir la session", mods: "", key: "", disabled: true, icon: "notch/layers.svg" }
            ]
        },
        {
            label: "Favoris",
            items: [
                { label: "Ajouter aux favoris", mods: "CTRL", key: "D", icon: "notch/plus.svg" },
                { label: "Afficher les favoris", mods: "CTRL SHIFT", key: "O", icon: "notch/eye.svg" }
            ]
        }
    ]
}
