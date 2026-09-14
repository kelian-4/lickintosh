import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var _systemActionTitles: [
        "Screenshot région", "Screenshot écran", "Screenshot fenêtre",
        "Sélecteur de couleur", "Google Lens", "Lock", "Sleep", "Hibernate",
        "Reboot", "Redémarrer vers le BIOS", "Shutdown", "Déconnexion",
        "Vider le presse-papier", "Fond d'écran aléatoire", "Réindexer les fichiers"
    ]

    function _isActionEnabled(title) {
        return ShellConfig.options.spotlight.disabledActions.indexOf(title) === -1
    }

    function _setActionEnabled(title, enabled) {
        var list = ShellConfig.options.spotlight.disabledActions.slice()
        var idx = list.indexOf(title)
        if (enabled && idx !== -1) list.splice(idx, 1)
        if (!enabled && idx === -1) list.push(title)
        ShellConfig.options.spotlight.disabledActions = list
    }

    ContentSection {
        title: "Sources de résultats"

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Applications"
            checked: ShellConfig.options.spotlight.sources.applications
            onToggled: function(v) { ShellConfig.options.spotlight.sources.applications = v }
        }

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Fichiers"
            checked: ShellConfig.options.spotlight.sources.files
            onToggled: function(v) { ShellConfig.options.spotlight.sources.files = v }
        }

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Actions système"
            checked: ShellConfig.options.spotlight.sources.actions
            onToggled: function(v) { ShellConfig.options.spotlight.sources.actions = v }
        }

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Calculatrice"
            checked: ShellConfig.options.spotlight.sources.calculator
            onToggled: function(v) { ShellConfig.options.spotlight.sources.calculator = v }
        }
    }

    ContentSection {
        title: "Presse-papier"

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Historique du texte copié"
            checked: ShellConfig.options.spotlight.clipboard.enableText
            onToggled: function(v) { ShellConfig.options.spotlight.clipboard.enableText = v }
        }

        ConfigSwitch {
            Layout.fillWidth: true
            text: "Historique des images copiées"
            checked: ShellConfig.options.spotlight.clipboard.enableImage
            onToggled: function(v) { ShellConfig.options.spotlight.clipboard.enableImage = v }
        }

        ConfigSlider {
            Layout.fillWidth: true
            text: "Nombre d'entrées conservées"
            value: ShellConfig.options.spotlight.clipboard.maxEntries
            from: 10
            to: 300
            decimals: 0
            onMoved: function(v) { ShellConfig.options.spotlight.clipboard.maxEntries = Math.round(v) }
        }
    }

    ContentSection {
        title: "Raccourcis rapides"

        CFText {
            text: "Préfixe suivi d'un espace ou tapé directement selon l'alias, pour accéder à chaque mode."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: [
                { key: "calc",   label: "Calculatrice" },
                { key: "search", label: "Recherche web" },
                { key: "wall",   label: "Fonds d'écran" },
                { key: "emoji",  label: "Emoji" },
                { key: "sh",     label: "Commande shell" },
                { key: "todo",   label: "Tâches" }
            ]

            RowLayout {
                id: _aliasRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                CFText {
                    text: _aliasRow.modelData.label
                    font.pixelSize: 14
                    color: "#fff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 30
                    radius: 7
                    color: "#18ffffff"
                    border.color: _aliasInput.activeFocus ? "#3478f6" : "#14ffffff"
                    border.width: 1

                    TextInput {
                        id: _aliasInput
                        anchors.fill: parent
                        anchors.margins: 8
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#fff"
                        font.pixelSize: 14
                        maximumLength: 3
                        text: ShellConfig.options.spotlight.aliases[_aliasRow.modelData.key]
                        onEditingFinished: {
                            if (text.length === 0) {
                                text = ShellConfig.options.spotlight.aliases[_aliasRow.modelData.key]
                                return
                            }
                            ShellConfig.options.spotlight.aliases[_aliasRow.modelData.key] = text
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        title: "Indexation des fichiers"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Dossier des fonds d'écran"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 220
                Layout.minimumWidth: 140
                Layout.preferredHeight: 30
                radius: 7
                color: "#18ffffff"
                border.color: _wallDirInput.activeFocus ? "#3478f6" : "#14ffffff"
                border.width: 1

                TextInput {
                    id: _wallDirInput
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#fff"
                    font.pixelSize: 12
                    clip: true
                    text: ShellConfig.options.spotlight.indexing.wallpaperDir
                    onEditingFinished: ShellConfig.options.spotlight.indexing.wallpaperDir = text
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Dossiers exclus de la recherche"
                font.pixelSize: 14
                color: "#fff"
                Layout.fillWidth: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ShellConfig.options.spotlight.indexing.excludePaths

                    Rectangle {
                        id: _excludeChip
                        required property string modelData
                        required property int index
                        width: _excludeLabel.implicitWidth + 34
                        height: 26
                        radius: 13
                        color: "#18ffffff"

                        CFText {
                            id: _excludeLabel
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: _excludeChip.modelData
                            font.pixelSize: 12
                            color: "#fff"
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: _removeExcludeMouse.containsMouse ? "#40ff453a" : "transparent"

                            CFVI {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                icon: "notch/x.svg"
                            }

                            MouseArea {
                                id: _removeExcludeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var list = ShellConfig.options.spotlight.indexing.excludePaths.slice()
                                    list.splice(_excludeChip.index, 1)
                                    ShellConfig.options.spotlight.indexing.excludePaths = list
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: _addExcludeButton
                    width: 30
                    height: 26
                    radius: 13
                    color: _addExcludeMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                    border.color: "#14ffffff"
                    border.width: 1
                    visible: !_addExcludeField.visible

                    CFVI {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        icon: "notch/plus.svg"
                    }

                    MouseArea {
                        id: _addExcludeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            _addExcludeButton.visible = false
                            _addExcludeField.visible = true
                            _addExcludeField.forceActiveFocus()
                        }
                    }
                }

                Rectangle {
                    id: _addExcludeField
                    visible: false
                    width: 120
                    height: 26
                    radius: 13
                    color: "#18ffffff"
                    border.color: "#3478f6"
                    border.width: 1

                    TextInput {
                        id: _addExcludeInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#fff"
                        font.pixelSize: 12
                        onAccepted: {
                            if (text.trim().length > 0) {
                                var list = ShellConfig.options.spotlight.indexing.excludePaths.slice()
                                list.push(text.trim())
                                ShellConfig.options.spotlight.indexing.excludePaths = list
                            }
                            text = ""
                            _addExcludeField.visible = false
                            _addExcludeButton.visible = true
                        }
                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                _addExcludeField.visible = false
                                _addExcludeButton.visible = true
                            }
                        }
                    }

                    function forceActiveFocus() { _addExcludeInput.forceActiveFocus() }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Réindexation incrémentale"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: "Toutes les " + ShellConfig.options.spotlight.indexing.incrementalMinutes + " min"
                gray: true
                font.pixelSize: 13
            }
        }

        ConfigSlider {
            Layout.fillWidth: true
            value: ShellConfig.options.spotlight.indexing.incrementalMinutes
            from: 1
            to: 60
            decimals: 0
            onMoved: function(v) { ShellConfig.options.spotlight.indexing.incrementalMinutes = Math.round(v) }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Réindexation complète"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: "Toutes les " + ShellConfig.options.spotlight.indexing.fullReindexHours + " h"
                gray: true
                font.pixelSize: 13
            }
        }

        ConfigSlider {
            Layout.fillWidth: true
            value: ShellConfig.options.spotlight.indexing.fullReindexHours
            from: 1
            to: 72
            decimals: 0
            onMoved: function(v) { ShellConfig.options.spotlight.indexing.fullReindexHours = Math.round(v) }
        }
    }

    ContentSection {
        title: "Actions système"

        CFText {
            text: "Désactive les actions que tu ne veux pas voir apparaître (accessibles avec le préfixe >)."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root._systemActionTitles

            ConfigSwitch {
                id: _actionRow
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                checked: root._isActionEnabled(modelData)
                onToggled: function(v) { root._setActionEnabled(_actionRow.modelData, v) }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
