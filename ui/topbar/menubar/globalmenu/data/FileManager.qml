pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouvelle fenêtre"), mods: "CTRL", key: "N", icon: "notch/layout.svg" },
                { label: I18n.tr("Nouveau dossier"), mods: "CTRL SHIFT", key: "N", icon: "notch/folder-plus.svg" },
                { label: I18n.tr("Nouvel onglet"), mods: "CTRL", key: "T", icon: "notch/plus-square.svg" },
                { label: I18n.tr("Ouvrir"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: I18n.tr("Ouvrir avec"), mods: "", key: "", disabled: true, icon: "notch/file.svg" },
                { label: I18n.tr("Fermer la fenêtre"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { separator: true },
                { label: I18n.tr("Informations"), mods: "CTRL", key: "I", icon: "notch/info.svg" },
                { label: I18n.tr("Renommer"), mods: "", key: "F2", icon: "notch/edit.svg" },
                { label: I18n.tr("Dupliquer"), mods: "CTRL", key: "D", icon: "notch/copy.svg" },
                { label: I18n.tr("Aperçu rapide"), mods: "", key: "", disabled: true, icon: "notch/eye.svg" },
                { label: I18n.tr("Imprimer"), mods: "", key: "", disabled: true, icon: "notch/file-text.svg" },
                { separator: true },
                { label: I18n.tr("Partager"), mods: "", key: "", disabled: true, icon: "notch/share.svg" },
                { separator: true },
                { label: I18n.tr("Mettre à la corbeille"), mods: "", key: "Delete", icon: "notch/trash-2.svg" },
                { label: I18n.tr("Éjecter"), mods: "", key: "", disabled: true, icon: "notch/disc.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Couper"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Fichiers cachés"), mods: "CTRL", key: "H", icon: "notch/eye.svg" },
                { label: I18n.tr("Actualiser"), mods: "", key: "F5", icon: "notch/refresh-cw.svg" }
            ]
        },
        {
            label: I18n.tr("Aller à"),
            items: [
                { label: I18n.tr("Dossier personnel"), mods: "ALT", key: "Home", icon: "notch/home.svg" },
                { label: I18n.tr("Dossier parent"), mods: "ALT", key: "Up", icon: "notch/folder.svg" },
                { label: I18n.tr("Saisir un chemin"), mods: "CTRL", key: "L", icon: "notch/edit-3.svg" }
            ]
        }
    ]
}
