hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 6,
        border_size = 1,

        col = {
            active_border = "rgba(ffffff38)",
            inactive_border = "rgba(ffffff14)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",

        snap = {
            enabled = true,
            window_gap = 8,
            monitor_gap = 8,
            respect_gaps = true,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})
