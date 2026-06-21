import QtQuick
import QtQuick.VectorImage
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
    }
}
