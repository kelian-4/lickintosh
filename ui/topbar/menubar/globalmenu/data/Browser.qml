pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouvel onglet", mods: "CTRL", key: "T" },
                { label: "Nouvelle fenêtre", mods: "CTRL", key: "N" },
                { label: "Fenêtre privée", mods: "CTRL SHIFT", key: "N" },
                { label: "Ouvrir fichier", mods: "CTRL", key: "O" },
                { separator: true },
                { label: "Fermer l'onglet", mods: "CTRL", key: "W" },
                { label: "Fermer la fenêtre", mods: "CTRL SHIFT", key: "W" },
                { separator: true },
                { label: "Enregistrer la page", mods: "CTRL", key: "S", disabled: true },
                { label: "Imprimer", mods: "CTRL", key: "P" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { label: "Rétablir", mods: "CTRL SHIFT", key: "Z", disabled: true },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Rechercher", mods: "CTRL", key: "F" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Recharger", mods: "CTRL", key: "R" },
                { separator: true },
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Taille réelle", mods: "CTRL", key: "0" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11" }
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
                { label: "Ajouter aux favoris", mods: "CTRL", key: "D" },
                { label: "Afficher les favoris", mods: "CTRL SHIFT", key: "O" }
            ]
        }
    ]
}
