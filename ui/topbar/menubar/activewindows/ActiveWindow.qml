import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Text {
    id: activeWindowText

    property string hostname: "Linux"
    readonly property var currentToplevel: Hyprland.activeToplevel
    readonly property var currentWayland: activeWindowText.currentToplevel ? activeWindowText.currentToplevel.wayland : null
    readonly property string currentAppId: activeWindowText.currentWayland ? (activeWindowText.currentWayland.appId ? activeWindowText.currentWayland.appId : "") : ""
    readonly property string currentTitle: activeWindowText.currentWayland ? (activeWindowText.currentWayland.title ? activeWindowText.currentWayland.title : "") : ""
    property string appName: formatName(currentAppId, currentTitle)

    Process {
        id: hostnameProc
        command: ["hostname", "-s"]
        running: true
        stdout: SplitParser {
            onRead: data => hostname = data.trim()
        }
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            Hyprland.refreshToplevels()
        }
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "activewindow" || event.name === "activewindowv2") {
                Hyprland.refreshToplevels()
            }
        }
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    function findCommonWord(classStr, titleStr) {
        if (!classStr || !titleStr) return null

        const classWords = classStr.toLowerCase().split(/[\s_.-]+/)
        const titleWords = titleStr.toLowerCase().split(/[\s_.-]+/)

        const common = classWords.filter(word =>
        word.length > 1 && titleWords.includes(word)
        )

        return common.length > 0 ? common[0] : null
    }

    function formatName(winClass, winTitle) {
        if (!winClass && !winTitle) return activeWindowText.hostname

        const commonWord = activeWindowText.findCommonWord(winClass, winTitle)
        if (commonWord) {
            return commonWord.charAt(0).toUpperCase() + commonWord.slice(1)
        }

        let targetName = ""

        if (winClass && winClass !== "") {
            targetName = winClass.charAt(0).toUpperCase() + winClass.slice(1)
        } else if (winTitle && winTitle !== "") {
            let segments = winTitle.split(/[-·]/)
            targetName = segments[segments.length - 1].trim()
        }

        return targetName === "" ? activeWindowText.hostname : targetName
    }

    text: appName
    color: "#FFFFFF"
    font.pixelSize: 14
    font.bold: true
    renderType: Text.NativeRendering
}
