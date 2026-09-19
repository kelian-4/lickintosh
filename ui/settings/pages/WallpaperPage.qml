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

    function _findCmd(dir, listFile) {
        // Le tee vers listFile donne au script de generation un vrai
        // fichier de chemins bruts a lire (voir plus bas) : ecrire
        // cette liste directement depuis find/sort evite d'avoir a la
        // reserialiser cote QML avec un quoting a reconstruire.
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

    // ---------------------------------------------------------------
    // Cache de miniatures sur disque
    // ---------------------------------------------------------------
    // Certains fonds livres avec le shell font jusqu'a 6400x3600 / 12 Mo
    // (PNG, sans decodage progressif). Qt doit decompresser l'integralite
    // du fichier avant d'appliquer sourceSize : sur une grille de 20+
    // images affichees en meme temps, ca sature le pool de threads de
    // decodage asynchrone de Qt et la grille entiere met du temps a
    // s'afficher, meme si chaque vignette prise isolement decoderait
    // vite. On genere donc une fois de vraies miniatures sur disque (296
    // x164, meme pattern magick/convert + repli que LockContext.qml pour
    // le lockscreen), et les vignettes pointent vers ces fichiers legers
    // plutot que vers les originaux.
    //
    // Nommage par index plutot que par hash du chemin : plus simple, et
    // suffisant puisque l'index vient d'une liste triee (find | sort),
    // donc stable d'un scan a l'autre tant que le contenu du dossier ne
    // change pas. Deux sous-caches distincts (shipped/user) pour que les
    // indices des deux listes ne se percutent jamais.
    //
    // La generation elle-meme vit dans tools/wallpaper-thumbs/generate.sh
    // plutot que dans une commande recomposee ici : plusieurs tentatives
    // de construire cette commande comme une chaine JS (quoting imbrique,
    // base64 via Qt.btoa qui corrompt l'UTF-8 hors Latin1) se sont
    // averees fragiles a l'usage. Un vrai fichier .sh recoit ses
    // arguments proprement (argv, pas de re-echappement), et le fichier
    // de chemins qu'il lit est ecrit directement par `find | sort | tee`
    // (_findCmd ci-dessus), jamais reserialise cote QML.
    readonly property string thumbCacheDir: (Quickshell.env("HOME") || "") + "/.cache/quickshell/wallpaper-thumbs"
    readonly property string genScript: Quickshell.shellDir + "/tools/wallpaper-thumbs/generate.sh"

    function thumbPathFor(kind, index) {
        return root.thumbCacheDir + "/" + kind + "-" + index + ".jpg"
    }

    // Le dossier livre avec le shell ne depend pas de la config : il peut
    // etre liste tout de suite. Le dossier utilisateur vient de
    // ShellConfig, donc on attend que le JSON soit lu (cf. ShellConfig
    // .ready, charge de facon asynchrone par FileView).
    readonly property string shippedListFile: root.thumbCacheDir + "/shipped-list.txt"
    readonly property string userListFile: root.thumbCacheDir + "/user-list.txt"

    Process {
        id: shippedProc
        running: true
        command: ["sh", "-c", "mkdir -p " + root._safeShellPath(root.thumbCacheDir) + " && " + root._findCmd(root.shippedDir, root.shippedListFile)]
        stdout: StdioCollector { id: shippedOut }
        onExited: {
            root.shippedList = root._parse(shippedOut.text)
            // Args separes (argv), jamais une commande shell recomposee
            // en texte : le script lit lui-meme le fichier de chemins,
            // rien a re-echapper cote QML.
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

    // Compteurs incrementes quand un batch de generation termine : les
    // vignettes y sont liees pour re-verifier le cache une fois pret
    // (elles s'affichent d'abord depuis l'original le temps du batch,
    // voir WallpaperThumb.qml, puis basculent sur la miniature legere
    // sans que l'utilisateur ait besoin de rouvrir la page).
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
        title: "Vos photos"

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

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
