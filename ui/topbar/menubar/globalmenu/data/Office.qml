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
                { label: I18n.tr("Imprimer"), mods: "CTRL", key: "P", icon: "notch/file-text.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Rétablir"), mods: "CTRL", key: "Y", icon: "notch/rotate-cw.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "F", icon: "notch/search.svg" }
            ]
        },
        {
            label: I18n.tr("Insertion"),
            items: [
                { label: I18n.tr("Lien"), mods: "CTRL", key: "K", icon: "notch/link.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" }
            ]
        }
    ]
}
