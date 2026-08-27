import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core.system
import qs.ui.primitives
import qs.ui.settings.widgets

Item {
    id: root

    anchors.fill: parent

    property string currentSubpage: ""

    readonly property var _rows: [
        { id: "about",     name: "Informations",         icon: "settings/general.svg" },
        { id: "updates",   name: "Mises à jour logicielles", icon: "settings/general.svg" },
        { id: "storage",   name: "Stockage",              icon: "settings/general.svg" },
        { id: "datetime",  name: "Date et heure",         icon: "settings/general.svg" },
        { id: "language",  name: "Langue et région",      icon: "settings/general.svg" },
        { id: "login",     name: "Éléments de connexion", icon: "settings/general.svg" }
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
                            color: "#fff"
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
                color: "#fff"
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
                            text: GeneralState.hostname.length > 0 ? GeneralState.hostname : "Inconnu"
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: "#fff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        CFText {
                            text: GeneralState.osName.length > 0 ? GeneralState.osName : "Système inconnu"
                            font.pixelSize: 13
                            gray: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            ContentSection {
                title: "Système"
                visible: root.currentSubpage === "about"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "OS"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.osName.length > 0 ? GeneralState.osName : "Inconnu"
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
                        text: "Host"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "Noyau"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.kernelVersion.length > 0 ? GeneralState.kernelVersion : "Inconnu"
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.uptimePretty.length > 0

                    CFText {
                        text: "Uptime"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "Paquets"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "Shell"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "WM"
                        font.pixelSize: 14
                        color: "#fff"
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
                title: "Matériel"
                visible: root.currentSubpage === "about"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: GeneralState.cpuModel.length > 0

                    CFText {
                        text: "CPU"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "GPU"
                        font.pixelSize: 14
                        color: "#fff"
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
                            text: "Mémoire"
                            font.pixelSize: 14
                            color: "#fff"
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
                        text: "Swap"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "IP locale"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "Batterie"
                        font.pixelSize: 14
                        color: "#fff"
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
                        text: "Locale"
                        font.pixelSize: 14
                        color: "#fff"
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
                title: "Mises à jour logicielles"
                visible: root.currentSubpage === "updates"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "État"
                        font.pixelSize: 14
                        color: "#fff"
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
                            text: "Vérifier"
                            font.pixelSize: 12
                            color: "#fff"
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

                CFText {
                    visible: GeneralState.packageManager === "" || GeneralState.packageManager === "unknown"
                    text: "Aucun gestionnaire de paquets pris en charge n'a été détecté."
                    font.pixelSize: 11
                    gray: true
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            ContentSection {
                title: "Stockage"
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
                                color: "#fff"
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
                    text: "Aucun volume détecté."
                    font.pixelSize: 12
                    gray: true
                }
            }

            ContentSection {
                title: "Date et heure"
                visible: root.currentSubpage === "datetime"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Fuseau horaire"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.timezone.length > 0 ? GeneralState.timezone : "Inconnu"
                        gray: true
                        font.pixelSize: 13
                    }
                }

                ConfigSwitch {
                    text: "Régler automatiquement (NTP)"
                    description: GeneralState.clockSynchronized ? "Horloge synchronisée" : "Horloge non synchronisée"
                    checked: GeneralState.ntpEnabled
                    onToggled: function(v) { GeneralState.setNtpEnabled(v) }
                }
            }

            ContentSection {
                title: "Langue et région"
                visible: root.currentSubpage === "language"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Langue système"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.languageCode.length > 0 ? GeneralState.languageCode.toUpperCase() : "Inconnu"
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Locale"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: GeneralState.localeName.length > 0 ? GeneralState.localeName : "Inconnu"
                        gray: true
                        font.pixelSize: 13
                    }
                }
            }

            ContentSection {
                title: "Éléments de connexion"
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
                    text: "Aucune application configurée pour démarrer automatiquement."
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
