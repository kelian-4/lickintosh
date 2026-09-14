import QtQuick
import QtQuick.Layouts
import qs.services

// Onglet "Performance" : calqué sur modules/dashboard/Performance.qml
// de caelestia — carte CPU (nom, température, usage), Storage,
// Network, Memory, et une grande barre Battery verticale.
Item {
    id: root

    component Ring: Item {
        id: ring
        property real percent: 0
        property color ringColor: "#4ADE80"
        implicitWidth: 64
        implicitHeight: 64
        onPercentChanged: canvas.requestPaint()

        Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: "#2A2A2A"; border.width: 5 }
        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.reset()
                var cx = width / 2, cy = height / 2, r = width / 2 - 2.5
                var start = -Math.PI / 2
                var end = start + (Math.PI * 2) * Math.min(1, Math.max(0, ring.percent / 100))
                ctx.strokeStyle = ring.ringColor; ctx.lineWidth = 5; ctx.lineCap = "round"
                ctx.beginPath(); ctx.arc(cx, cy, r, start, end); ctx.stroke()
            }
        }
        Text { anchors.centerIn: parent; text: Math.round(ring.percent) + "%"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true; font.family: "SF Pro Rounded" }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // -- CPU --
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                radius: 12
                color: "#1A1A1A"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "CPU"; color: "#8A8A8A"; font.pixelSize: 10; font.family: "SF Pro Rounded" }
                        Text {
                            Layout.fillWidth: true
                            text: ResourcesState.cpuName || "Processeur"
                            color: "#FFFFFF"; font.pixelSize: 13; font.bold: true; font.family: "SF Pro Rounded"
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: ResourcesState.cpuTempAvailable
                            text: Math.round(ResourcesState.cpuTempC) + "°C"
                            color: "#B0B0B0"; font.pixelSize: 11; font.family: "SF Pro Rounded"
                        }
                    }
                    Ring { percent: ResourcesState.cpuPercent; ringColor: "#1C7AFF" }
                }
            }

            // -- Storage + Network --
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#1A1A1A"
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.storagePercent; ringColor: "#4ADE80" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Storage"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ResourcesState.storageUsedGb.toFixed(0) + " / " + ResourcesState.storageTotalGb.toFixed(0) + " GiB"
                            color: "#B0B0B0"; font.pixelSize: 9; font.family: "SF Pro Rounded"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#1A1A1A"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        Text { text: "Network"; color: "#8A8A8A"; font.pixelSize: 10; font.family: "SF Pro Rounded" }
                        RowLayout {
                            spacing: 4
                            Text { text: "↓"; color: "#4ADE80"; font.pixelSize: 11 }
                            Text { text: root._fmtSpeed(ResourcesState.netDownBps); color: "#FFFFFF"; font.pixelSize: 11; font.family: "SF Pro Rounded" }
                        }
                        RowLayout {
                            spacing: 4
                            Text { text: "↑"; color: "#FBBF24"; font.pixelSize: 11 }
                            Text { text: root._fmtSpeed(ResourcesState.netUpBps); color: "#FFFFFF"; font.pixelSize: 11; font.family: "SF Pro Rounded" }
                        }
                        Item { Layout.fillHeight: true }
                        Text {
                            text: "Session : ↓" + ResourcesState.netTotalDownGb.toFixed(2) + " Go  ↑" + ResourcesState.netTotalUpGb.toFixed(2) + " Go"
                            color: "#6A6A6A"; font.pixelSize: 8; font.family: "SF Pro Rounded"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#1A1A1A"
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.memoryPercent; ringColor: "#EC4899" }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Memory"; color: "#8A8A8A"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ResourcesState.memoryUsedGb.toFixed(1) + " / " + ResourcesState.memoryTotalGb.toFixed(1) + " GiB"
                            color: "#B0B0B0"; font.pixelSize: 9; font.family: "SF Pro Rounded"
                        }
                    }
                }
            }
        }

        // -- Battery --
        Rectangle {
            Layout.preferredWidth: 90
            Layout.fillHeight: true
            radius: 12
            color: "#1A1A1A"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text { text: "Battery"; color: "#8A8A8A"; font.pixelSize: 10; font.family: "SF Pro Rounded" }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 30
                        height: parent.height - 10
                        radius: 6
                        color: "transparent"
                        border.color: "#3A3A3A"
                        border.width: 2

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 3
                            height: (parent.height - 6) * Math.min(1, NotchState.batteryPercent / 100)
                            radius: 3
                            color: NotchState.batteryPercent > 20 ? "#4ADE80" : "#FF6B6B"
                            Behavior on height { NumberAnimation { duration: 400 } }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (NotchState.batteryCharging ? "⚡ " : "") + NotchState.batteryPercent + "%"
                    color: "#FFFFFF"; font.pixelSize: 13; font.bold: true; font.family: "SF Pro Rounded"
                }
            }
        }
    }

    function _fmtSpeed(bps) {
        if (bps > 1048576) return (bps / 1048576).toFixed(1) + " Mo/s"
        if (bps > 1024) return (bps / 1024).toFixed(0) + " Ko/s"
        return Math.round(bps) + " o/s"
    }
}
