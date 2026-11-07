pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.components
import qs.components.glass
import qs.services

Item {
    id: root

    property Item glassBackdrop: null
    property bool open: false

    readonly property int box: ControlCatalog.box
    readonly property int boxMargin: ControlCatalog.boxMargin
    readonly property int cols: 4
    readonly property int rows: hasBacklight ? 3 : 2

    readonly property bool wifiOn: NetworkManager.wifiEnabled
    readonly property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property bool focusOn: NotifService.dndEnabled

    property bool hasBacklight: false
    property real brtValue: 0.5

    implicitWidth: box * cols + boxMargin * (cols + 1)
    implicitHeight: box * rows + boxMargin * (rows + 1)
    width: implicitWidth
    height: implicitHeight

    visible: opacity > 0
    opacity: root.open ? 1 : 0
    scale: root.open ? 1 : 0.95
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
    Behavior on scale   { NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }

    function gridX(c) { return c * (root.box + root.boxMargin) + root.boxMargin }
    function gridY(r) { return r * (root.box + root.boxMargin) + root.boxMargin }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Process {
        id: _brtProbe
        command: ["sh", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBacklight = text.trim() !== ""
                if (root.hasBacklight) _brtGet.running = true
            }
        }
    }

    Process {
        id: _brtGet
        command: ["brightnessctl", "-e2", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split(",")
                if (f.length >= 5) {
                    var pct = parseFloat(f[3])
                    if (isFinite(pct)) root.brtValue = pct / 100
                }
            }
        }
    }

    Process { id: _brtSet }

    Timer {
        id: _brtT
        interval: 50
        onTriggered: {
            _brtSet.command = ["brightnessctl", "-e2", "set", Math.round(root.brtValue * 100) + "%"]
            _brtSet.running = true
        }
    }

    onOpenChanged: {
        if (root.open) _brtProbe.running = true
    }

    component BoxButton: BoxGlass {
        id: boxbutton
        radius: 40
        backdrop: root.glassBackdrop
        property bool enabled: false
        property bool isPressed: false
        property int xPos: 0
        property int yPos: 0

        x: root.gridX(boxbutton.xPos)
        y: root.gridY(boxbutton.yPos)
        scale: boxbutton.isPressed ? 0.93 : 1.0
        transformOrigin: Item.Top
        Behavior on scale {
            NumberAnimation { duration: ShellMotion.spatial(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.spatialCurve }
        }

        light: "transparent"
        rimStrength: boxbutton.enabled ? 0 : 1.0
        color: boxbutton.enabled ? "#fff" : "transparent"
        Behavior on color { ColorAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve } }
    }

    BoxButton {
        id: wifiBox
        xPos: 0
        yPos: 0
        width: root.box * 2 + root.boxMargin
        height: root.box

        CFClippingRect {
            id: wifiCircle
            width: 34
            height: 34
            radius: 17
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            color: root.wifiOn ? "#fff" : Qt.rgba(1, 1, 1, 0.18)
            Behavior on color { ColorAnimation { duration: ShellMotion.fade() } }

            CFVI {
                anchors.centerIn: parent
                width: 25
                height: 25
                icon: "wifi/nm-signal-100-symbolic.svg"
                color: root.wifiOn ? Theme.accent : "#fff"
            }
        }

        Column {
            anchors.left: wifiCircle.right
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter

            CFText {
                text: I18n.tr("Wi-Fi")
                font.weight: Font.Bold
                font.pixelSize: 12
                color: Theme.ink(parent, false)
            }
            CFText {
                text: root.wifiOn && NetworkManager.active ? NetworkManager.active.ssid : (root.wifiOn ? "Wi-Fi" : I18n.tr("Off"))
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.55)
                width: root.box - 10
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: NetworkManager.enableWifi(!root.wifiOn)
            onPressed: wifiBox.isPressed = true
            onReleased: wifiBox.isPressed = false
            onCanceled: wifiBox.isPressed = false
        }
    }

    BoxButton {
        id: btBox
        xPos: 2
        yPos: 0
        width: root.box
        height: root.box
        enabled: root.btOn

        CFClippingRect {
            anchors.centerIn: parent
            width: 38
            height: 38
            radius: 19
            color: root.btOn ? "#fff" : Qt.rgba(1, 1, 1, 0.18)
            Behavior on color { ColorAnimation { duration: ShellMotion.fade() } }

            CFVI {
                anchors.centerIn: parent
                width: 30
                height: 30
                icon: "bluetooth/bluetooth.svg"
                color: root.btOn ? Theme.accent : "#fff"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
            onPressed: btBox.isPressed = true
            onReleased: btBox.isPressed = false
            onCanceled: btBox.isPressed = false
        }
    }

    BoxButton {
        id: focusBox
        xPos: 3
        yPos: 0
        width: root.box
        height: root.box
        enabled: root.focusOn

        CFVI {
            anchors.centerIn: parent
            icon: "dnd.svg"
            size: 26
            color: root.focusOn ? "#8E44AD" : "#fff"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: NotifService.dndEnabled = !NotifService.dndEnabled
            onPressed: focusBox.isPressed = true
            onReleased: focusBox.isPressed = false
            onCanceled: focusBox.isPressed = false
        }
    }

    BoxButton {
        xPos: 0
        yPos: 1
        width: root.box * 4 + root.boxMargin * 3
        height: root.box
        radius: 25
        visible: root.hasBacklight

        CFSlider {
            autoHideHandle: true
            glassBackdrop: root.glassBackdrop
            focusPolicy: Qt.NoFocus
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            value: root.brtValue
            onMoved: {
                root.brtValue = value
                _brtT.restart()
            }
        }
        CFVI {
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: "sun-small.svg"
            size: 14
        }
        CFVI {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: "sun-huge.svg"
            size: 18
        }
    }

    BoxButton {
        xPos: 0
        yPos: root.hasBacklight ? 2 : 1
        width: root.box * 4 + root.boxMargin * 3
        height: root.box
        radius: 25

        CFSlider {
            autoHideHandle: true
            glassBackdrop: root.glassBackdrop
            focusPolicy: Qt.NoFocus
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            value: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
            onMoved: {
                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                    Pipewire.defaultAudioSink.audio.volume = value
                }
            }
        }
        CFVI {
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: "volume/audio-volume-1.svg"
            size: 14
        }
        CFVI {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            icon: "volume/audio-volume-3.svg"
            size: 18
        }
    }
}
