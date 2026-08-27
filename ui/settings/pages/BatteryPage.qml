import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtGraphs
import qs.core.config
import qs.core.battery
import qs.ui.primitives
import qs.ui.settings.widgets

ContentPage {
    id: root

    property string historyRange: "24h"

    readonly property var _currentLevelHistory: root.historyRange === "24h"
                                                 ? BatteryHistoryState.last24h
                                                 : BatteryHistoryState.last10days
    readonly property var _currentUsageHistory: root.historyRange === "24h"
                                                 ? BatteryHistoryState.screenUsage24h
                                                 : BatteryHistoryState.screenUsage10days

    readonly property string _chargingStateLabel: BatteryHealthState.onBattery ? "Sur batterie" : "En charge"

    ContentSection {
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Santé de la batterie"
                font.pixelSize: 14
                color: "#fff"
                Layout.fillWidth: true
            }

            CFText {
                text: BatteryHealthState.healthLabel
                          + (BatteryHealthState.energyFullDesign > 0 ? " · " + BatteryHealthState.healthPercent + "%" : "")
                gray: true
                font.pixelSize: 13
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: root._chargingStateLabel
                font.pixelSize: 14
                color: "#fff"
                Layout.fillWidth: true
            }

            CFText {
                visible: BatteryHealthState.chargeLimitSupported && BatteryHealthState.chargeLimitValue < 100
                text: "Limité à " + BatteryHealthState.chargeLimitValue + " %"
                gray: true
                font.pixelSize: 13
            }
        }
    }

    readonly property var _lowPowerRules: [
        { id: "never",         label: "Jamais" },
        { id: "always",        label: "Toujours" },
        { id: "only-battery",  label: "Sur batterie uniquement" },
        { id: "only-ac",       label: "Sur secteur uniquement" }
    ]

    readonly property string _lowPowerRuleLabel: {
        for (var i = 0; i < root._lowPowerRules.length; i++) {
            if (root._lowPowerRules[i].id === BatteryHealthState.lowPowerRule) return root._lowPowerRules[i].label
        }
        return "Jamais"
    }

    property bool _lowPowerMenuOpen: false

    ContentSection {
        title: "Mode basse consommation"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CFText {
                text: "Mode basse consommation"
                font.pixelSize: 14
                color: "#fff"
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Rectangle {
                id: _lowPowerButton
                Layout.preferredWidth: 170
                Layout.minimumWidth: 110
                Layout.preferredHeight: 28
                radius: 7
                color: "#18ffffff"
                border.color: "#14ffffff"
                border.width: 1
                clip: true

                CFVI {
                    id: _lowPowerChevron
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
                    width: _lowPowerButton.width - 10 - 8 - _lowPowerChevron.width - 4
                    text: root._lowPowerRuleLabel
                    font.pixelSize: 12
                    color: "#fff"
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._lowPowerMenuOpen = !root._lowPowerMenuOpen
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root._lowPowerMenuOpen
            spacing: 2

            Repeater {
                model: root._lowPowerRules

                Rectangle {
                    id: _ruleRow
                    required property var modelData
                    width: parent.width
                    height: 30
                    radius: 6
                    color: _ruleMouse.containsMouse ? "#14ffffff" : "transparent"

                    CFText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: _ruleRow.modelData.label
                        font.pixelSize: 13
                        color: "#fff"
                    }

                    MouseArea {
                        id: _ruleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            BatteryHealthState.setLowPowerRule(_ruleRow.modelData.id)
                            root._lowPowerMenuOpen = false
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        title: "Limite de charge"
        visible: BatteryHealthState.chargeLimitSupported

        ConfigSlider {
            text: "Charger jusqu'à"
            value: BatteryHealthState.chargeLimitValue
            from: 50
            to: 100
            decimals: 0
            valueSuffix: " %"
            onMoved: function(v) { BatteryHealthState.setChargeLimit(v) }
        }

        CFText {
            text: "Limite la charge pour ralentir le vieillissement de la batterie. Nécessite un mot de passe administrateur."
            font.pixelSize: 11
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    ContentSection {
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "24h",     label: "Dernières 24 heures" },
                    { id: "10days",  label: "10 derniers jours" }
                ]

                Rectangle {
                    id: _tabButton
                    required property var modelData
                    readonly property bool active: root.historyRange === modelData.id

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 8
                    color: active ? "#3478f6" : (_tabMouse.containsMouse ? "#14ffffff" : "transparent")
                    border.color: active ? "transparent" : "#14ffffff"
                    border.width: active ? 0 : 1

                    CFText {
                        anchors.centerIn: parent
                        text: _tabButton.modelData.label
                        font.pixelSize: 12
                        font.weight: _tabButton.active ? Font.DemiBold : Font.Normal
                        color: "#fff"
                    }

                    MouseArea {
                        id: _tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.historyRange = _tabButton.modelData.id
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 4
            visible: root._currentLevelHistory.length > 1

            CFText {
                text: "Niveau de batterie"
                font.pixelSize: 12
                gray: true
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140

                GraphsView {
                    anchors.fill: parent

                    axisX: ValueAxis {
                        min: 0
                        max: Math.max(1, root._currentLevelHistory.length - 1)
                        visible: false
                    }
                    axisY: ValueAxis {
                        min: 0
                        max: 100
                        visible: false
                    }

                    AreaSeries {
                        id: _historyArea
                        color: "#4034c759"
                        borderColor: "#34c759"
                        borderWidth: 2

                        upperSeries: LineSeries {
                            id: _historyLine

                            Connections {
                                target: BatteryHistoryState
                                function onRawEntriesChanged() { root._fillLevelSeries() }
                            }

                            Connections {
                                target: root
                                function onHistoryRangeChanged() { root._fillLevelSeries() }
                            }
                        }
                    }
                }
            }

            CFText {
                text: {
                    if (root._currentLevelHistory.length === 0) return ""
                    var oldest = root._currentLevelHistory[0].timestamp
                    var newest = root._currentLevelHistory[root._currentLevelHistory.length - 1].timestamp
                    return Qt.formatDateTime(new Date(oldest * 1000), "hh:mm")
                           + "  →  "
                           + Qt.formatDateTime(new Date(newest * 1000), "hh:mm")
                }
                font.pixelSize: 10
                gray: true
            }
        }

        CFText {
            visible: root._currentLevelHistory.length <= 1
            text: "Pas encore assez de données collectées pour afficher l'historique."
            font.pixelSize: 12
            gray: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 4
            visible: root._currentUsageHistory.length > 0

            CFText {
                text: "Activité de l'écran"
                font.pixelSize: 12
                gray: true
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80

                RowLayout {
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: root._currentUsageHistory

                        Rectangle {
                            id: _bar
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.preferredHeight: Math.max(2, (modelData.minutesOn / 60) * 80)
                            radius: 2
                            color: "#3478f6"
                        }
                    }
                }
            }
        }
    }

    function _fillLevelSeries() {
        _historyLine.clear()
        var entries = root._currentLevelHistory
        for (var i = 0; i < entries.length; i++) {
            _historyLine.append(i, entries[i].percent)
        }
    }

    Component.onCompleted: root._fillLevelSeries()

    ContentSection {
        title: "Utilisation énergétique"

        Repeater {
            model: ShellConfig.topConsumers

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                CFText {
                    text: modelData.name
                    font.pixelSize: 14
                    color: "#fff"
                    Layout.fillWidth: true
                }

                CFText {
                    text: "CPU " + modelData.cpu.toFixed(1) + "% · RAM " + ShellConfig.formatMemory(modelData.rssMb)
                    font.pixelSize: 12
                    gray: true
                }
            }
        }

        CFText {
            text: "Analyse en cours…"
            font.pixelSize: 13
            gray: true
            visible: !ShellConfig.hasCollectedOnce
        }
    }
}
