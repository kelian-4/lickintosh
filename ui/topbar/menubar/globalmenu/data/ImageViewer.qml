pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Ouvrir", mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: "Copier l'image", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Enregistrer sous", mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { label: "Imprimer", mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { separator: true },
                { label: "Fermer", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Quitter", mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: "Image",
            items: [
                { label: "Pivoter à gauche", mods: "CTRL", key: "Left", icon: "notch/rotate-ccw.svg" },
                { label: "Pivoter à droite", mods: "CTRL", key: "Right", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: "Définir comme fond d'écran", mods: "", key: "", disabled: true, icon: "notch/image.svg" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: "Taille réelle", mods: "CTRL", key: "1", icon: "notch/maximize-2.svg" },
                { label: "Ajuster à la fenêtre", mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: "Plein écran", mods: "", key: "F11", icon: "notch/maximize.svg" },
                { label: "Diaporama", mods: "", key: "F5", icon: "notch/play-circle.svg" }
            ]
        },
        {
            label: "Aller à",
            items: [
                { label: "Image précédente", mods: "", key: "Left", icon: "notch/skip-back.svg" },
                { label: "Image suivante", mods: "", key: "Right", icon: "notch/skip-forward.svg" },
                { label: "Première image", mods: "", key: "Home", icon: "notch/image.svg" },
                { label: "Dernière image", mods: "", key: "End", icon: "notch/image.svg" }
            ]
        }
    ]
}
