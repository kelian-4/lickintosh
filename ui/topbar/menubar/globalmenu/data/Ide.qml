pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Nouveau fichier", mods: "CTRL", key: "N" },
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { label: "Ouvrir dossier", mods: "CTRL", key: "K" },
                { label: "Enregistrer", mods: "CTRL", key: "S" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S" },
                { label: "Fermer l'onglet", mods: "CTRL", key: "W" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Annuler", mods: "CTRL", key: "Z" },
                { label: "Rétablir", mods: "CTRL", key: "Y" },
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { label: "Rechercher", mods: "CTRL", key: "F" },
                { label: "Remplacer", mods: "CTRL", key: "H" }
            ]
        },
        {
            label: "Sélection",
            items: [
                { label: "Tout sélectionner", mods: "CTRL", key: "A" },
                { label: "Sélection suivante", mods: "CTRL", key: "D" },
                { label: "Développer la sélection", mods: "SHIFT ALT", key: "Right" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Palette de commandes", mods: "CTRL SHIFT", key: "P" },
                { label: "Explorateur", mods: "CTRL SHIFT", key: "E" },
                { label: "Terminal intégré", mods: "CTRL", key: "grave" },
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Aller au fichier", mods: "CTRL", key: "P" },
                { label: "Aller à la ligne", mods: "CTRL", key: "G" },
                { label: "Aller à la définition", mods: "", key: "F12" }
            ]
        },
        {
            label: "Exécuter",
            items: [
                { label: "Démarrer le débogage", mods: "", key: "F5" },
                { label: "Exécuter sans débogage", mods: "CTRL", key: "F5" },
                { label: "Arrêter", mods: "SHIFT", key: "F5" }
            ]
        }
    ]
}
