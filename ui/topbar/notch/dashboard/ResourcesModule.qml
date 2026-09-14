import QtQuick
import QtQuick.Layouts
import qs.services

// Calqué sur modules/dashboard/dash/Resources.qml de caelestia : trois
// jauges circulaires CPU / RAM / Disque. Leur version consomme des
// services C++ natifs (Caelestia.Services.Cpu/Memory/Storage) qu'on
// n'a pas ; mêmes définitions, réimplémentées via
// services/ResourcesState.qml (/proc, df).
Item {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 76

    component Ring: Item {
        id: ring
        property real percent: 0
        property string label: ""
        property string icon: ""
        property color ringColor: "#4ADE80"

        implicitWidth: 56
        implicitHeight: 56

        onPercentChanged: canvas.requestPaint()
        onRingColorChanged: canvas.requestPaint()

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#2A2A2A"
            border.width: 4
        }

        // Anneau de progression approximé par un arc via Canvas
        // (pas de QtQuick.Shapes.ArcItem disponible partout) — simple
        // et suffisant pour un indicateur de ce format.
        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var cx = width / 2, cy = height / 2, r = width / 2 - 2
                var start = -Math.PI / 2
                var end = start + (Math.PI * 2) * Math.min(1, Math.max(0, ring.percent / 100))
                ctx.strokeStyle = ring.ringColor
                ctx.lineWidth = 4
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.stroke()
            }
        }

        // Icône + pourcentage empilés au centre (caelestia montre une
        // icône dans l'anneau plutôt que le seul chiffre) — glyphes
        // génériques faute d'icônes SVG dédiées CPU/RAM/Disque dans
        // assets/, à ADAPTER si tu en as de meilleures sous la main.
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            Text { Layout.alignment: Qt.AlignHCenter; text: ring.icon; color: ring.ringColor; font.pixelSize: 13 }
            Text { Layout.alignment: Qt.AlignHCenter; text: Math.round(ring.percent) + "%"; color: "#FFFFFF"; font.pixelSize: 9; font.family: "SF Pro Rounded" }
        }

        Text {
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 2
            text: ring.label
            color: "#8A8A8A"
            font.pixelSize: 9
            font.family: "SF Pro Rounded"
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.cpuPercent;     label: "CPU";  icon: "⚙";  ringColor: "#1C7AFF" }
        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.memoryPercent;  label: "RAM";  icon: "▤";  ringColor: "#FBBF24" }
        Ring { Layout.alignment: Qt.AlignHCenter; percent: ResourcesState.storagePercent; label: "DISK"; icon: "▦";  ringColor: "#4ADE80" }
    }
}
