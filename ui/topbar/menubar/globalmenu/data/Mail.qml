pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouveau message"), mods: "CTRL", key: "N", icon: "notch/edit-2.svg" },
                { label: I18n.tr("Relever les messages"), mods: "", key: "F5", icon: "notch/refresh-cw.svg" },
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
                { label: I18n.tr("Recherche globale"), mods: "CTRL", key: "K", icon: "notch/search.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Plein écran"), mods: "", key: "F11", icon: "notch/maximize.svg" },
                { separator: true },
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Taille réelle"), mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" }
            ]
        },
        {
            label: I18n.tr("Message"),
            items: [
                { label: I18n.tr("Répondre"), mods: "CTRL", key: "R", icon: "notch/corner-down-left.svg" },
                { label: I18n.tr("Répondre à tous"), mods: "CTRL SHIFT", key: "R", icon: "notch/users.svg" },
                { label: I18n.tr("Transférer"), mods: "CTRL", key: "L", icon: "notch/send.svg" },
                { separator: true },
                { label: I18n.tr("Archiver"), mods: "", key: "A", icon: "notch/inbox.svg" },
                { label: I18n.tr("Marquer comme lu"), mods: "", key: "M", icon: "notch/check-circle.svg" },
                { label: I18n.tr("Supprimer"), mods: "", key: "Delete", icon: "notch/trash-2.svg" },
                { separator: true },
                { label: I18n.tr("Message suivant non lu"), mods: "", key: "F", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Message précédent"), mods: "", key: "B", icon: "notch/skip-back.svg" }
            ]
        }
    ]
}
