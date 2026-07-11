pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Zathura",
            items: [
                { label: "Rechercher", mods: "", key: "slash" },
                { label: "Page suivante", mods: "", key: "J" },
                { label: "Page précédente", mods: "", key: "K" },
                { label: "Aller à la fin", mods: "SHIFT", key: "G" },
                { label: "Zoom avant", mods: "", key: "I" },
                { label: "Zoom arrière", mods: "", key: "O" },
                { label: "Index", mods: "", key: "Tab" }
            ]
        }
    ]
}
