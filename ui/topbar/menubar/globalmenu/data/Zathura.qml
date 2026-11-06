pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Zathura"),
            items: [
                { label: I18n.tr("Rechercher"), mods: "", key: "slash", icon: "notch/search.svg" },
                { label: I18n.tr("Page suivante"), mods: "", key: "J", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Page précédente"), mods: "", key: "K", icon: "notch/skip-back.svg" },
                { label: I18n.tr("Aller à la fin"), mods: "SHIFT", key: "G", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Zoom avant"), mods: "", key: "I", icon: "notch/zoom-in.svg" },
                { label: I18n.tr("Zoom arrière"), mods: "", key: "O", icon: "notch/zoom-out.svg" },
                { label: I18n.tr("Index"), mods: "", key: "Tab", icon: "notch/list.svg" }
            ]
        }
    ]
}
