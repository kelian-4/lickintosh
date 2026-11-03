import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import qs.services
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root

    property int iconSize: 20
    property string color: "#fff"
    property var adapter: Bluetooth.defaultAdapter
    property bool bluetoothOn: adapter ? adapter.enabled : false

    implicitWidth: iconSize
    implicitHeight: iconSize

    VectorImage {
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/bluetooth/bluetooth.svg")
        width: root.iconSize
        height: root.iconSize
        anchors.centerIn: parent
        preferredRendererType: VectorImage.CurveRenderer
        opacity: bluetoothOn ? 1.0 : 0.4
        layer.enabled: Theme.themed(root) && Theme.isLight
        layer.effect: MultiEffect { colorization: 1; colorizationColor: Theme.textPrimary }
    }
}
