pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau message", mods: "CTRL", key: "N", icon: "notch/edit-2.svg" },
                { label: "Relever les messages", mods: "", key: "F5", icon: "notch/refresh-cw.svg" },
                { separator: true },
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { separator: true },
                { label: "Fermer", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Quitter", mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Rétablir", mods: "CTRL SHIFT", key: "Z", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: "Recherche globale", mods: "CTRL", key: "K", icon: "notch/search.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Plein écran", mods: "", key: "F11", icon: "notch/maximize.svg" },
                { separator: true },
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Taille réelle", mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" }
            ]
        },
        {
            label: "Message",
            items: [
                { label: "Répondre", mods: "CTRL", key: "R", icon: "notch/corner-down-left.svg" },
                { label: "Répondre à tous", mods: "CTRL SHIFT", key: "R", icon: "notch/users.svg" },
                { label: "Transférer", mods: "CTRL", key: "L", icon: "notch/send.svg" },
                { separator: true },
                { label: "Archiver", mods: "", key: "A", icon: "notch/inbox.svg" },
                { label: "Marquer comme lu", mods: "", key: "M", icon: "notch/check-circle.svg" },
                { label: "Supprimer", mods: "", key: "Delete", icon: "notch/trash-2.svg" },
                { separator: true },
                { label: "Message suivant non lu", mods: "", key: "F", icon: "notch/skip-forward.svg" },
                { label: "Message précédent", mods: "", key: "B", icon: "notch/skip-back.svg" }
            ]
        }
    ]
}
