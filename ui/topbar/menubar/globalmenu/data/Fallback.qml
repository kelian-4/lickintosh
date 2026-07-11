pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Fichier",
            items: [
                { label: "Fermer", mods: "CTRL", key: "W" },
                { label: "Quitter", mods: "CTRL", key: "Q" }
            ]
        },
        {
            label: "Édition",
            items: [
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { label: "Tout sélectionner", mods: "CTRL", key: "A" }
            ]
        }
    ]
}
