pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir", mods: "CTRL", key: "O" },
                { label: "Copier l'image", mods: "CTRL", key: "C" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S" },
                { label: "Imprimer", mods: "CTRL", key: "P" },
                { separator: true },
                { label: "Fermer", mods: "CTRL", key: "W" },
                { label: "Quitter", mods: "CTRL", key: "Q" }
            ]
        },
        {
            label: "Image",
            items: [
                { label: "Pivoter à gauche", mods: "CTRL", key: "Left" },
                { label: "Pivoter à droite", mods: "CTRL", key: "Right" },
                { separator: true },
                { label: "Définir comme fond d'écran", mods: "", key: "", disabled: true }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" },
                { label: "Taille réelle", mods: "CTRL", key: "1" },
                { label: "Ajuster à la fenêtre", mods: "CTRL", key: "0" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11" },
                { label: "Diaporama", mods: "", key: "F5" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Image précédente", mods: "", key: "Left" },
                { label: "Image suivante", mods: "", key: "Right" },
                { label: "Première image", mods: "", key: "Home" },
                { label: "Dernière image", mods: "", key: "End" }
            ]
        }
    ]
}
