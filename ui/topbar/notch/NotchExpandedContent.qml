import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.topbar.notch.activities

/*
    En "expanded" (clic sur la notch) :
      - Un évènement vraiment URGENT/transitoire (alarme qui sonne,
        minuteur terminé, notification, connexion Bluetooth) prend
        l'écran en entier temporairement — c'est voulu, ça expire seul.
      - Sinon, TOUJOURS le hub (NotchDashboard), même si un "mode"
        continu est actif (Game Mode, média, batterie en charge,
        caméra/micro) : ces états restent visibles comme petits badges
        DANS le hub (cf. NotchDashboard.qml), jamais en accaparant tout
        l'écran — pour qu'on puisse toujours accéder au reste de la
        notch, avec juste un petit bouton pour désactiver le mode.
*/
Item {
    id: root

    readonly property bool isDashboard: !NotchState.hasUrgentActivity
    readonly property string kind: root.isDashboard ? "none" : NotchState.primaryKind

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.fillWidth: true
            visible: !root.isDashboard
            text: root.title(root.kind)
            color: "#FFFFFF"
            font.pixelSize: 13
            font.bold: true
            font.family: "SF Pro Text"
        }

        PageLoader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            index: root.pageIndex(root.kind)
            pages: [dashboardComp, timerComp, alarmComp, notificationComp, bluetoothComp]
        }
    }

    Component { id: timerComp;        TimerActivity {} }
    Component { id: alarmComp;        AlarmActivity {} }
    Component { id: notificationComp; NotificationActivity {} }
    Component { id: bluetoothComp;    BluetoothActivity {} }
    Component { id: dashboardComp;    NotchDashboard {} }

    function pageIndex(k) {
        switch (k) {
            case "timer":        return 1
            case "alarm":        return 2
            case "notification": return 3
            case "bluetooth":    return 4
            default:             return 0
        }
    }

    function title(k) {
        switch (k) {
            case "timer":        return "Minuteur"
            case "alarm":        return "Alarme"
            case "notification": return "Notification"
            case "bluetooth":    return "Bluetooth"
            default:             return ""
        }
    }
}
