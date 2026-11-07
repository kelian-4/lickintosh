pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "K", icon: "notch/search.svg" },
                { separator: true },
                { label: I18n.tr("Fermer la fenêtre"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Quitter"), mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { separator: true },
                { label: I18n.tr("Couper"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "F", icon: "notch/search.svg" }
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
