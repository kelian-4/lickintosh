import QtQuick
import QtQuick.VectorImage
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int iconSize: 20
    property string color: "#fff"

    property int networkStrength: 0
    property bool nmcliExists: true

    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: {
                if (!debounceTimer.running) {
                    debounceTimer.start();
                }
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 500 
        repeat: false
        onTriggered: fetchSignal.running = true
    }

    Process {
        id: fetchSignal
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\\*' | cut -d':' -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let strength = parseInt(text.trim());
                if (!isNaN(strength)) {
                    root.networkStrength = strength;
                } else {
                    root.networkStrength = 0;
                }
            }
        }
    }

    Component.onCompleted: fetchSignal.running = true

    property string networkIcon: {
        if (networkStrength == 0) return "wifi-off-clear.svg";
        if (networkStrength > 90) return "nm-signal-100-symbolic.svg";
        if (networkStrength > 66) return "nm-signal-66-symbolic.svg";
        if (networkStrength > 33) return "nm-signal-33-symbolic.svg";
        return "nm-signal-0-symbolic.svg";
    }

    implicitWidth: iconSize
    implicitHeight: iconSize

    VectorImage {
        source: "../../../../assets/icons/wifi/" + networkIcon
        width: root.iconSize
        height: root.iconSize
        anchors.centerIn: parent
        preferredRendererType: VectorImage.CurveRenderer
    }
}
