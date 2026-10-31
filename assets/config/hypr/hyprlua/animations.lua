hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("macOut", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("macIn", { type = "bezier", points = { { 0.32, 0 }, { 0.67, 0 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "macOut", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "macIn", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "macOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "macOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "macIn" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "macOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macOut", style = "slide" })

hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "fadeLayers", enabled = false })
