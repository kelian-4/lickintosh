pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Fermer"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Quitter"), mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" }
            ]
        }
    ]
}
