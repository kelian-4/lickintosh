import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.ui.settings.widgets

ContentPage {
    id: root

    readonly property var _transformOptions: [
        { id: 0, label: "Normal" },
        { id: 1, label: "90°" },
        { id: 2, label: "180°" },
        { id: 3, label: "270°" },
        { id: 4, label: "Miroir horizontal" },
        { id: 5, label: "Miroir + 90°" },
        { id: 6, label: "Miroir + 180°" },
        { id: 7, label: "Miroir + 270°" }
    ]

    readonly property var _cmOptions: [
        { id: "auto",    label: "Auto" },
        { id: "srgb",    label: "sRGB" },
        { id: "dcip3",   label: "DCI-P3" },
        { id: "dp3",     label: "Apple P3" },
        { id: "adobe",   label: "Adobe RGB" },
        { id: "wide",    label: "Large gamut (BT2020)" },
        { id: "edid",    label: "Primaires EDID" },
        { id: "hdr",     label: "HDR (expérimental)" },
        { id: "hdredid", label: "HDR + EDID (expérimental)" }
    ]

    ContentSection {
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Écrans détectés"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
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
                    text: MonitorState.loading ? "…" : "Actualiser"
                    font.pixelSize: 11
                    color: "#fff"
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: _refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MonitorState.refresh()
                }
            }
        }
    }

    Repeater {
        model: MonitorState.monitors

        ContentSection {
            id: _monSection
            required property var modelData
            title: (modelData.name || "") + (modelData.description ? " — " + modelData.description : "")

            property bool menuTransformOpen: false
            property bool menuCmOpen: false

            ConfigSwitch {
                Layout.fillWidth: true
                text: "Activé"
                checked: !_monSection.modelData.disabled
                enabled: _monSection.modelData.disabled || MonitorState.activeCount > 1
                onToggled: function(v) {
                    MonitorState.toggleDisabled(_monSection.modelData.name, !v)
                }
            }

            CFText {
                visible: !_monSection.modelData.disabled && MonitorState.activeCount <= 1
                text: "Impossible de désactiver le seul écran actif."
                font.pixelSize: 11
                gray: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: !_monSection.modelData.disabled

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Résolution"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: _monSection.modelData.width + "×" + _monSection.modelData.height
                              + " @ " + (_monSection.modelData.refreshRate ? _monSection.modelData.refreshRate.toFixed(2) : "?") + " Hz"
                        gray: true
                        font.pixelSize: 13
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: _monSection.modelData.availableModes && _monSection.modelData.availableModes.length > 0

                    Repeater {
                        model: _monSection.modelData.availableModes || []

                        Rectangle {
                            id: _modeRow
                            required property string modelData
                            width: parent.width
                            height: 28
                            radius: 6
                            color: _modeRowMouse.containsMouse ? "#14ffffff" : "transparent"

                            CFText {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: _modeRow.modelData
                                font.pixelSize: 12
                                color: "#fff"
                            }

                            MouseArea {
                                id: _modeRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var parts = _modeRow.modelData.replace("Hz", "").split("@")
                                    MonitorState.applyAndPersist({
                                        output: _monSection.modelData.name,
                                        mode: parts[0] + "@" + parts[1],
                                        position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                        scale: _monSection.modelData.scale
                                    })
                                }
                            }
                        }
                    }
                }

                ConfigSlider {
                    Layout.fillWidth: true
                    text: "Échelle"
                    value: _monSection.modelData.scale || 1
                    from: 0.5
                    to: 3.0
                    decimals: 2
                    onMoved: function(v) {
                        MonitorState.applyAndPersist({
                            output: _monSection.modelData.name,
                            mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                            position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                            scale: v
                        })
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Position"
                        font.pixelSize: 14
                        color: "#fff"
                        Layout.fillWidth: true
                    }

                    CFText {
                        text: _monSection.modelData.x + ", " + _monSection.modelData.y
                        gray: true
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Orientation"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: _transformButton
                        Layout.preferredWidth: 170
                        Layout.minimumWidth: 110
                        Layout.preferredHeight: 28
                        radius: 7
                        color: "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        clip: true

                        CFVI {
                            id: _transformChevron
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
                            width: _transformButton.width - 10 - 8 - _transformChevron.width - 4
                            text: {
                                for (var i = 0; i < root._transformOptions.length; i++) {
                                    if (root._transformOptions[i].id === (_monSection.modelData.transform || 0)) return root._transformOptions[i].label
                                }
                                return "Normal"
                            }
                            font.pixelSize: 12
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _monSection.menuTransformOpen = !_monSection.menuTransformOpen
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    visible: _monSection.menuTransformOpen
                    spacing: 2

                    Repeater {
                        model: root._transformOptions

                        Rectangle {
                            id: _transformRow
                            required property var modelData
                            width: parent.width
                            height: 30
                            radius: 6
                            color: _transformRowMouse.containsMouse ? "#14ffffff" : "transparent"

                            CFText {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: _transformRow.modelData.label
                                font.pixelSize: 13
                                color: "#fff"
                            }

                            MouseArea {
                                id: _transformRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    MonitorState.applyAndPersist({
                                        output: _monSection.modelData.name,
                                        mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                        position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                        scale: _monSection.modelData.scale,
                                        transform: _transformRow.modelData.id
                                    })
                                    _monSection.menuTransformOpen = false
                                }
                            }
                        }
                    }
                }

                ConfigSwitch {
                    Layout.fillWidth: true
                    text: "Taux de rafraîchissement variable (VRR)"
                    checked: _monSection.modelData.vrr || false
                    onToggled: function(v) {
                        MonitorState.applyAndPersist({
                            output: _monSection.modelData.name,
                            mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                            position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                            scale: _monSection.modelData.scale,
                            vrr: v ? 1 : 0
                        })
                    }
                }

                ConfigSwitch {
                    Layout.fillWidth: true
                    text: "Profondeur de couleur 10 bits"
                    checked: (_monSection.modelData.currentFormat || "").indexOf("2101010") !== -1 || (_monSection.modelData.currentFormat || "").indexOf("A2R10G10B10") !== -1
                    onToggled: function(v) {
                        MonitorState.applyAndPersist({
                            output: _monSection.modelData.name,
                            mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                            position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                            scale: _monSection.modelData.scale,
                            bitdepth: v ? 10 : 8
                        })
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Gestion des couleurs"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: _cmButton
                        Layout.preferredWidth: 190
                        Layout.minimumWidth: 120
                        Layout.preferredHeight: 28
                        radius: 7
                        color: "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        clip: true

                        CFVI {
                            id: _cmChevron
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
                            width: _cmButton.width - 10 - 8 - _cmChevron.width - 4
                            text: {
                                var cur = _monSection.modelData.colorManagementPreset || "auto"
                                for (var i = 0; i < root._cmOptions.length; i++) {
                                    if (root._cmOptions[i].id === cur) return root._cmOptions[i].label
                                }
                                return "Auto"
                            }
                            font.pixelSize: 12
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _monSection.menuCmOpen = !_monSection.menuCmOpen
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    visible: _monSection.menuCmOpen
                    spacing: 2

                    Repeater {
                        model: root._cmOptions

                        Rectangle {
                            id: _cmRow
                            required property var modelData
                            width: parent.width
                            height: 30
                            radius: 6
                            color: _cmRowMouse.containsMouse ? "#14ffffff" : "transparent"

                            CFText {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: _cmRow.modelData.label
                                font.pixelSize: 13
                                color: "#fff"
                            }

                            MouseArea {
                                id: _cmRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    MonitorState.applyAndPersist({
                                        output: _monSection.modelData.name,
                                        mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                        position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                        scale: _monSection.modelData.scale,
                                        cm: _cmRow.modelData.id
                                    })
                                    _monSection.menuCmOpen = false
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: _monSection.modelData.colorManagementPreset === "hdr" || _monSection.modelData.colorManagementPreset === "hdredid"

                    ConfigSlider {
                        Layout.fillWidth: true
                        text: "Luminosité SDR"
                        value: _monSection.modelData.sdrBrightness || 1.0
                        from: 0.5
                        to: 2.0
                        decimals: 2
                        onMoved: function(v) {
                            MonitorState.applyAndPersist({
                                output: _monSection.modelData.name,
                                mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                scale: _monSection.modelData.scale,
                                sdrbrightness: v
                            })
                        }
                    }

                    ConfigSlider {
                        Layout.fillWidth: true
                        text: "Saturation SDR"
                        value: _monSection.modelData.sdrSaturation || 1.0
                        from: 0.5
                        to: 1.5
                        decimals: 2
                        onMoved: function(v) {
                            MonitorState.applyAndPersist({
                                output: _monSection.modelData.name,
                                mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                scale: _monSection.modelData.scale,
                                sdrsaturation: v
                            })
                        }
                    }
                }

                property bool menuMirrorOpen: false

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Miroir de"
                        font.pixelSize: 14
                        color: "#fff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: _mirrorButton
                        Layout.preferredWidth: 170
                        Layout.minimumWidth: 110
                        Layout.preferredHeight: 28
                        radius: 7
                        color: "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        clip: true

                        CFVI {
                            id: _mirrorChevron
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
                            width: _mirrorButton.width - 10 - 8 - _mirrorChevron.width - 4
                            text: (_monSection.modelData.mirrorOf && _monSection.modelData.mirrorOf !== "none" && _monSection.modelData.mirrorOf.length > 0) ? _monSection.modelData.mirrorOf : "Aucun"
                            font.pixelSize: 12
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _monSection.menuMirrorOpen = !_monSection.menuMirrorOpen
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    visible: _monSection.menuMirrorOpen
                    spacing: 2

                    Rectangle {
                        id: _mirrorNoneRow
                        width: parent.width
                        height: 30
                        radius: 6
                        color: _mirrorNoneMouse.containsMouse ? "#14ffffff" : "transparent"

                        CFText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Aucun"
                            font.pixelSize: 13
                            color: "#fff"
                        }

                        MouseArea {
                            id: _mirrorNoneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                MonitorState.applyAndPersist({
                                    output: _monSection.modelData.name,
                                    mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                    position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                    scale: _monSection.modelData.scale,
                                    mirror: "none"
                                })
                                _monSection.menuMirrorOpen = false
                            }
                        }
                    }

                    Repeater {
                        model: MonitorState.monitors.filter(function(m) { return m.name !== _monSection.modelData.name })

                        Rectangle {
                            id: _mirrorRow
                            required property var modelData
                            width: parent.width
                            height: 30
                            radius: 6
                            color: _mirrorRowMouse.containsMouse ? "#14ffffff" : "transparent"

                            CFText {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: _mirrorRow.modelData.name
                                font.pixelSize: 13
                                color: "#fff"
                            }

                            MouseArea {
                                id: _mirrorRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    MonitorState.applyAndPersist({
                                        output: _monSection.modelData.name,
                                        mode: _monSection.modelData.width + "x" + _monSection.modelData.height + "@" + (_monSection.modelData.refreshRate || 60).toFixed(2),
                                        position: _monSection.modelData.x + "x" + _monSection.modelData.y,
                                        scale: _monSection.modelData.scale,
                                        mirror: _mirrorRow.modelData.name
                                    })
                                    _monSection.menuMirrorOpen = false
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CFText {
                        text: "Sur certains pilotes graphiques, la rotation ou le HDR peuvent nécessiter un redémarrage du compositeur pour s'appliquer pleinement."
                        font.pixelSize: 11
                        gray: true
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        id: _resetButton
                        Layout.preferredWidth: 100
                        Layout.minimumWidth: 70
                        Layout.preferredHeight: 28
                        radius: 7
                        color: _resetMouse.containsMouse ? "#24ffffff" : "#18ffffff"
                        border.color: "#14ffffff"
                        border.width: 1
                        clip: true

                        CFText {
                            anchors.centerIn: parent
                            width: _resetButton.width - 12
                            horizontalAlignment: Text.AlignHCenter
                            text: "Réinitialiser"
                            font.pixelSize: 11
                            color: "#fff"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: _resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                MonitorState.applyAndPersist({
                                    output: _monSection.modelData.name,
                                    mode: "preferred",
                                    position: "auto",
                                    scale: "auto",
                                    transform: 0,
                                    vrr: 0,
                                    bitdepth: 8,
                                    cm: "auto",
                                    mirror: ""
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    CFText {
        visible: MonitorState.monitors.length === 0 && !MonitorState.loading
        text: "Aucun écran détecté."
        font.pixelSize: 13
        gray: true
        Layout.fillWidth: true
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
    }
}
