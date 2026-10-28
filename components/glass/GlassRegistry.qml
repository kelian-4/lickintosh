pragma Singleton
import Quickshell

Singleton {
    id: root

    property var entries: []
    property int revision: 0

    function register(win, backdrop) {
        if (!win || !backdrop)
            return
        var next = root.entries.filter(function(e) { return e.win !== win })
        next.push({ win: win, backdrop: backdrop })
        root.entries = next
        root.revision++
    }

    function unregister(backdrop) {
        root.entries = root.entries.filter(function(e) { return e.backdrop !== backdrop })
        root.revision++
    }

    function lookup(win) {
        var rev = root.revision
        if (!win || rev < 0)
            return null
        for (var i = 0; i < root.entries.length; i++) {
            if (root.entries[i].win === win)
                return root.entries[i].backdrop
        }
        return null
    }
}
