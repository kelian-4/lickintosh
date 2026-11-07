pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouveau"), mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: I18n.tr("Nouvelle fenêtre"), mods: "CTRL SHIFT", key: "N", icon: "notch/layout.svg" },
                { label: I18n.tr("Ouvrir"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { separator: true },
                { label: I18n.tr("Enregistrer"), mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Enregistrer sous"), mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { separator: true },
                { label: I18n.tr("Imprimer"), mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { separator: true },
                { label: I18n.tr("Fermer"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Quitter"), mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Rétablir"), mods: "CTRL SHIFT", key: "Z", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: I18n.tr("Couper"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: I18n.tr("Remplacer"), mods: "CTRL", key: "H", icon: "notch/refresh-cw.svg" },
                { label: I18n.tr("Aller à la ligne"), mods: "CTRL", key: "G", icon: "notch/corner-down-right.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Taille réelle"), mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: I18n.tr("Plein écran"), mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        }
    ]
}
