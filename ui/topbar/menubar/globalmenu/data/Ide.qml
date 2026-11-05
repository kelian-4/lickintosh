pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau fichier", mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Ouvrir dossier", mods: "CTRL", key: "K", icon: "notch/folder.svg" },
                { label: "Enregistrer", mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { label: "Fermer l'onglet", mods: "CTRL", key: "W", icon: "notch/x.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: "Rétablir", mods: "CTRL", key: "Y", icon: "notch/rotate-cw.svg" },
                { label: "Couper", mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: "Rechercher", mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: "Remplacer", mods: "CTRL", key: "H", icon: "notch/refresh-cw.svg" }
            ]
        },
        {
            label: "Sélection",
            items: [
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: "Sélection suivante", mods: "CTRL", key: "D", icon: "notch/skip-forward.svg" },
                { label: "Développer la sélection", mods: "SHIFT ALT", key: "Right", icon: "notch/check.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Palette de commandes", mods: "CTRL SHIFT", key: "P", icon: "notch/search.svg" },
                { label: "Explorateur", mods: "CTRL SHIFT", key: "E", icon: "notch/folder.svg" },
                { label: "Terminal intégré", mods: "CTRL", key: "grave", icon: "notch/terminal.svg" },
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Aller au fichier", mods: "CTRL", key: "P", icon: "notch/corner-down-right.svg" },
                { label: "Aller à la ligne", mods: "CTRL", key: "G", icon: "notch/corner-down-right.svg" },
                { label: "Aller à la définition", mods: "", key: "F12", icon: "notch/corner-down-right.svg" }
            ]
        },
        {
            label: "Exécuter",
            items: [
                { label: "Démarrer le débogage", mods: "", key: "F5", icon: "notch/tool.svg" },
                { label: "Exécuter sans débogage", mods: "CTRL", key: "F5", icon: "notch/tool.svg" },
                { label: "Arrêter", mods: "SHIFT", key: "F5", icon: "notch/stop-circle.svg" }
            ]
        }
    ]
}
