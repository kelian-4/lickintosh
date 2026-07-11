pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Édition",
            items: [
                { label: "Couper", mods: "CTRL", key: "X" },
                { label: "Copier", mods: "CTRL", key: "C" },
                { label: "Coller", mods: "CTRL", key: "V" },
                { label: "Rechercher", mods: "CTRL", key: "F" }
            ]
        },
        {
            label: "Affichage",
            items: [
                { label: "Zoom avant", mods: "CTRL", key: "plus" },
                { label: "Zoom arrière", mods: "CTRL", key: "minus" }
            ]
        }
    ]
}
