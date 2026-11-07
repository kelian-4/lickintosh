import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

Item {
    id: root
    property bool peek: false

    readonly property string kind: NotchState.primaryKind
    readonly property bool hasKind: root.kind !== "none"

    function _batteryIcon() {
        var level = Math.max(0, Math.min(100, Math.round(NotchState.batteryPercent / 10) * 10))
        return "battery/battery-" + String(level).padStart(3, "0") + "-charging.svg"
    }

    function _icon(k) {
        switch (k) {
            case "timer":          return "notch/clock.svg"
            case "stopwatch":      return "notch/clock.svg"
            case "alarm":          return "dropdown/clock.svg"
            case "notification":   return "notch/bell.svg"
            case "bluetooth":      return "bluetooth/bluetooth.svg"
            case "battery":        return root._batteryIcon()
            case "gamemode":       return Quickshell.shellDir + "/assets/icons_desktop/MacTahoe/actions/symbolic/gamepad-symbolic.svg"
            case "capture-camera": return "notch/camera.svg"
            case "capture-mic":    return "notch/mic.svg"
            default:               return ""
        }
    }

    function _label(k) {
        switch (k) {
            case "media":          return MprisState.trackArtist ? (MprisState.trackTitle + " — " + MprisState.trackArtist) : MprisState.trackTitle
            case "timer":          return TimerState.formatRemaining(TimerState.remainingMs)
            case "stopwatch":      return StopwatchState.formatElapsed(StopwatchState.elapsedMs)
            case "alarm":          return "Alarme"
            case "notification":   return NotchState.topUrgent ? NotchState.topUrgent.title : I18n.tr("Notification")
            case "bluetooth":      return NotchState.topUrgent ? NotchState.topUrgent.title : I18n.tr("Bluetooth")
            case "battery":        return "Charge · " + NotchState.batteryPercent + "%"
            case "gamemode":       return "Game Mode"
            case "capture-camera": return "Caméra active"
            case "capture-mic":    return "Micro actif"
            default:               return ""
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8
        visible: root.hasKind

        Rectangle {
            visible: root.kind === "media"
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            radius: 3
            color: "#2A2A2A"
            clip: true
            Image {
                anchors.fill: parent
                source: MprisState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MprisState.artUrl !== ""
            }
        }

        CFVI {
            visible: root.kind !== "media" && root.kind !== "none"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            size: 14
            icon: root._icon(root.kind)
            colorized: root.kind === "gamemode"
            color: "#ffffff"
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            visible: root.peek
            text: root._label(root.kind)
            color: "#FFFFFF"
            font.pixelSize: 12
            font.family: "SF Pro Text"
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        Item {
            Layout.fillWidth: true
            visible: !root.peek
        }

        Row {
            id: wave
            visible: root.kind === "media"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 14
            spacing: 2

            Repeater {
                model: [520, 380, 610, 440]

                delegate: Rectangle {
                    id: bar
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: 2.5
                    height: 4
                    radius: 1.25
                    color: "#FFFFFF"

                    SequentialAnimation on height {
                        running: wave.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 14; duration: bar.modelData; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 4; duration: bar.modelData; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}
