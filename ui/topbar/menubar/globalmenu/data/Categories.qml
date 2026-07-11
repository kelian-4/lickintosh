pragma Singleton
import QtQuick

QtObject {
    property list<var> matchers: [
        { pattern: "firefox|chromium|brave-browser|zen|librewolf|Zen-alpha", category: "browser" },
        { pattern: "code|codium|vscode", category: "vscode" },
        { pattern: "jetbrains-.*|zed|neovide", category: "ide" },
        { pattern: "kitty|alacritty|foot|wezterm", category: "terminal" },
        { pattern: "nautilus|thunar|dolphin|nemo|pcmanfm", category: "filemanager" },
        { pattern: "vesktop|discord|Slack|TelegramDesktop", category: "chat" },
        { pattern: "libreoffice-.*|obsidian", category: "office" },
        { pattern: "Gimp-.*|blender|inkscape", category: "design" },
        { pattern: "mpv|vlc", category: "media" },
        { pattern: "Evince|org\.gnome\.Evince", category: "pdf" },
        { pattern: "zathura|org\.pwmt\.zathura", category: "zathura" }
    ]
}
