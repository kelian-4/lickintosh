pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Fermer", mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: "Quitter", mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: "Coller", mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { label: "Tout sélectionner", mods: "CTRL", key: "A", icon: "notch/check.svg" }
            ]
        }
    ]
}
