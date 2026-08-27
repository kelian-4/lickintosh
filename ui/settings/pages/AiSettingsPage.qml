import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.ui.topbar.statusarea.ai
import qs.ui.primitives
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var _providers: [
        { id: "anthropic", label: "Anthropic (Claude)" },
        { id: "openai",    label: "OpenAI" },
        { id: "google",    label: "Google (Gemini)" },
        { id: "ollama",    label: "Ollama (local)" }
    ]

    readonly property string _currentProviderLabel: {
        for (var i = 0; i < root._providers.length; i++) {
            if (root._providers[i].id === AiConfig.provider) return root._providers[i].label
        }
        return "Anthropic (Claude)"
    }

    property bool _providerMenuOpen: false
    property bool _ollamaModelMenuOpen: false
    property bool _apiKeyVisible: false
    property string _apiKeyDraft: AiConfig.getKey(AiConfig.provider)
    property string _modelDraft: AiConfig.cloudModel

    onVisibleChanged: {
        if (visible) {
            root._apiKeyDraft = AiConfig.getKey(AiConfig.provider)
            root._modelDraft = AiConfig.cloudModel
        }
    }

    ContentSection {
        title: "Fournisseur"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Fournisseur IA"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                id: _providerButton
                Layout.preferredWidth: 200
                Layout.minimumWidth: 120
                Layout.preferredHeight: 28
                radius: 7
                color: "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                clip: true

                CFVI {
                    id: _providerChevron
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "chevron-down.svg"
                    size: 9
                    gray: true
                }

                CFText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: _providerButton.width - 10 - 8 - _providerChevron.width - 4
                    text: root._currentProviderLabel
                    font.pixelSize: 12
                    color: "#fff"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._providerMenuOpen = !root._providerMenuOpen
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root._providerMenuOpen
            spacing: 2

            Repeater {
                model: root._providers

                Rectangle {
                    id: _providerRow
                    required property var modelData
                    width: parent.width
                    height: 30
                    radius: 6
                    color: _providerRowMouse.containsMouse ? "#14ffffff" : "transparent"

                    CFText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: _providerRow.modelData.label
                        font.pixelSize: 13
                        color: "#fff"
                    }

                    MouseArea {
                        id: _providerRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiConfig.set("provider", _providerRow.modelData.id)
                            root._apiKeyDraft = AiConfig.getKey(_providerRow.modelData.id)
                            root._modelDraft = AiConfig.cloudModel
                            root._providerMenuOpen = false
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: AiConfig.provider === "anthropic" || AiConfig.provider === "openai" || AiConfig.provider === "google"

            CFText {
                text: "Modèle"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 220
                Layout.minimumWidth: 140
                Layout.preferredHeight: 28
                radius: 7
                color: "#18ffffff"
                border.color: _modelInput.activeFocus ? "#3478f6" : "#14ffffff"
                border.width: 1

                TextInput {
                    id: _modelInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#fff"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    activeFocusOnPress: true
                    text: root._modelDraft
                    onTextChanged: root._modelDraft = text
                    onEditingFinished: AiConfig.set("cloudModel", text)
                }
            }
        }
    }

    ContentSection {
        title: "Clé API"
        visible: AiConfig.provider === "anthropic" || AiConfig.provider === "openai" || AiConfig.provider === "google"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 7
                    color: "#18ffffff"
                    border.color: "#14ffffff"
                    border.width: 1

                    TextInput {
                        id: _apiKeyInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#fff"
                        font.pixelSize: 13
                        echoMode: root._apiKeyVisible ? TextInput.Normal : TextInput.Password
                        text: root._apiKeyDraft
                        clip: true
                        onTextChanged: root._apiKeyDraft = text
                        onEditingFinished: AiConfig.setKey(AiConfig.provider, text)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 7
                    color: _eyeMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                    border.color: "#14ffffff"
                    border.width: 1

                    CFVI {
                        anchors.centerIn: parent
                        icon: root._apiKeyVisible ? "notch/eye-off.svg" : "notch/eye.svg"
                        size: 14
                        gray: true
                    }

                    MouseArea {
                        id: _eyeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._apiKeyVisible = !root._apiKeyVisible
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 7
                    color: _deleteKeyMouse.containsMouse ? "#40ff453a" : "#18ffffff"
                    border.color: "#14ffffff"
                    border.width: 1
                    enabled: root._apiKeyDraft.length > 0

                    CFVI {
                        anchors.centerIn: parent
                        icon: "notch/trash-2.svg"
                        size: 14
                        color: _deleteKeyMouse.containsMouse ? "#ff453a" : "#a0ffffff"
                    }

                    MouseArea {
                        id: _deleteKeyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiConfig.removeKey(AiConfig.provider)
                            root._apiKeyDraft = ""
                        }
                    }
                }
            }

            CFText {
                text: AiConfig.keyringAvailable
                          ? "Stockée dans le trousseau système (secret-tool)."
                          : "Trousseau système indisponible — clé stockée en clair dans le fichier de config."
                font.pixelSize: 11
                gray: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    ContentSection {
        title: "Ollama"
        visible: AiConfig.provider === "ollama"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Hôte"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: AiConfig.ollamaHost
                gray: true
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.maximumWidth: 220
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Modèle"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                id: _ollamaModelButton
                Layout.preferredWidth: 170
                Layout.minimumWidth: 110
                Layout.preferredHeight: 28
                radius: 7
                color: "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                clip: true
                enabled: AiConfig.ollamaModels.length > 0

                CFVI {
                    id: _ollamaModelChevron
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "chevron-down.svg"
                    size: 9
                    gray: true
                }

                CFText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: _ollamaModelButton.width - 10 - 8 - _ollamaModelChevron.width - 4
                    text: AiConfig.ollamaModel.length > 0 ? AiConfig.ollamaModel : "Aucun modèle"
                    font.pixelSize: 12
                    color: "#fff"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._ollamaModelMenuOpen = !root._ollamaModelMenuOpen
                }
            }

            Rectangle {
                id: _refreshButton
                Layout.preferredWidth: 90
                Layout.minimumWidth: 60
                Layout.preferredHeight: 26
                radius: 7
                color: _refreshMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                clip: true

                CFText {
                    anchors.centerIn: parent
                    width: _refreshButton.width - 12
                    horizontalAlignment: Text.AlignHCenter
                    text: "Actualiser"
                    font.pixelSize: 11
                    color: "#fff"
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: _refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AiConfig.refreshOllamaModels()
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root._ollamaModelMenuOpen
            spacing: 2

            Repeater {
                model: AiConfig.ollamaModels

                Rectangle {
                    id: _ollamaModelRow
                    required property string modelData
                    width: parent.width
                    height: 30
                    radius: 6
                    color: _ollamaModelRowMouse.containsMouse ? "#14ffffff" : "transparent"

                    CFText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: _ollamaModelRow.modelData
                        font.pixelSize: 13
                        color: "#fff"
                    }

                    MouseArea {
                        id: _ollamaModelRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiConfig.set("ollamaModel", _ollamaModelRow.modelData)
                            root._ollamaModelMenuOpen = false
                        }
                    }
                }
            }
        }

        CFText {
            visible: AiConfig.ollamaModels.length === 0
            text: "Aucun modèle Ollama détecté. Vérifie qu'Ollama tourne et qu'au moins un modèle est installé (ollama pull <modèle>)."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: "Reconnaissance vocale"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Modèle Whisper"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: AiConfig.whisperModel
                gray: true
                font.pixelSize: 13
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Langue"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: AiConfig.whisperLang
                gray: true
                font.pixelSize: 13
            }
        }

        CFText {
            text: "Nécessite whisper-cpp et un modèle ggml compatible installés sur le système."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: "Historique des conversations"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Conversations enregistrées"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CFText {
                text: AiChats.chats.length + " conversation" + (AiChats.chats.length > 1 ? "s" : "")
                gray: true
                font.pixelSize: 13
            }
        }

        Rectangle {
            id: _clearButton
            Layout.preferredWidth: 220
            Layout.minimumWidth: 140
            Layout.preferredHeight: 30
            radius: 8
            color: _clearMouse.containsMouse ? "#40ff453a" : "#20ff453a"
            border.color: "#40ff453a"
            border.width: 1
            clip: true
            enabled: AiChats.chats.length > 0

            CFText {
                anchors.centerIn: parent
                width: _clearButton.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: "Effacer tout l'historique"
                font.pixelSize: 12
                color: "#ff453a"
                elide: Text.ElideRight
            }

            MouseArea {
                id: _clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AiChats.clearAllChats()
            }
        }
    }

    ContentSection {
        title: "Instructions personnalisées"

        CFText {
            text: "Ajoutées à la fin des instructions système de base à chaque conversation."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: 8
            color: "#18ffffff"
            border.color: "#14ffffff"
            border.width: 1
            clip: true

            TextArea {
                id: _systemPromptInput
                anchors.fill: parent
                anchors.margins: 8
                text: AiConfig.systemPrompt
                color: "#fff"
                font.pixelSize: 13
                wrapMode: TextArea.Wrap
                selectByMouse: true
                background: Item {}
                onEditingFinished: AiConfig.set("systemPrompt", text)
            }
        }
    }

    ContentSection {
        title: "Accès rapide"

        CFText {
            text: "Clique sur l'icône IA dans la barre du haut pour ouvrir l'assistant à tout moment, depuis n'importe quel espace de travail."
            font.pixelSize: 12
            color: "#fff"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        title: "Commandes slash"

        CFText {
            text: "Dans le champ de saisie de l'assistant, tape / pour voir apparaître les commandes disponibles."
            font.pixelSize: 12
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: [
                { cmd: "/model set <nom>", desc: "Changer de modèle" },
                { cmd: "/provider set <id> [key <clé>]", desc: "Changer de fournisseur, avec clé optionnelle" },
                { cmd: "/key set <provider> <clé>", desc: "Définir une clé API" },
                { cmd: "/key remove <provider>", desc: "Supprimer une clé API" },
                { cmd: "/add <id> <endpoint> <format> <modèle>", desc: "Ajouter un fournisseur personnalisé" },
                { cmd: "/chat list | load <id> | new | delete <id> | clear", desc: "Gérer les conversations sauvegardées" },
                { cmd: "/clear", desc: "Effacer la conversation en cours" },
                { cmd: "/help", desc: "Afficher la liste des commandes" }
            ]

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                CFText {
                    text: modelData.cmd
                    font.pixelSize: 13
                    font.family: "monospace"
                    color: "#fff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                CFText {
                    text: modelData.desc
                    font.pixelSize: 11
                    gray: true
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
