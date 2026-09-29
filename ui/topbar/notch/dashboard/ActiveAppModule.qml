import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/*
    Remplace WeatherModule dans cette rangee du dashboard, a la demande
    explicite de l'utilisateur : affiche "le mode actuellement actif",
    c'est a dire l'application/fenetre active — comme le fait deja
    ui/topbar/menubar/activewindows/ActiveWindow.qml dans la topbar
    (indicateur style barre de menu macOS). Meme logique de detection
    reprise ici a l'identique (Hyprland.activeToplevel, formatage du nom
    via appId/titre, repli sur le hostname) plutot que d'en re-derbranler
    une plus simple : ce fichier existant est la logique de reference du
    projet pour "l'app active", pas question d'improviser autre chose.
*/
Rectangle {
    id: root
    color: "#1A1A1A"

    property string hostname: "Linux"
    readonly property var currentToplevel: Hyprland.activeToplevel
    readonly property var currentWayland: root.currentToplevel ? root.currentToplevel.wayland : null
    readonly property string currentAppId: root.currentWayland ? (root.currentWayland.appId ? root.currentWayland.appId : "") : ""
    readonly property string currentTitle: root.currentWayland ? (root.currentWayland.title ? root.currentWayland.title : "") : ""
    property string appName: formatName(currentAppId, currentTitle)

    Process {
        id: hostnameProc
        command: ["hostname", "-s"]
        running: true
        stdout: SplitParser {
            onRead: data => root.hostname = data.trim()
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
        const common = classWords.filter(word => word.length > 1 && titleWords.includes(word))
        return common.length > 0 ? common[0] : null
    }

    function formatName(winClass, winTitle) {
        if (!winClass && !winTitle) return root.hostname
        const commonWord = root.findCommonWord(winClass, winTitle)
        if (commonWord) return commonWord.charAt(0).toUpperCase() + commonWord.slice(1)
        let targetName = ""
        if (winClass && winClass !== "") {
            targetName = winClass.charAt(0).toUpperCase() + winClass.slice(1)
        } else if (winTitle && winTitle !== "") {
            let segments = winTitle.split(/[-·]/)
            targetName = segments[segments.length - 1].trim()
        }
        return targetName === "" ? root.hostname : targetName
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        VectorImage {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/layout.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: "#8AB4F8"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.appName
                color: "#FFFFFF"; font.pixelSize: 18; font.bold: true; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: "Application active"
                color: "#B0B0B0"; font.pixelSize: 11; font.family: "SF Pro Rounded"
                elide: Text.ElideRight
            }
        }
    }
}
