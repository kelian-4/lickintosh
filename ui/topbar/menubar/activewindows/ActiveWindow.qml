import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Text {
    id: activeWindowText

    property string hostname: "Linux"
    property string appName: hostname

    Process {
        id: hostnameProc
        command: ["hostname", "-s"]
        running: true
        stdout: SplitParser {
            onRead: data => hostname = data.trim()
        }
    }

    function findCommonWord(classStr, titleStr) {
        if (!classStr || !titleStr) return null;

        const classWords = classStr.toLowerCase().split(/[\s_.-]+/);
        const titleWords = titleStr.toLowerCase().split(/[\s_.-]+/);

        const common = classWords.filter(word =>
        word.length > 1 && titleWords.includes(word)
        );

        return common.length > 0 ? common[0] : null;
    }

    function formatName(winClass, winTitle) {
        if (!winClass && !winTitle) return hostname;

        const commonWord = findCommonWord(winClass, winTitle);
        if (commonWord) {
            return commonWord.charAt(0).toUpperCase() + commonWord.slice(1);
        }

        let targetName = "";

        if (winClass && winClass !== "") {
            targetName = winClass.charAt(0).toUpperCase() + winClass.slice(1);
        } else if (winTitle && winTitle !== "") {
            let segments = winTitle.split(/[-·]/);
            targetName = segments[segments.length - 1].trim();
        }

        return targetName === "" ? hostname : targetName;
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const window = Hyprland.activeToplevel?.wayland || null;
            appName = (window == null)
            ? hostname
            : formatName(window.appId, window.title);
        }
    }

    text: appName
    color: "#FFFFFF"
    font.pixelSize: 14
    font.bold: true
    renderType: Text.NativeRendering
}
