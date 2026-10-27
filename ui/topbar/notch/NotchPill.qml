import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import qs.services

/*
    Contenu compact : icône réelle du projet (assets/icons/...), pas
    un glyphe inventé — chemins relatifs depuis ui/topbar/notch/ (3
    niveaux jusqu'à la racine), même convention que le FontLoader de
    TopBar.qml ("../../../assets/...").
*/
Item {
    id: root
    property bool peek: false

    readonly property string kind: NotchState.primaryKind
    readonly property bool hasKind: root.kind !== "none"

    function _icon(k) {
        switch (k) {
            case "timer":          return "../../../assets/icons/notch/clock.svg"
            case "stopwatch":      return "../../../assets/icons/notch/clock.svg"
            case "alarm":          return "../../../assets/icons/dropdown/clock.svg"
            case "notification":   return "../../../assets/icons/notch/bell.svg"
            case "bluetooth":      return "../../../assets/icons/bluetooth/bluetooth.svg"
            case "battery":        return "../../../assets/icons/battery/zap.svg"
            case "gamemode":       return "../../../assets/icons/notch/award.svg"
            case "capture-camera": return "../../../assets/icons/notch/camera.svg"
            case "capture-mic":    return "../../../assets/icons/notch/mic.svg"
            default:               return ""
        }
    }

    function _label(k) {
        switch (k) {
            case "media":          return MprisState.trackArtist ? (MprisState.trackTitle + " — " + MprisState.trackArtist) : MprisState.trackTitle
            case "timer":          return TimerState.formatRemaining(TimerState.remainingMs)
            case "stopwatch":      return StopwatchState.formatElapsed(StopwatchState.elapsedMs)
            case "alarm":          return "Alarme"
            case "notification":   return NotchState.topUrgent ? NotchState.topUrgent.title : "Notification"
            case "bluetooth":      return NotchState.topUrgent ? NotchState.topUrgent.title : "Bluetooth"
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

        // Le média n'a pas d'icône SVG dédiée dans assets/ : on montre
        // la pochette (Mpris) si disponible, sinon un simple carré vide
        // plutôt que d'inventer un glyphe.
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

        VectorImage {
            visible: root.kind !== "media" && root.kind !== "none"
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            source: root._icon(root.kind)
            preferredRendererType: VectorImage.CurveRenderer
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            visible: root.peek
            text: root._label(root.kind)
            color: "#FFFFFF"
            font.pixelSize: 12
            font.family: "SF Pro Rounded"
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
    }
}
