pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.ui.topbar.menubar.globalmenu.data

Item {
    id: root

    readonly property var currentToplevel: Hyprland.activeToplevel
    readonly property var currentWayland: root.currentToplevel ? root.currentToplevel.wayland : null
    readonly property bool hasWindow: root.currentToplevel !== null
    readonly property string appId: root.currentWayland ? (root.currentWayland.appId ? root.currentWayland.appId : "") : ""
    readonly property string category: root.classify(root.appId)
    readonly property list<var> menus: root.menusFor(root.category)

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            Hyprland.refreshToplevels()
        }
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "activewindow" || event.name === "activewindowv2") {
                Hyprland.refreshToplevels()
            }
        }
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    function classify(id) {
        if (!id) return "fallback"
        for (var i = 0; i < Categories.matchers.length; i++) {
            var m = Categories.matchers[i]
            var re = new RegExp(m.pattern, "i")
            if (re.test(id)) return m.category
        }
        return "fallback"
    }

    function menusFor(cat) {
        switch (cat) {
        case "browser": return Browser.menus
        case "vscode": return VsCode.menus
        case "ide": return Ide.menus
        case "terminal": return Terminal.menus
        case "filemanager": return FileManager.menus
        case "chat": return Chat.menus
        case "office": return Office.menus
        case "design": return Design.menus
        case "media": return Media.menus
        case "pdf": return Pdf.menus
        case "zathura": return Zathura.menus
        default: return Fallback.menus
        }
    }
}
