import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io   

Text {
    id: activeWindowText

    // Récupère le hostname via une commande shell au démarrage
    property string hostname: "Mac"
    property string appName: hostname

    Process {
        id: hostnameProc
        command: ["hostname", "-s"]  // -s = short hostname sans le domaine
        running: true
        stdout: SplitParser {
            onRead: data => hostname = data.trim()
        }
    }

    function formatName(winClass, winTitle) {
        if (!winClass && !winTitle) return hostname;

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