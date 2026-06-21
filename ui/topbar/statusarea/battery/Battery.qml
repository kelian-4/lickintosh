import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import Quickshell.Services.UPower

RowLayout {
    spacing: 4

    FontLoader {
        id: macFont
        source: "../../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    readonly property bool onBattery: UPower.onBattery
    readonly property real batPercentage: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 1
    readonly property bool charging: onBattery ? (UPower.displayDevice.state === 1 ) : true

    readonly property string batIcon: {
        let level = (batPercentage > 0.95) ? "100" :
                    (batPercentage > 0.85) ? "090" :
                    (batPercentage > 0.75) ? "080" :
                    (batPercentage > 0.65) ? "070" :
                    (batPercentage > 0.55) ? "060" :
                    (batPercentage > 0.45) ? "050" :
                    (batPercentage > 0.35) ? "040" :
                    (batPercentage > 0.25) ? "030" :
                    (batPercentage > 0.15) ? "020" :
                    (batPercentage > 0.05) ? "010" : "000";
        return "battery-" + level + (charging ? "-charging.svg" : ".svg");
    }

    Item {
        width: 22
        height: 22
        Layout.alignment: Qt.AlignVCenter

        VectorImage {
            id: batImg
            source: "../../../../assets/icons/battery/" + batIcon
            anchors.fill: parent
            preferredRendererType: VectorImage.CurveRenderer
        }
    }

    Text {
        text: Math.round(batPercentage * 100) + "%"
        color: "#FFFFFF"
        font.family: macFont.name
        font.pixelSize: 13
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }
}
