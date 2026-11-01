local function floatCentered(match, width, height)
    hl.window_rule({
        match = match,
        float = true,
        center = true,
        size = { "monitor_w*" .. width, "monitor_h*" .. height },
    })
end

hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
    idle_inhibit = "fullscreen",
})

floatCentered({ title = "^(Open File|Open Folder|Select a File|Save As|File Upload).*$" }, 0.6, 0.65)
floatCentered({ title = "^.*(wants to save|wants to open)$" }, 0.6, 0.65)

floatCentered({ class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol|com\\.saivert\\.pwvucontrol)$" }, 0.45, 0.45)
floatCentered({ class = "^(nm-connection-editor|blueman-manager)$" }, 0.45, 0.45)

hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { "monitor_w*0.25", "monitor_h*0.25" },
    move = { "monitor_w*0.73", "monitor_h*0.72" },
})

hl.window_rule({
    match = { title = ".*is sharing (a window|your screen).*" },
    float = true,
    pin = true,
    move = { "monitor_w*0.5-window_w*0.5", "monitor_h-window_h-12" },
})

hl.window_rule({
    match = { xwayland = true, class = "^$", title = "^$" },
    no_blur = true,
    no_shadow = true,
})
