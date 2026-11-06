pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var supported: ["fr", "en", "es"]
    readonly property string setting: ShellConfig.options.general.language
    readonly property string detected: {
        var code = Qt.locale().name.split("_")[0].toLowerCase()
        return root.supported.indexOf(code) !== -1 ? code : "en"
    }
    readonly property string lang: root.supported.indexOf(root.setting) !== -1 ? root.setting : root.detected

    property var catalog: ({})

    function tr(text) {
        var c = root.catalog
        var v = c[text]
        return v !== undefined ? v : text
    }

    FileView {
        id: file
        path: Quickshell.shellPath("assets/i18n/" + root.lang + ".json")
        onLoaded: {
            try {
                root.catalog = JSON.parse(file.text())
            } catch (e) {
                root.catalog = ({})
            }
        }
        onLoadFailed: root.catalog = ({})
    }
}
