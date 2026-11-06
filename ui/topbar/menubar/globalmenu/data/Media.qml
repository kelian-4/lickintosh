pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("Ouvrir fichier"), mods: "CTRL", key: "O", icon: "notch/file.svg" },
                { label: I18n.tr("Ouvrir URL"), mods: "CTRL", key: "U", icon: "notch/link.svg" }
            ]
        },
        {
            label: I18n.tr("Lecture"),
            items: [
                { label: I18n.tr("Lecture/Pause"), mods: "", key: "space", icon: "notch/play.svg" },
                { label: I18n.tr("Suivant"), mods: "", key: "N", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Précédent"), mods: "", key: "P", icon: "notch/skip-back.svg" },
                { label: I18n.tr("Muet"), mods: "", key: "M", icon: "notch/volume-x.svg" },
                { separator: true },
                { label: I18n.tr("Avancer"), mods: "", key: "Right", icon: "notch/fast-forward.svg" },
                { label: I18n.tr("Reculer"), mods: "", key: "Left", icon: "notch/rewind.svg" }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Plein écran"), mods: "", key: "F", icon: "notch/maximize.svg" },
                { label: I18n.tr("Sous-titres"), mods: "", key: "V", icon: "notch/type.svg" }
            ]
        }
    ]
}
