hl.config({
    input = {
        kb_layout = "no",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            tap_to_click = true,
            disable_while_typing = false,
        },
    },

    cursor = {
        hide_on_key_press = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
