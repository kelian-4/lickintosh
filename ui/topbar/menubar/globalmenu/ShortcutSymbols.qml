pragma Singleton
import QtQuick

QtObject {
    function keySymbol(key) {
        switch (key) {
        case "plus": return "+"
        case "minus": return "-"
        case "Left": return "←"
        case "Right": return "→"
        case "Up": return "↑"
        case "Down": return "↓"
        case "Delete": return "⌫"
        case "Return": return "⏎"
        case "Tab": return "⇥"
        case "space": return "Space"
        case "grave": return "`"
        case "slash": return "/"
        case "bar": return "|"
        case "Page_Down": return "Pg⇓"
        case "Page_Up": return "Pg⇑"
        default: return key
        }
    }

    function format(mods, key) {
        var out = ""
        var m = mods ? mods : ""
        if (m.indexOf("SUPER") !== -1) out += "❖"
        if (m.indexOf("ALT") !== -1) out += "⌥"
        if (m.indexOf("SHIFT") !== -1) out += "⇧"
        if (m.indexOf("CTRL") !== -1) out += "⌘"
        return out + keySymbol(key)
    }

    function formatChord(chord) {
        var parts = []
        for (var i = 0; i < chord.length; i++) {
            parts.push(format(chord[i].mods, chord[i].key))
        }
        return parts.join(" ")
    }
}
