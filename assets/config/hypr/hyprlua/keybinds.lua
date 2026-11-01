local programs = require("hyprlua/programs")

local mainMod = "SUPER"

hl.bind(mainMod .. " + space", hl.dsp.global("quickshell:spotlight"))
hl.bind("CTRL + " .. mainMod .. " + Q", hl.dsp.global("lickintosh:lock"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind("ALT + " .. mainMod .. " + Escape", hl.dsp.exec_cmd("hyprctl kill"))

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(programs.codeEditor))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(programs.mediaPlayer))

hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next(), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }), { repeating = true })

local resizeStep = 40
local resizeDeltas = {
    left = { -resizeStep, 0 },
    right = { resizeStep, 0 },
    up = { 0, -resizeStep },
    down = { 0, resizeStep },
}

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    local delta = resizeDeltas[direction]
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
    hl.bind(
        mainMod .. " + ALT + " .. direction,
        hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }),
        { repeating = true }
    )
end

hl.bind(
    mainMod .. " + PRINT",
    hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +%F_%T).png | wl-copy]])
)
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("CTRL + " .. mainMod .. " + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + " .. mainMod .. " + right", hl.dsp.focus({ workspace = "e+1" }))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.on("config.reloaded", function()
    hl.dispatch(hl.dsp.submap("reset"))
end)
