pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Ouvrir"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: I18n.tr("Copier l'image"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Enregistrer sous"), mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Imprimer"), mods: "CTRL", key: "P", icon: "notch/file-text.svg" },
                { separator: true },
                { label: I18n.tr("Fermer"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Quitter"), mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: I18n.tr("Image"),
            items: [
                { label: I18n.tr("Pivoter à gauche"), mods: "CTRL", key: "Left", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Pivoter à droite"), mods: "CTRL", key: "Right", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: I18n.tr("Définir comme fond d'écran"), mods: "", key: "", disabled: true, icon: "notch/image.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Zoom avant"), mods: "CTRL", key: "plus", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "CTRL", key: "minus", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Taille réelle"), mods: "CTRL", key: "1", icon: "notch/maximize-2.svg" },
                { label: I18n.tr("Ajuster à la fenêtre"), mods: "CTRL", key: "0", icon: "notch/maximize-2.svg" },
                { separator: true },
                { label: I18n.tr("Plein écran"), mods: "", key: "F11", icon: "notch/maximize.svg" },
                { label: I18n.tr("Diaporama"), mods: "", key: "F5", icon: "notch/play-circle.svg" }
            ]
        },
        {
            label: I18n.tr("Aller à"),
            items: [
                { label: I18n.tr("Image précédente"), mods: "", key: "Left", icon: "notch/skip-back.svg" },
                { label: I18n.tr("Image suivante"), mods: "", key: "Right", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Première image"), mods: "", key: "Home", icon: "notch/image.svg" },
                { label: I18n.tr("Dernière image"), mods: "", key: "End", icon: "notch/image.svg" }
            ]
        }
    ]
}
