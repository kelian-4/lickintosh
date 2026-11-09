import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import qs.components.glass
import qs.ui.settings.widgets

ContentPage {
    id: root

    property string activeTarget: "desktop"

    readonly property string shippedDir: Quickshell.shellDir + "/assets/wallpapers"
    readonly property string userDir: ShellConfig.options.spotlight.indexing.wallpaperDir

    property var shippedList: []
    property var userList: []

    function _safeShellPath(p) {
        var s = String(p)
        var home = Quickshell.env("HOME") || ""
        if (home !== "") {
            if (s === "~") s = home
            else if (s.indexOf("~/") === 0) s = home + s.slice(1)
        }
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    function _findCmd(dir, listFile) {
        return "find " + root._safeShellPath(dir) +
               " -maxdepth 2 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \\) " +
               "2>/dev/null | sort | head -60 | tee " + root._safeShellPath(listFile)
    }

    function _parse(text) {
        var lines = String(text).trim().split("\n")
        var out = []
        for (var i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i] !== "") out.push(lines[i])
        }
        return out
    }

    function pathOf(target) {
        if (target === "lockscreen") return ShellConfig.options.wallpaper.lockscreenPath
        if (target === "desktopDark") return ShellConfig.options.wallpaper.pathDark
        if (target === "desktopLight") return ShellConfig.options.wallpaper.pathLight
        if (ShellConfig.options.wallpaper.videoPath !== "") return ""
        return ShellConfig.options.wallpaper.path
    }

    readonly property string currentPath: root.pathOf(root.activeTarget)

    function apply(path) {
        if (root.activeTarget === "lockscreen") ShellConfig.options.wallpaper.lockscreenPath = path
        else if (root.activeTarget === "desktopDark") ShellConfig.options.wallpaper.pathDark = path
        else if (root.activeTarget === "desktopLight") ShellConfig.options.wallpaper.pathLight = path
        else {
            ShellConfig.options.wallpaper.videoPath = ""
            ShellConfig.options.wallpaper.path = path
        }
    }

    function applyRandom() {
        var all = root.shippedList.concat(root.userList)
        if (all.length === 0) return
        root.apply(all[Math.floor(Math.random() * all.length)])
    }

    readonly property string thumbCacheDir: (Quickshell.env("HOME") || "") + "/.cache/quickshell/wallpaper-thumbs"
    readonly property string genScript: Quickshell.shellDir + "/tools/wallpaper-thumbs/generate.sh"

    function thumbPathFor(kind, index) {
        return root.thumbCacheDir + "/" + kind + "-" + index + ".jpg"
    }

    readonly property string shippedListFile: root.thumbCacheDir + "/shipped-list.txt"
    readonly property string userListFile: root.thumbCacheDir + "/user-list.txt"

    Process {
        id: shippedProc
        running: true
        command: ["sh", "-c", "mkdir -p " + root._safeShellPath(root.thumbCacheDir) + " && " + root._findCmd(root.shippedDir, root.shippedListFile)]
        stdout: StdioCollector { id: shippedOut }
        onExited: {
            root.shippedList = root._parse(shippedOut.text)

            shippedThumbProc.command = ["bash", root.genScript, root.shippedListFile, "shipped", root.thumbCacheDir]
            shippedThumbProc.running = true
        }
    }

    Process {
        id: userProc
        running: false
        command: ["sh", "-c", "mkdir -p " + root._safeShellPath(root.thumbCacheDir) + " && " + root._findCmd(root.userDir, root.userListFile)]
        stdout: StdioCollector { id: userOut }
        onExited: {
            root.userList = root._parse(userOut.text)
            userThumbProc.command = ["bash", root.genScript, root.userListFile, "user", root.thumbCacheDir]
            userThumbProc.running = true
        }
    }

    property int shippedThumbsGen: 0
    property int userThumbsGen: 0

    Process {
        id: shippedThumbProc
        onExited: root.shippedThumbsGen++
    }

    Process {
        id: userThumbProc
        onExited: root.userThumbsGen++
    }

    property var videoList: []

    Process {
        id: videoProc
        running: false
        command: ["sh", "-c",
            "find " + root._safeShellPath(root.userDir) + " " + root._safeShellPath(root.shippedDir) +
            " -maxdepth 2 -type f \\( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) 2>/dev/null | sort | head -60"]
        stdout: StdioCollector { id: videoOut }
        onExited: root.videoList = root._parse(videoOut.text)
    }

    function refreshUser() {
        if (!ShellConfig.ready) return
        userProc.running = true
        videoProc.running = true
    }

    Component.onCompleted: root.refreshUser()

    Connections {
        target: ShellConfig
        function onReadyChanged() { root.refreshUser() }
    }

    onUserDirChanged: root.refreshUser()

    ContentSection {
        title: I18n.tr("Aperçu")

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: [
                    { key: "desktop",    label: I18n.tr("Bureau") },
                    { key: "desktopLight", label: I18n.tr("Bureau (mode clair)") },
                    { key: "desktopDark", label: I18n.tr("Bureau (mode sombre)") },
                    { key: "lockscreen", label: I18n.tr("Écran de verrouillage") }
                ]

                delegate: ColumnLayout {
                    id: _preview
                    required property var modelData
                    spacing: 6

                    readonly property bool isActive: root.activeTarget === _preview.modelData.key
                    readonly property string shownPath: root.pathOf(_preview.modelData.key)

                    Item {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 87

                        CFClippingRect {
                            anchors.fill: parent
                            radius: 10
                            color: "#25000000"

                            Image {
                                anchors.fill: parent
                                source: _preview.shownPath !== "" ? "file://" + _preview.shownPath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(300, 174)
                            }

                            Loader {
                                anchors.fill: parent
                                active: _preview.modelData.key === "desktop" && ShellConfig.options.wallpaper.videoPath !== ""
                                source: "../../../components/VideoFrame.qml"
                                onLoaded: item.source = Qt.binding(function() { return ShellConfig.options.wallpaper.videoPath })
                            }

                            CFText {
                                anchors.centerIn: parent
                                text: I18n.tr("Aucun fond d'écran")
                                font.pixelSize: 12
                                gray: true
                                visible: _preview.shownPath === "" && !(_preview.modelData.key === "desktop" && ShellConfig.options.wallpaper.videoPath !== "")
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: 12
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                            visible: _preview.isActive
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTarget = _preview.modelData.key
                        }
                    }

                    CFText {
                        text: _preview.modelData.label
                        font.pixelSize: 12
                        font.weight: _preview.isActive ? Font.Bold : Font.Normal
                        gray: !_preview.isActive
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        CFText {
            text: root.activeTarget === "lockscreen"
                ? I18n.tr("La sélection ci-dessous s'applique à l'écran de verrouillage.")
                : (root.activeTarget === "desktopDark"
                    ? I18n.tr("La sélection ci-dessous s'applique au bureau en mode sombre. Sans fond choisi ici, le fond du bureau est utilisé.")
                    : (root.activeTarget === "desktopLight"
                        ? I18n.tr("La sélection ci-dessous s'applique au bureau en mode clair. Sans fond choisi ici, le fond du bureau est utilisé.")
                        : I18n.tr("La sélection ci-dessous s'applique au bureau.")))
            font.pixelSize: 12
            gray: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: _randomBtn
                Layout.preferredWidth: 96
                Layout.preferredHeight: 28
                radius: 7
                opacity: _randomBtn.enabled ? 1 : 0.4
                enabled: root.shippedList.length + root.userList.length > 0
                color: _randomMouse.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: I18n.tr("Aléatoire")
                    font.pixelSize: 12
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: _randomMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: _randomBtn.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyRandom()
                }
            }

            Rectangle {
                id: _resetBtn
                Layout.preferredWidth: Math.max(172, _resetLabel.implicitWidth + 24)
                Layout.preferredHeight: 28
                radius: 7
                visible: root.activeTarget !== "desktop"
                opacity: _resetBtn.enabled ? 1 : 0.4
                enabled: root.currentPath !== ""
                color: _resetMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    id: _resetLabel
                    anchors.centerIn: parent
                    text: I18n.tr("Revenir au fond par défaut")
                    font.pixelSize: 12
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: _resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: _resetBtn.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.apply("")
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    ContentSection {
        title: I18n.tr("Fournis avec le shell")

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.shippedList

                delegate: WallpaperThumb {
                    id: _thumb
                    required property string modelData
                    required property int index
                    path: modelData
                    thumbPath: root.thumbPathFor("shipped", index)
                    thumbsGen: root.shippedThumbsGen
                    selected: root.currentPath === modelData
                    onClicked: root.apply(modelData)
                }
            }
        }

        CFText {
            text: "Aucune image dans " + root.shippedDir
            font.pixelSize: 12
            gray: true
            visible: root.shippedList.length === 0
            Layout.fillWidth: true
        }
    }

    ContentSection {
        title: I18n.tr("Vos photos")

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.userList

                delegate: WallpaperThumb {
                    id: _thumb
                    required property string modelData
                    required property int index
                    path: modelData
                    thumbPath: root.thumbPathFor("user", index)
                    thumbsGen: root.userThumbsGen
                    selected: root.currentPath === modelData
                    onClicked: root.apply(modelData)
                }
            }
        }

        CFText {
            text: root.userList.length === 0
                ? "Aucune image dans " + root.userDir + " — le dossier se règle dans Réglages > Spotlight."
                : "Dossier : " + root.userDir
            font.pixelSize: 12
            gray: true
            Layout.fillWidth: true
        }
    }

    ContentSection {
        title: I18n.tr("Fond animé")

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.videoList

                delegate: VideoThumb {
                    id: _video
                    required property string modelData
                    path: modelData
                    selected: ShellConfig.options.wallpaper.videoPath === modelData
                    onClicked: {
                        if (_video.selected) ShellConfig.options.wallpaper.videoPath = ""
                        else {
                            ShellConfig.options.wallpaper.videoPath = _video.modelData
                            root.activeTarget = "desktop"
                        }
                    }
                }
            }
        }

        CFText {
            text: I18n.tr("Aucune vidéo trouvée dans") + " " + root.userDir
            font.pixelSize: 12
            gray: true
            visible: root.videoList.length === 0
            Layout.fillWidth: true
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
