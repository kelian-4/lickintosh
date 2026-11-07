pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouvel onglet"), mods: "CTRL SHIFT", key: "T", icon: "notch/plus-square.svg" },
                { label: I18n.tr("Nouvelle fenêtre"), mods: "CTRL SHIFT", key: "N", icon: "notch/layout.svg" },
                { label: I18n.tr("Fermer l'onglet"), mods: "CTRL SHIFT", key: "W", icon: "notch/x.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Copier"), mods: "CTRL SHIFT", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL SHIFT", key: "V", icon: "notch/clipboard.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL SHIFT", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Zoom avant"), mods: "CTRL SHIFT", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Réinitialiser zoom"), mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { label: I18n.tr("Plein écran"), mods: "", key: "F11", icon: "notch/maximize.svg" }
            ]
        }
    ]
}
