import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    readonly property var _firing: {
        for (var i = 0; i < AlarmState.alarms.length; i++) {
            if (AlarmState.alarms[i].id === AlarmState.firingAlarmId) return AlarmState.alarms[i]
        }
        return null
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._firing && root._firing.label ? root._firing.label : "Alarme"
            color: "#FFFFFF"
            font.pixelSize: 18
            font.bold: true
            font.family: "SF Pro Rounded"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._firing ? (String(root._firing.hour).padStart(2, "0") + ":" + String(root._firing.minute).padStart(2, "0")) : ""
            color: "#B0B0B0"
            font.pixelSize: 22
            font.family: "SF Pro Mono"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 30
                radius: 15
                color: "#2A2A2A"
                Text { anchors.centerIn: parent; text: "Répéter (9 min)"; color: "#FFFFFF"; font.pixelSize: 11; font.family: "SF Pro Rounded" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AlarmState.snoozeFiringAlarm(9) }
            }
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 30
                radius: 15
                color: "#1C7AFF"
                Text { anchors.centerIn: parent; text: "Arrêter"; color: "#FFFFFF"; font.pixelSize: 12; font.family: "SF Pro Rounded" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AlarmState.dismissFiringAlarm() }
            }
        }
    }
}
