import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    function fmtSpeed(bps) {
        if (bps > 1048576) return (bps / 1048576).toFixed(1) + " Mo/s"
        if (bps > 1024) return (bps / 1024).toFixed(0) + " Ko/s"
        return Math.round(bps) + " o/s"
    }

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: "#262626"
    }

    component Caption: Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 150
        color: "#8A8A8A"
        font.pixelSize: 11
        font.family: "SF Pro Text"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    component Section: Item {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true
    }

    component Metric: Section {
        id: metric

        property string title: ""
        property var history: []
        property color accent: "#1C7AFF"
        property real percent: 0
        property string detail: ""

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: metric.title
                    color: "#8A8A8A"
                    font.pixelSize: 11
                    font.family: "SF Pro Text"
                }
                Text {
                    text: Math.round(metric.percent) + "%"
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "SF Pro Text"
                }
            }

            Sparkline {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                values: metric.history
                lineColor: metric.accent
            }

            Caption { color: "#B0B0B0"; text: metric.detail }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Metric {
            title: "CPU"
            history: ResourcesState.cpuHistory
            accent: "#1C7AFF"
            percent: ResourcesState.cpuPercent
            detail: ResourcesState.cpuTempAvailable ? Math.round(ResourcesState.cpuTempC) + "°C" : (ResourcesState.cpuName || "Processeur")
        }

        Divider {}

        Metric {
            title: "Mémoire"
            history: ResourcesState.memoryHistory
            accent: "#EC4899"
            percent: ResourcesState.memoryPercent
            detail: ResourcesState.memoryUsedGb.toFixed(1) + " / " + ResourcesState.memoryTotalGb.toFixed(1) + " Gio"
        }

        Divider {}

        Metric {
            title: "Stockage"
            history: ResourcesState.storageHistory
            accent: "#4ADE80"
            percent: ResourcesState.storagePercent
            detail: ResourcesState.storageUsedGb.toFixed(0) + " / " + ResourcesState.storageTotalGb.toFixed(0) + " Gio"
        }

        Divider {}

        Section {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Caption { text: "Réseau" }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↓  " + root.fmtSpeed(ResourcesState.netDownBps)
                    color: "#4ADE80"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "SF Pro Text"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑  " + root.fmtSpeed(ResourcesState.netUpBps)
                    color: "#FBBF24"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "SF Pro Text"
                }
                Caption {
                    color: "#6A6A6A"
                    text: "Session ↓" + ResourcesState.netTotalDownGb.toFixed(2) + " ↑" + ResourcesState.netTotalUpGb.toFixed(2) + " Go"
                }
            }
        }

        Divider {}

        Metric {
            title: "Batterie"
            history: ResourcesState.batteryHistory
            accent: NotchState.batteryPercent > 20 ? "#4ADE80" : "#FF6B6B"
            percent: NotchState.batteryPercent
            detail: NotchState.batteryCharging ? "En charge" : "Sur batterie"
        }

        Divider {}

        Section {
            Component.onCompleted: ResourcesState.topMemoryWatchers++
            Component.onDestruction: ResourcesState.topMemoryWatchers--

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 8
                spacing: 4

                Caption { text: "Processus (mémoire)" }

                Repeater {
                    model: ResourcesState.topMemory.slice(0, 4)

                    delegate: RowLayout {
                        id: proc
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: proc.modelData.name
                            color: "#E6E6E6"
                            font.pixelSize: 11
                            font.family: "SF Pro Text"
                            elide: Text.ElideRight
                        }
                        Text {
                            text: proc.modelData.mb >= 1024 ? (proc.modelData.mb / 1024).toFixed(1) + " Gio" : Math.round(proc.modelData.mb) + " Mio"
                            color: "#8A8A8A"
                            font.pixelSize: 11
                            font.family: "SF Mono"
                        }
                    }
                }
            }
        }
    }
}
