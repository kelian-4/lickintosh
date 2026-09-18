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

    // Cible courante de la selection : les grilles du bas appliquent au
    // bureau ou au lockscreen selon la vignette de preview active, plutot
    // que de dupliquer deux grilles identiques.
    property string activeTarget: "desktop"

    readonly property string shippedDir: Quickshell.shellDir + "/assets/wallpapers"
    readonly property string userDir: ShellConfig.options.spotlight.indexing.wallpaperDir

    property var shippedList: []
    property var userList: []

    // Meme contrainte que SpotlightWindow.qml : le quoting simple protege
    // les espaces (les noms livres en contiennent) mais bloque l'expansion
    // du ~, qu'on resout donc cote QML avant de quoter.
    function _safeShellPath(p) {
        var s = String(p)
        var home = Quickshell.env("HOME") || ""
        if (home !== "") {
            if (s === "~") s = home
            else if (s.indexOf("~/") === 0) s = home + s.slice(1)
        }
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    function _findCmd(dir) {
        return "find " + root._safeShellPath(dir) +
               " -maxdepth 2 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \\) " +
               "2>/dev/null | sort | head -60"
    }

    function _parse(text) {
        var lines = String(text).trim().split("\n")
        var out = []
        for (var i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i] !== "") out.push(lines[i])
        }
        return out
    }

    readonly property string currentPath: root.activeTarget === "lockscreen"
        ? ShellConfig.options.wallpaper.lockscreenPath
        : ShellConfig.options.wallpaper.path

    function apply(path) {
        if (root.activeTarget === "lockscreen") ShellConfig.options.wallpaper.lockscreenPath = path
        else ShellConfig.options.wallpaper.path = path
    }

    function applyRandom() {
        var all = root.shippedList.concat(root.userList)
        if (all.length === 0) return
        root.apply(all[Math.floor(Math.random() * all.length)])
    }

    // Le dossier livre avec le shell ne depend pas de la config : il peut
    // etre liste tout de suite. Le dossier utilisateur vient de
    // ShellConfig, donc on attend que le JSON soit lu (cf. ShellConfig
    // .ready, charge de facon asynchrone par FileView).
    Process {
        id: shippedProc
        running: true
        command: ["sh", "-c", root._findCmd(root.shippedDir)]
        stdout: StdioCollector { id: shippedOut }
        onExited: root.shippedList = root._parse(shippedOut.text)
    }

    Process {
        id: userProc
        running: false
        command: ["sh", "-c", root._findCmd(root.userDir)]
        stdout: StdioCollector { id: userOut }
        onExited: root.userList = root._parse(userOut.text)
    }

    function refreshUser() { if (ShellConfig.ready) userProc.running = true }

    Component.onCompleted: root.refreshUser()

    Connections {
        target: ShellConfig
        function onReadyChanged() { root.refreshUser() }
    }

    // Le dossier peut etre change depuis la page Spotlight sans quitter
    // l'app Settings : on relance le scan quand il bouge.
    onUserDirChanged: root.refreshUser()

    // ---------------------------------------------------------------
    // Previsualisation : bureau et ecran de verrouillage
    // ---------------------------------------------------------------
    ContentSection {
        title: "Aperçu"

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: [
                    { key: "desktop",    label: "Bureau" },
                    { key: "lockscreen", label: "Écran de verrouillage" }
                ]

                delegate: ColumnLayout {
                    id: _preview
                    required property var modelData
                    spacing: 6

                    readonly property bool isActive: root.activeTarget === _preview.modelData.key
                    readonly property string shownPath: _preview.modelData.key === "lockscreen"
                        ? ShellConfig.options.wallpaper.lockscreenPath
                        : ShellConfig.options.wallpaper.path

                    Item {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 116

                        CFClippingRect {
                            anchors.fill: parent
                            radius: 10
                            color: "#25000000"

                            Image {
                                anchors.fill: parent
                                source: _preview.shownPath !== "" ? "file://" + _preview.shownPath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(400, 232)
                            }

                            CFText {
                                anchors.centerIn: parent
                                text: "Aucun fond d'écran"
                                font.pixelSize: 12
                                gray: true
                                visible: _preview.shownPath === ""
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: 12
                            color: "transparent"
                            border.width: 2
                            border.color: "#1C7AFF"
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
                ? "La sélection ci-dessous s'applique à l'écran de verrouillage."
                : "La sélection ci-dessous s'applique au bureau."
            font.pixelSize: 12
            gray: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Meme pattern que le bouton "Options..." de BluetoothPage.qml
            // et le bouton "OK" bleu de WifiPage.qml : le Button {} de
            // QtQuick.Controls n'est utilise nulle part ailleurs dans le
            // repo et rend un gris plat generique hors charte.
            Rectangle {
                id: _randomBtn
                Layout.preferredWidth: 96
                Layout.preferredHeight: 28
                radius: 7
                opacity: _randomBtn.enabled ? 1 : 0.4
                enabled: root.shippedList.length + root.userList.length > 0
                color: _randomMouse.containsMouse ? Qt.rgba(0.15, 0.51, 1, 1) : "#1C7AFF"
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Aléatoire"
                    font.pixelSize: 12
                    color: "#fff"
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

            // Uniquement pour le lockscreen : la valeur vide y a un sens
            // defini (retour au wallpaper livre, cf. LockContext.qml).
            // Cote bureau elle ne donnerait qu'un fond noir, aussitot
            // reecrase par le fallback de wallProc au scan suivant.
            Rectangle {
                id: _resetBtn
                Layout.preferredWidth: 172
                Layout.preferredHeight: 28
                radius: 7
                visible: root.activeTarget === "lockscreen"
                opacity: _resetBtn.enabled ? 1 : 0.4
                enabled: root.currentPath !== ""
                color: _resetMouse.containsMouse ? "#22ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                CFText {
                    anchors.centerIn: parent
                    text: "Revenir au fond par défaut"
                    font.pixelSize: 12
                    color: "#fff"
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

    // ---------------------------------------------------------------
    // Grilles de selection
    // ---------------------------------------------------------------
    ContentSection {
        title: "Fournis avec le shell"

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.shippedList

                delegate: WallpaperThumb {
                    required property string modelData
                    path: modelData
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
        title: "Vos photos"

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.userList

                delegate: WallpaperThumb {
                    required property string modelData
                    path: modelData
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

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
