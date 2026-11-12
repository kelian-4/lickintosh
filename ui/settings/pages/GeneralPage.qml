import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.ui.settings.widgets

Item {
    id: root

    anchors.fill: parent

    property string currentSubpage: ""

    readonly property var _rows: [
        { id: "about",     name: I18n.tr("Informations"),         icon: "settings/general.svg" },
        { id: "updates",   name: I18n.tr("Mises à jour logicielles"), icon: "settings/general.svg" },
        { id: "storage",   name: I18n.tr("Stockage"),              icon: "settings/general.svg" },
        { id: "datetime",  name: I18n.tr("Date et heure"),         icon: "settings/general.svg" },
        { id: "language",  name: I18n.tr("Langue et région"),      icon: "settings/general.svg" },
        { id: "login",     name: I18n.tr("Éléments de connexion"), icon: "settings/general.svg" }
    ]

    readonly property string _currentSubpageLabel: {
        for (var i = 0; i < root._rows.length; i++) {
            if (root._rows[i].id === root.currentSubpage) return root._rows[i].name
        }
        return ""
    }

    function _parseMemValue(str) {
        var match = str.match(/([0-9.]+)\s*([A-Za-z]*)/)
        if (!match) return 0
        var n = parseFloat(match[1])
        var unit = match[2].toUpperCase()
        if (unit.indexOf("G") === 0) return n * 1024
        if (unit.indexOf("T") === 0) return n * 1024 * 1024
        return n
    }

    readonly property real _memoryFraction: {
        var used = root._parseMemValue(GeneralState.memoryUsed)
        var total = root._parseMemValue(GeneralState.memoryTotal)
        if (total <= 0) return 0
        return Math.min(1, used / total)
    }

    ContentPage {
        id: _listPage
        anchors.fill: parent
        visible: root.currentSubpage === ""

        ContentSection {
            Repeater {
                model: root._rows

                Rectangle {
                    id: _row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 8
                    color: _rowMouse.containsMouse ? "#14ffffff" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 10

                        CFVI {
                            icon: _row.modelData.icon
                            size: 20
                            gray: true
                        }

                        CFText {
                            text: _row.modelData.name
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        CFVI {
                            icon: "chevron-right-bold.svg"
                            size: 12
                            gray: true
                        }
                    }

                    MouseArea {
                        id: _rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSubpage = _row.modelData.id
                    }
                }
            }
        }
    }

    Item {
        id: _subpageContainer
        anchors.fill: parent
        visible: root.currentSubpage !== ""

        RowLayout {
            id: _subpageHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: _backMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1

                CFVI {
                    anchors.centerIn: parent
                    icon: "chevron-left-bold.svg"
                    size: 12
                }

                MouseArea {
                    id: _backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentSubpage = ""
                }
            }

            CFText {
                text: root._currentSubpageLabel
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        ContentPage {
            anchors.top: _subpageHeader.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ContentSection {
                visible: root.currentSubpage === "about"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        Layout.alignment: Qt.AlignTop
                        radius: 12
                        color: "#18ffffff"

                        CFVI {
                            anchors.centerIn: parent
                            icon: "settings/general.svg"
                            size: 30
                            gray: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        CFText {
                            text: GeneralState.hostname.length > 0 ? GeneralState.hostname : I18n.tr("Inconnu")
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        CFText {
                            text: GeneralState.osName.length > 0 ? GeneralState.osName : I18n.tr("Système inconnu")
                            font.pixelSize: 13
                            gray: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            ContentSection {
                title: I18n.tr("Système")
                visible: root.currentSubpage === "about"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("OS")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.osName.length > 0 ? GeneralState.osName : I18n.tr("Inconnu")
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.machineModel.length > 0

                    CFText {
                        text: I18n.tr("Host")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.machineModel
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Noyau")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.kernelVersion.length > 0 ? GeneralState.kernelVersion : I18n.tr("Inconnu")
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.uptimePretty.length > 0

                    CFText {
                        text: I18n.tr("Uptime")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.uptimePretty
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.packageCounts.length > 0

                    CFText {
                        text: I18n.tr("Paquets")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: {
                            var parts = []
                            for (var i = 0; i < GeneralState.packageCounts.length; i++) {
                                var pkg = GeneralState.packageCounts[i]
                                parts.push(pkg.count + " (" + pkg.manager + ")")
                            }
                            return parts.join(", ")
                        }
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 300
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.shellName.length > 0

                    CFText {
                        text: I18n.tr("Shell")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.shellName
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.wmName.length > 0

                    CFText {
                        text: I18n.tr("WM")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.wmName + (GeneralState.hyprlandVersion.length > 0 ? " (" + GeneralState.hyprlandVersion + ")" : "")
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }
            }

            ContentSection {
                title: I18n.tr("Matériel")
                visible: root.currentSubpage === "about"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.cpuModel.length > 0

                    CFText {
                        text: I18n.tr("CPU")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.cpuModel
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 300
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.gpuModel.length > 0

                    CFText {
                        text: I18n.tr("GPU")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.gpuModel
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 300
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: GeneralState.memoryTotal.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        CFText {
                            text: I18n.tr("Mémoire")
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        CFText {
                            text: GeneralState.memoryUsed + " / " + GeneralState.memoryTotal
                            gray: true
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: "#18ffffff"

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: parent.width * root._memoryFraction
                            color: "#3478f6"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.swapTotal.length > 0

                    CFText {
                        text: I18n.tr("Swap")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.swapUsed + " / " + GeneralState.swapTotal
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.localIp.length > 0

                    CFText {
                        text: I18n.tr("IP locale")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.localIp
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.batteryPercent.length > 0

                    CFText {
                        text: I18n.tr("Batterie")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.batteryPercent + (GeneralState.batteryState.length > 0 ? " (" + GeneralState.batteryState + ")" : "")
                        gray: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 220
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.localeName.length > 0

                    CFText {
                        text: I18n.tr("Locale")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.localeName
                        gray: true
                        font.pixelSize: 13
                    }
                }
            }

            ContentSection {
                title: I18n.tr("Mises à jour logicielles")
                visible: root.currentSubpage === "updates"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("État")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    CFText {
                        text: {
                            if (GeneralState.packageManager === "" || GeneralState.packageManager === "unknown") return "Non disponible"
                            if (GeneralState.checkingUpdates) return "Vérification…"
                            if (GeneralState.updateCount < 0) return "Inconnu"
                            if (GeneralState.updateCount === 0) return "À jour"
                            return GeneralState.updateCount + " mise" + (GeneralState.updateCount > 1 ? "s" : "") + " à jour disponible" + (GeneralState.updateCount > 1 ? "s" : "")
                        }
                        gray: true
                        font.pixelSize: 13
                    }

                    Rectangle {
                        id: _checkButton
                        Layout.preferredWidth: 90
                        Layout.minimumWidth: 60
                        Layout.preferredHeight: 26
                        radius: 7
                        color: _checkMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        enabled: !GeneralState.checkingUpdates
                        clip: true

                        CFText {
                            anchors.centerIn: parent
                            width: _checkButton.width - 12
                            horizontalAlignment: Text.AlignHCenter
                            text: I18n.tr("Vérifier")
                            font.pixelSize: 12
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: _checkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GeneralState.checkForUpdates()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Installateur Lickintosh")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 26
                        radius: 7
                        color: _installerMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1

                        CFText {
                            anchors.centerIn: parent
                            text: I18n.tr("Ouvrir")
                            font.pixelSize: 12
                            color: Theme.textPrimary
                        }

                        MouseArea {
                            id: _installerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: InstallerLauncher.open("UpdatesPage")
                        }
                    }
                }

                CFText {
                    visible: GeneralState.packageManager === "" || GeneralState.packageManager === "unknown"
                    text: I18n.tr("Aucun gestionnaire de paquets pris en charge n'a été détecté.")
                    font.pixelSize: 11
                    gray: true
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            ContentSection {
                title: I18n.tr("Stockage")
                visible: root.currentSubpage === "storage"

                Repeater {
                    model: GeneralState.storageVolumes

                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            CFText {
                                text: modelData.mountPoint
                                font.pixelSize: 14
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            CFText {
                                text: modelData.used + " / " + modelData.size + " (" + modelData.usePercent + ")"
                                gray: true
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: "#18ffffff"

                            Rectangle {
                                height: parent.height
                                radius: 3
                                width: parent.width * Math.min(1, parseInt(modelData.usePercent) / 100)
                                color: parseInt(modelData.usePercent) >= 90 ? "#ff453a" : "#3478f6"
                            }
                        }
                    }
                }

                CFText {
                    visible: GeneralState.storageVolumes.length === 0
                    text: I18n.tr("Aucun volume détecté.")
                    font.pixelSize: 12
                    gray: true
                }
            }

            ContentSection {
                title: I18n.tr("Date et heure")
                visible: root.currentSubpage === "datetime"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Fuseau horaire")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.timezone.length > 0 ? GeneralState.timezone : I18n.tr("Inconnu")
                        gray: true
                        font.pixelSize: 13
                    }
                }

                ConfigSwitch {
                    text: I18n.tr("Régler automatiquement (NTP)")
                    description: GeneralState.clockSynchronized ? I18n.tr("Horloge synchronisée") : I18n.tr("Horloge non synchronisée")
                    checked: GeneralState.ntpEnabled
                    onToggled: function(v) { GeneralState.setNtpEnabled(v) }
                }
            }

            ContentSection {
                title: I18n.tr("Langue et région")
                visible: root.currentSubpage === "language"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Langue de l'interface")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: [
                            { id: "auto", label: I18n.tr("Auto") },
                            { id: "fr",   label: "Français" },
                            { id: "en",   label: "English" },
                            { id: "es",   label: "Español" }
                        ]

                        Rectangle {
                            id: langChip
                            required property var modelData
                            readonly property bool active: ShellConfig.options.general.language === modelData.id
                            implicitWidth: chipLabel.implicitWidth + 24
                            implicitHeight: 28
                            radius: 8
                            color: active ? Theme.accent : (chipArea.containsMouse ? Theme.fillHover : Theme.fillControl)

                            CFText {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: langChip.modelData.id === "auto" ? I18n.tr("Auto") : langChip.modelData.label
                                font.pixelSize: 13
                                color: langChip.active ? Theme.onAccent : Theme.textPrimary
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellConfig.options.general.language = langChip.modelData.id
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Langue système")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.languageCode.length > 0 ? GeneralState.languageCode.toUpperCase() : I18n.tr("Inconnu")
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: I18n.tr("Locale")
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.localeName.length > 0 ? GeneralState.localeName : I18n.tr("Inconnu")
                        gray: true
                        font.pixelSize: 13
                    }
                }
            }

            ContentSection {
                title: I18n.tr("Éléments de connexion")
                visible: root.currentSubpage === "login"

                Repeater {
                    model: GeneralState.autostartEntries

                    ConfigSwitch {
                        required property var modelData
                        text: modelData.name
                        checked: modelData.enabled
                        onToggled: function(v) { GeneralState.setAutostartEnabled(modelData.path, v) }
                    }
                }

                CFText {
                    visible: GeneralState.autostartEntries.length === 0
                    text: I18n.tr("Aucune application configurée pour démarrer automatiquement.")
                    font.pixelSize: 12
                    gray: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
            }
        }
    }
}
