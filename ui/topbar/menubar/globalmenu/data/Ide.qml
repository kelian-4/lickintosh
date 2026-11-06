pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Nouveau fichier"), mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: I18n.tr("Ouvrir"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: I18n.tr("Ouvrir dossier"), mods: "CTRL", key: "K", icon: "notch/folder.svg" },
                { label: I18n.tr("Enregistrer"), mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Enregistrer sous"), mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Fermer l'onglet"), mods: "CTRL", key: "W", icon: "notch/x.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Annuler"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Rétablir"), mods: "CTRL", key: "Y", icon: "notch/rotate-cw.svg" },
                { label: I18n.tr("Couper"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Copier"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Coller"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: I18n.tr("Rechercher"), mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: I18n.tr("Remplacer"), mods: "CTRL", key: "H", icon: "notch/refresh-cw.svg" }
            ]
        },
        {
            label: I18n.tr("Sélection"),
            items: [
                { label: I18n.tr("Tout sélectionner"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Sélection suivante"), mods: "CTRL", key: "D", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Développer la sélection"), mods: "SHIFT ALT", key: "Right", icon: "notch/check.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Palette de commandes"), mods: "CTRL SHIFT", key: "P", icon: "notch/search.svg" },
                { label: I18n.tr("Explorateur"), mods: "CTRL SHIFT", key: "E", icon: "notch/folder.svg" },
                { label: I18n.tr("Terminal intégré"), mods: "CTRL", key: "grave", icon: "notch/terminal.svg" },
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" }
            ]
        },
        {
            label: I18n.tr("Aller à"),
            items: [
                { label: I18n.tr("Aller au fichier"), mods: "CTRL", key: "P", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Aller à la ligne"), mods: "CTRL", key: "G", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Aller à la définition"), mods: "", key: "F12", icon: "notch/corner-down-right.svg" }
            ]
        },
        {
            label: I18n.tr("Exécuter"),
            items: [
                { label: I18n.tr("Démarrer le débogage"), mods: "", key: "F5", icon: "notch/tool.svg" },
                { label: I18n.tr("Exécuter sans débogage"), mods: "CTRL", key: "F5", icon: "notch/tool.svg" },
                { label: I18n.tr("Arrêter"), mods: "SHIFT", key: "F5", icon: "notch/stop-circle.svg" }
            ]
        }
    ]
}
