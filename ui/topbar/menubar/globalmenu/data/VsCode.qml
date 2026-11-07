pragma Singleton
import QtQuick
import qs.services

QtObject {
    property var menus: [
        {
            label: I18n.tr("Fichier"),
            items: [
                { label: I18n.tr("New Text File"), mods: "CTRL", key: "N", icon: "notch/plus.svg" },
                { label: I18n.tr("New File..."), mods: "CTRL ALT SUPER", key: "N", icon: "notch/plus.svg" },
                { label: I18n.tr("New Window"), mods: "CTRL SHIFT", key: "N", icon: "notch/layout.svg" },
                { label: I18n.tr("New Window with Profile"), disabled: true },
                { separator: true },
                { label: I18n.tr("Open File..."), mods: "CTRL", key: "O", icon: "notch/folder.svg" },
                { label: I18n.tr("Open Folder..."), chord: [ { mods: "CTRL", key: "K" }, { mods: "CTRL", key: "O" } ] },
                { label: I18n.tr("Open Workspace from File..."), disabled: true },
                { label: I18n.tr("Open Recent"), disabled: true },
                { separator: true },
                { label: I18n.tr("Add Folder to Workspace..."), disabled: true },
                { label: I18n.tr("Save Workspace As..."), disabled: true },
                { label: I18n.tr("Duplicate Workspace"), disabled: true },
                { separator: true },
                { label: I18n.tr("Save"), mods: "CTRL", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Save As..."), mods: "CTRL SHIFT", key: "S", icon: "notch/save.svg" },
                { label: I18n.tr("Save All"), disabled: true },
                { separator: true },
                { label: I18n.tr("Share"), disabled: true },
                { separator: true },
                { label: I18n.tr("Auto Save"), disabled: true },
                {
                    label: I18n.tr("Preferences"),
                    submenu: [
                        { label: I18n.tr("Settings"), mods: "CTRL", key: "comma", icon: "notch/settings.svg" },
                        { label: I18n.tr("Extensions"), mods: "CTRL SHIFT", key: "X", icon: "notch/package.svg" },
                        { label: I18n.tr("Keyboard Shortcuts"), chord: [ { mods: "CTRL", key: "K" }, { mods: "CTRL", key: "S" } ] },
                        { separator: true },
                        { label: I18n.tr("Profiles"), disabled: true },
                        { label: I18n.tr("Turn on Settings Sync..."), disabled: true }
                    ]
                },
                { separator: true },
                { label: I18n.tr("Revert File"), disabled: true },
                { label: I18n.tr("Close Editor"), mods: "CTRL", key: "W", icon: "notch/x.svg" },
                { label: I18n.tr("Close Folder"), chord: [ { mods: "CTRL", key: "K" }, { mods: "", key: "F" } ] },
                { label: I18n.tr("Close Window"), mods: "ALT", key: "F4", icon: "notch/x.svg" },
                { separator: true },
                { label: I18n.tr("Exit"), mods: "CTRL", key: "Q", icon: "notch/power.svg" }
            ]
        },
        {
            label: I18n.tr("Édition"),
            items: [
                { label: I18n.tr("Undo"), mods: "CTRL", key: "Z", icon: "notch/rotate-ccw.svg" },
                { label: I18n.tr("Redo"), mods: "CTRL", key: "Y", icon: "notch/rotate-cw.svg" },
                { separator: true },
                { label: I18n.tr("Cut"), mods: "CTRL", key: "X", icon: "notch/crop.svg" },
                { label: I18n.tr("Copy"), mods: "CTRL", key: "C", icon: "notch/copy.svg" },
                { label: I18n.tr("Paste"), mods: "CTRL", key: "V", icon: "notch/clipboard.svg" },
                { separator: true },
                { label: I18n.tr("Find"), mods: "CTRL", key: "F", icon: "notch/search.svg" },
                { label: I18n.tr("Replace"), mods: "CTRL", key: "H", icon: "notch/refresh-cw.svg" },
                { separator: true },
                { label: I18n.tr("Find in Files"), mods: "CTRL SHIFT", key: "F", icon: "notch/search.svg" },
                { label: I18n.tr("Replace in Files"), mods: "CTRL SHIFT", key: "H", icon: "notch/refresh-cw.svg" },
                { separator: true },
                { label: I18n.tr("Toggle Line Comment"), mods: "CTRL SHIFT", key: "7", icon: "notch/code.svg" },
                { label: I18n.tr("Toggle Block Comment"), mods: "CTRL SHIFT", key: "A", icon: "notch/code.svg" },
                { label: I18n.tr("Emmet: Expand Abbreviation"), mods: "", key: "Tab", icon: "notch/code.svg" }
            ]
        },
        {
            label: I18n.tr("Sélection"),
            items: [
                { label: I18n.tr("Select All"), mods: "CTRL", key: "A", icon: "notch/check.svg" },
                { label: I18n.tr("Expand Selection"), mods: "SHIFT ALT", key: "Right", icon: "notch/check.svg" },
                { label: I18n.tr("Shrink Selection"), mods: "SHIFT ALT", key: "Left", icon: "notch/check.svg" },
                { separator: true },
                { label: I18n.tr("Copy Line Up"), mods: "CTRL SHIFT ALT", key: "Up", icon: "notch/copy.svg" },
                { label: I18n.tr("Copy Line Down"), mods: "CTRL SHIFT ALT", key: "Down", icon: "notch/copy.svg" },
                { label: I18n.tr("Move Line Up"), mods: "ALT", key: "Up", icon: "notch/move.svg" },
                { label: I18n.tr("Move Line Down"), mods: "ALT", key: "Down", icon: "notch/move.svg" },
                { label: I18n.tr("Duplicate Selection"), disabled: true },
                { separator: true },
                { label: I18n.tr("Add Cursor Above"), mods: "SHIFT ALT", key: "Up", icon: "notch/plus-circle.svg" },
                { label: I18n.tr("Add Cursor Below"), mods: "SHIFT ALT", key: "Down", icon: "notch/plus-circle.svg" },
                { label: I18n.tr("Add Cursors to Line Ends"), mods: "SHIFT ALT", key: "I", icon: "notch/plus-circle.svg" },
                { label: I18n.tr("Add Next Occurrence"), mods: "CTRL", key: "D", icon: "notch/plus-circle.svg" },
                { label: I18n.tr("Add Previous Occurrence"), disabled: true },
                { label: I18n.tr("Select All Occurrences"), mods: "CTRL SHIFT", key: "L", icon: "notch/check.svg" },
                { separator: true },
                { label: I18n.tr("Switch to Ctrl+Click for Multi-Cursor"), disabled: true },
                { label: I18n.tr("Column Selection Mode"), disabled: true }
            ]
        },
        {
            label: I18n.tr("Affichage"),
            items: [
                { label: I18n.tr("Command Palette..."), mods: "CTRL SHIFT", key: "P", icon: "notch/search.svg" },
                { label: I18n.tr("Open View..."), disabled: true },
                { separator: true },
                { label: I18n.tr("Appearance"), disabled: true },
                { label: I18n.tr("Editor Layout"), disabled: true },
                { separator: true },
                { label: I18n.tr("Explorer"), mods: "CTRL SHIFT", key: "E", icon: "notch/folder.svg" },
                { label: I18n.tr("Search"), mods: "CTRL SHIFT", key: "F", icon: "notch/search.svg" },
                { label: I18n.tr("Source Control"), mods: "CTRL SHIFT", key: "G", icon: "notch/git-commit.svg" },
                { label: I18n.tr("Run"), mods: "CTRL SHIFT", key: "D", icon: "notch/play.svg" },
                { label: I18n.tr("Extensions"), mods: "CTRL SHIFT", key: "X", icon: "notch/package.svg" },
                { label: I18n.tr("Testing"), disabled: true },
                { separator: true },
                { label: I18n.tr("Chat"), mods: "CTRL ALT", key: "I", icon: "notch/message-square.svg" },
                { label: I18n.tr("Browser"), mods: "CTRL SHIFT ALT", key: "7", icon: "notch/globe.svg" },
                { separator: true },
                { label: I18n.tr("Problems"), mods: "CTRL SHIFT", key: "M", icon: "notch/alert-triangle.svg" },
                { label: I18n.tr("Output"), chord: [ { mods: "CTRL", key: "K" }, { mods: "CTRL", key: "H" } ] },
                { label: I18n.tr("Debug Console"), mods: "CTRL SHIFT", key: "Y", icon: "notch/tool.svg" },
                { label: I18n.tr("Terminal"), mods: "CTRL SHIFT", key: "grave", icon: "notch/terminal.svg" },
                { separator: true },
                { label: I18n.tr("Word Wrap"), mods: "ALT", key: "Z", icon: "notch/type.svg" }
            ]
        },
        {
            label: I18n.tr("Aller à"),
            items: [
                { label: I18n.tr("Back"), mods: "CTRL ALT", key: "minus", icon: "notch/corner-down-left.svg" },
                { label: I18n.tr("Forward"), mods: "CTRL SHIFT", key: "minus", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Last Edit Location"), disabled: true },
                { separator: true },
                { label: I18n.tr("Switch Editor"), disabled: true },
                { label: I18n.tr("Switch Group"), disabled: true },
                { separator: true },
                { label: I18n.tr("Go to File..."), mods: "CTRL", key: "P", icon: "notch/search.svg" },
                { label: I18n.tr("Go to Symbol in Workspace..."), mods: "CTRL", key: "T", icon: "notch/search.svg" },
                { label: I18n.tr("Go to Symbol in Editor..."), mods: "CTRL SHIFT", key: "O", icon: "notch/search.svg" },
                { label: I18n.tr("Go to Definition"), mods: "", key: "F12", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Go to Declaration"), disabled: true },
                { label: I18n.tr("Go to Type Definition"), disabled: true },
                { label: I18n.tr("Go to Implementations"), mods: "CTRL", key: "F12", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Go to References"), mods: "SHIFT", key: "F12", icon: "notch/corner-down-right.svg" },
                { separator: true },
                { label: I18n.tr("Go to Line/Column..."), mods: "CTRL", key: "G", icon: "notch/corner-down-right.svg" },
                { label: I18n.tr("Go to Bracket"), mods: "CTRL", key: "bar", icon: "notch/corner-down-right.svg" },
                { separator: true },
                { label: I18n.tr("Next Problem"), mods: "", key: "F8", icon: "notch/alert-triangle.svg" },
                { label: I18n.tr("Previous Problem"), mods: "SHIFT", key: "F8", icon: "notch/alert-triangle.svg" },
                { separator: true },
                { label: I18n.tr("Next Change"), mods: "ALT", key: "F3", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Previous Change"), mods: "SHIFT ALT", key: "F3", icon: "notch/skip-back.svg" }
            ]
        },
        {
            label: I18n.tr("Exécuter"),
            items: [
                { label: I18n.tr("Start Debugging"), mods: "", key: "F5", icon: "notch/tool.svg" },
                { label: I18n.tr("Run Without Debugging"), mods: "CTRL", key: "F5", icon: "notch/tool.svg" },
                { label: I18n.tr("Stop Debugging"), mods: "SHIFT", key: "F5", icon: "notch/tool.svg" },
                { label: I18n.tr("Restart Debugging"), mods: "CTRL SHIFT", key: "F5", icon: "notch/tool.svg" },
                { separator: true },
                { label: I18n.tr("Open Configurations"), disabled: true },
                { label: I18n.tr("Add Configuration..."), disabled: true },
                { separator: true },
                { label: I18n.tr("Step Over"), mods: "", key: "F10", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Step Into"), mods: "", key: "F11", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Step Out"), mods: "SHIFT", key: "F11", icon: "notch/skip-forward.svg" },
                { label: I18n.tr("Continue"), mods: "", key: "F5", icon: "notch/play.svg" },
                { separator: true },
                { label: I18n.tr("Toggle Breakpoint"), mods: "", key: "F9", icon: "notch/circle.svg" },
                { label: I18n.tr("New Breakpoint"), disabled: true },
                { separator: true },
                { label: I18n.tr("Enable All Breakpoints"), disabled: true },
                { label: I18n.tr("Disable All Breakpoints"), disabled: true },
                { label: I18n.tr("Remove All Breakpoints"), disabled: true },
                { separator: true },
                { label: I18n.tr("Install Additional Debuggers..."), disabled: true }
            ]
        },
        {
            label: I18n.tr("Terminal"),
            items: [
                { label: I18n.tr("New Terminal"), disabled: true },
                { label: I18n.tr("Split Terminal"), mods: "CTRL SHIFT", key: "5", icon: "notch/terminal.svg" },
                { label: I18n.tr("New Terminal Window"), disabled: true },
                { separator: true },
                { label: I18n.tr("Run Task..."), disabled: true },
                { label: I18n.tr("Run Build Task..."), mods: "CTRL SHIFT", key: "B", icon: "notch/play.svg" },
                { label: I18n.tr("Run Active File"), disabled: true },
                { label: I18n.tr("Run Selected Text"), disabled: true },
                { separator: true },
                { label: I18n.tr("Show Running Tasks..."), disabled: true },
                { label: I18n.tr("Restart Running Task..."), disabled: true },
                { label: I18n.tr("Terminate Task..."), disabled: true },
                { separator: true },
                { label: I18n.tr("Configure Tasks..."), disabled: true },
                { label: I18n.tr("Configure Default Build Task..."), disabled: true }
            ]
        },
        {
            label: I18n.tr("Help"),
            items: [
                { label: I18n.tr("Welcome"), disabled: true },
                { label: I18n.tr("Show All Commands"), mods: "CTRL SHIFT", key: "P", icon: "notch/sidebar.svg" },
                { label: I18n.tr("Documentation"), disabled: true },
                { label: I18n.tr("Editor Playground"), disabled: true },
                { label: I18n.tr("Open Walkthrough..."), disabled: true },
                { label: I18n.tr("Show Release Notes"), disabled: true },
                { label: I18n.tr("Get Started with Accessibility Features"), disabled: true },
                { label: I18n.tr("Ask @vscode"), disabled: true },
                { separator: true },
                { label: I18n.tr("Keyboard Shortcuts Reference"), chord: [ { mods: "CTRL", key: "K" }, { mods: "CTRL", key: "R" } ] },
                { label: I18n.tr("Video Tutorials"), disabled: true },
                { label: I18n.tr("Tips and Tricks"), disabled: true },
                { separator: true },
                { label: I18n.tr("Join Us on YouTube"), disabled: true },
                { label: I18n.tr("Search Feature Requests"), disabled: true },
                { label: I18n.tr("Report Issue"), disabled: true },
                { separator: true },
                { label: I18n.tr("View License"), disabled: true },
                { label: I18n.tr("Privacy Statement"), disabled: true },
                { separator: true },
                { label: I18n.tr("Toggle Developer Tools"), disabled: true },
                { label: I18n.tr("Open Process Explorer"), disabled: true },
                { separator: true },
                { label: I18n.tr("About"), disabled: true }
            ]
        }
    ]
}
