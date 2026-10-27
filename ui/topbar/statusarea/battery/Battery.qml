import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import Quickshell.Services.UPower
import qs.services

RowLayout {
    id: root
    spacing: 4
    visible: ShellConfig.options.topbar.batteryVisible

    signal toggleBattery(int xPos)

    FontLoader {
        id: macFont
        source: "../../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    readonly property bool onBattery:     UPower.onBattery
    readonly property real batPercentage: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 1
    readonly property bool charging:      onBattery ? (UPower.displayDevice.state === 1) : true
    readonly property string batIcon: {
        var level = (batPercentage > 0.95) ? "100" :
                    (batPercentage > 0.85) ? "090" :
                    (batPercentage > 0.75) ? "080" :
                    (batPercentage > 0.65) ? "070" :
                    (batPercentage > 0.55) ? "060" :
                    (batPercentage > 0.45) ? "050" :
                    (batPercentage > 0.35) ? "040" :
                    (batPercentage > 0.25) ? "030" :
                    (batPercentage > 0.15) ? "020" :
                    (batPercentage > 0.05) ? "010" : "000"
        return "battery-" + level + (charging ? "-charging.svg" : ".svg")
    }

    Item {
        id: _batBtn
        width:  22
        height: 22
        Layout.alignment: Qt.AlignVCenter
        visible: ShellConfig.options.topbar.batteryIconVisible

        VectorImage {
            source: "../../../../assets/icons/battery/" + root.batIcon
            anchors.fill: parent
            preferredRendererType: VectorImage.CurveRenderer
        }

        MouseArea {
            anchors.fill:    parent
            anchors.margins: -4
            cursorShape:     Qt.PointingHandCursor
            onClicked:       root.toggleBattery(_batBtn.mapToItem(null, _batBtn.width / 2, 0).x)
        }
    }

    Text {
        id: _pctText
        text:           Math.round(root.batPercentage * 100) + "%"
        color:          "#FFFFFF"
        font.family:    macFont.name
        font.pixelSize: 13
        renderType:     Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
        visible: ShellConfig.options.topbar.batteryTextVisible
    }
}
