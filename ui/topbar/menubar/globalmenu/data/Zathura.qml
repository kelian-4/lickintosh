pragma Singleton
import QtQuick

QtObject {
    property list<var> menus: [
        {
            label: "Zathura",
            items: [
                { label: "Rechercher", mods: "", key: "slash", icon: "notch/search.svg" },
                { label: "Page suivante", mods: "", key: "J", icon: "notch/skip-forward.svg" },
                { label: "Page précédente", mods: "", key: "K", icon: "notch/skip-back.svg" },
                { label: "Aller à la fin", mods: "SHIFT", key: "G", icon: "notch/corner-down-right.svg" },
                { label: "Zoom avant", mods: "", key: "I", icon: "notch/zoom-in.svg" },
                { label: "Zoom arrière", mods: "", key: "O", icon: "notch/zoom-out.svg" },
                { label: "Index", mods: "", key: "Tab", icon: "notch/list.svg" }
            ]
        }
    ]
}
