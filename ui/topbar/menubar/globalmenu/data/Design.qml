pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouveau"), mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: I18n.tr("Ouvrir"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: I18n.tr("Enregistrer"), mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Exporter"), mods: "CTRL SHIFT", key: "E", icon: "notch/save.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" }
            ]
        },
        {
            label: I18n.tr("Sélection"),
            items: [
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Désélectionner"), mods: "CTRL SHIFT", key: "A", icon: "notch/check.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Zoom avant"), mods: "", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Ajuster à la fenêtre"), mods: "SHIFT CTRL", key: "J", icon: "notch/maximize-2.svg" }
            ]
        }
    ]
}
