import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell

RowLayout {
    id: root
    spacing: 15
    signal toggleCC()
    signal toggleSpotlight()

    FontLoader {
        id: macFont
        source: "../../../assets/fonts/SFPR/SF-Pro-Rounded-Regular.otf"
    }

    Volume {
        Layout.alignment: Qt.AlignVCenter
    }

    Battery {
        Layout.alignment: Qt.AlignVCenter
    }

    Wifi {
        Layout.alignment: Qt.AlignVCenter
    }

    // ── Bouton Spotlight ─────────────────────────────────────────────────
    Item {
        id: spotlightBtn
        width:  18
        height: 18
        Layout.alignment: Qt.AlignVCenter

        property bool hovered: false

        VectorImage {
            anchors.fill:          parent
            source:                Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/search.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled:         true
            layer.effect: MultiEffect {
                colorization:      1
                colorizationColor: spotlightBtn.hovered ? "#AAAAAA" : "#FFFFFF"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onEntered:    spotlightBtn.hovered = true
            onExited:     spotlightBtn.hovered = false
            onClicked:    root.toggleSpotlight()
        }
    }

    MouseArea {
        width: 16
        height: 16
        Layout.alignment: Qt.AlignVCenter
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.toggleCC()

        VectorImage {
            anchors.centerIn:      parent
            width:                 16
            height:                16
            source:                Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/control-center.svg")
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled:         true
            layer.effect: MultiEffect {
                colorization:      1
                colorizationColor: parent.containsMouse ? "#AAAAAA" : "#FFFFFF"
            }
        }
    }

    Text {
        text:           "AI"
        color:          "#FFFFFF"
        font.family:    macFont.name
        font.pixelSize: 13
        renderType:     Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
    }

    Clock {
        Layout.alignment: Qt.AlignVCenter
    }
}
