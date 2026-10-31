local programs = require("hyprlua/programs")

hl.env("XCURSOR_THEME", programs.cursor.theme)
hl.env("XCURSOR_SIZE", tostring(programs.cursor.size))
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
