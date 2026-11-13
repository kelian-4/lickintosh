local function firstAvailable(candidates)
    local parts = {}
    for i, cmd in ipairs(candidates) do
        local bin = cmd:match("^%S+")
        parts[#parts + 1] = (i == 1 and "if" or "elif") .. " command -v " .. bin .. " >/dev/null 2>&1; then exec " .. cmd
    end
    return table.concat(parts, "; ") .. "; fi"
end

return {
    terminal = firstAvailable({ "kitty", "foot", "alacritty", "wezterm", "ghostty", "konsole", "gnome-terminal", "xterm" }),
    fileManager = firstAvailable({ "dolphin", "nautilus", "thunar", "pcmanfm-qt", "pcmanfm", "nemo", "caja" }),
    browser = firstAvailable({ "helium", "zen-browser", "firefox", "brave", "google-chrome-stable", "chromium", "librewolf", "microsoft-edge-stable", "vivaldi", "opera" }),
    codeEditor = firstAvailable({ "code", "codium", "cursor", "zeditor", "zed", "kate", "gnome-text-editor", "gedit" }),
    mediaPlayer = firstAvailable({ "mpv", "vlc", "celluloid", "haruna", "totem" }),
    shell = "sh ~/.config/quickshell/lickintosh/tools/lickintosh-start",
    cursor = {
        theme = "MacOS-Tahoe-Cursor",
        size = 24,
    },
}
