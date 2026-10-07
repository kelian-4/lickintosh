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
        font.family: "SF Pro Rounded"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                RingGauge { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.cpuPercent; ringColor: "#1C7AFF" }
                Caption { text: "CPU" }
                Caption {
                    color: "#B0B0B0"
                    text: ResourcesState.cpuTempAvailable ? Math.round(ResourcesState.cpuTempC) + "°C" : (ResourcesState.cpuName || "Processeur")
                }
            }
        }

        Divider {}

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                RingGauge { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.memoryPercent; ringColor: "#EC4899" }
                Caption { text: "Mémoire" }
                Caption { color: "#B0B0B0"; text: ResourcesState.memoryUsedGb.toFixed(1) + " / " + ResourcesState.memoryTotalGb.toFixed(1) + " Gio" }
            }
        }

        Divider {}

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                RingGauge { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.storagePercent; ringColor: "#4ADE80" }
                Caption { text: "Stockage" }
                Caption { color: "#B0B0B0"; text: ResourcesState.storageUsedGb.toFixed(0) + " / " + ResourcesState.storageTotalGb.toFixed(0) + " Gio" }
            }
        }

        Divider {}

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

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
                    font.family: "SF Pro Rounded"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑  " + root.fmtSpeed(ResourcesState.netUpBps)
                    color: "#FBBF24"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "SF Pro Rounded"
                }
                Caption {
                    color: "#6A6A6A"
                    text: "Session ↓" + ResourcesState.netTotalDownGb.toFixed(2) + " ↑" + ResourcesState.netTotalUpGb.toFixed(2) + " Go"
                }
            }
        }

        Divider {}

        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                RingGauge {
                    Layout.alignment: Qt.AlignHCenter
                    percent: NotchState.batteryPercent
                    ringColor: NotchState.batteryPercent > 20 ? "#4ADE80" : "#FF6B6B"
                }
                Caption { text: "Batterie" }
                Caption { color: "#B0B0B0"; text: NotchState.batteryCharging ? "En charge" : "Sur batterie" }
            }
        }
    }
}
