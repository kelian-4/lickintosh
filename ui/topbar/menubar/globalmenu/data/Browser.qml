pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouvel onglet"), mods: "CTRL", key: "T", icon: "notch/plus-square.svg" },
                { label: I18n.tr("Nouvelle fenêtre"), mods: "CTRL", key: "N", icon: "notch/layout.svg" },
                { label: I18n.tr("Fenêtre privée"), mods: "CTRL SHIFT", key: "N", icon: "notch/eye-off.svg" },
                { label: I18n.tr("Ouvrir fichier"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { separator: true },
                { label: I18n.tr("Fermer l'onglet"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Fermer la fenêtre"), mods: "CTRL SHIFT", key: "W", icon: "notch/x.svg" },
                { separator: true },
                { label: I18n.tr("Enregistrer la page"), mods: "CTRL", key: "S", disabled: true, icon: "notch/save.svg" },
                { label: I18n.tr("Imprimer"), mods: "CTRL", key: "P", icon: "notch/file-text.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Rétablir"), mods: "CTRL SHIFT", key: "Z", disabled: true, icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: I18n.tr("Couper"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Recharger"), mods: "CTRL", key: "R", icon: "notch/refresh-cw.svg" },
                { separator: true },
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Taille réelle"), mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: I18n.tr("Plein écran"), mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        },
        {
            label: I18n.tr("Historique"),
            items: [
                { label: I18n.tr("Afficher tout l'historique"), mods: "CTRL", key: "H", icon: "notch/clock.svg" },
                { separator: true },
                { label: I18n.tr("Précédent"), mods: "ALT", key: "Left", icon: "chevron-left.svg" },
                { label: I18n.tr("Suivant"), mods: "ALT", key: "Right", icon: "chevron-right.svg" },
                { label: I18n.tr("Accueil"), mods: "ALT", key: "Home", icon: "notch/home.svg" },
                { label: I18n.tr("Résultats de recherche"), mods: "", key: "", disabled: true, icon: "search.svg" },
                { separator: true },
                { label: I18n.tr("Onglets récemment fermés"), mods: "", key: "", disabled: true, icon: "notch/x.svg" },
                { label: I18n.tr("Rouvrir l'onglet fermé"), mods: "CTRL SHIFT", key: "T", icon: "notch/folder.svg" },
                { label: I18n.tr("Rouvrir la session"), mods: "", key: "", disabled: true, icon: "notch/layers.svg" }
            ]
        },
        {
            label: I18n.tr("Favoris"),
            items: [
                { label: I18n.tr("Ajouter aux favoris"), mods: "CTRL", key: "D", icon: "notch/plus.svg" },
                { label: I18n.tr("Afficher les favoris"), mods: "CTRL SHIFT", key: "O", icon: "notch/eye.svg" }
            ]
        }
    ]
}
