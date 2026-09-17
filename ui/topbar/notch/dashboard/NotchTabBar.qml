import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell

/*
    Port de modules/dashboard/Tabs.qml (caelestia-dots/shell, GPLv3) :
    icone au-dessus du libelle sur CHAQUE onglet (pas seulement l'actif),
    largeur uniforme, et un seul indicateur (pilule pleine largeur de
    l'onglet actif) qui glisse sous la barre au lieu d'un soulignement
    par onglet.
*/
Item {
    id: root
    property int currentIndex: 0
    readonly property var tabs: [
        { label: "Dashboard",   icon: "grid.svg" },
        { label: "Media",       icon: "music.svg" },
        { label: "Performance", icon: "bar-chart2.svg" },
        { label: "Weather",     icon: "cloud.svg" }
    ]

    Layout.fillWidth: true
    Layout.topMargin: 4
    Layout.bottomMargin: 2
    implicitHeight: bar.implicitHeight + 5 + indicator.height + 1

    RowLayout {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Repeater {
            model: root.tabs

            delegate: Item {
                id: tabDelegate
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: content.implicitHeight

                ColumnLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: 3

                    VectorImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/notch/" + tabDelegate.modelData.icon)
                        preferredRendererType: VectorImage.CurveRenderer
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: root.currentIndex === tabDelegate.index ? "#1C7AFF" : "#8A8A8A"
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: tabDelegate.modelData.label
                        color: root.currentIndex === tabDelegate.index ? "#1C7AFF" : "#8A8A8A"
                        font.pixelSize: 12
                        font.family: "SF Pro Rounded"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentIndex = tabDelegate.index
                }
            }
        }
    }

    Item {
        id: indicator
        anchors.top: bar.bottom
        anchors.topMargin: 5
        clip: true
        readonly property real _tabWidth: bar.width / root.tabs.length
        width: _tabWidth
        height: 3
        x: _tabWidth * root.currentIndex

        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#1C7AFF"
        }
    }

    Rectangle {
        anchors.top: indicator.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#2A2A2A"
    }
}
