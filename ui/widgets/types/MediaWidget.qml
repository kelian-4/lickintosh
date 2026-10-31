import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"
    readonly property bool large: root.size === "l"
    readonly property bool compact: root.size === "s"

    GridLayout {
        anchors.fill: parent
        columns: root.large ? 1 : 2
        columnSpacing: 14
        rowSpacing: 10

        Rectangle {
            Layout.preferredWidth: root.large ? -1 : (root.compact ? 60 : 96)
            Layout.preferredHeight: root.large ? 190 : (root.compact ? 60 : 96)
            Layout.fillWidth: root.large
            Layout.alignment: root.large ? Qt.AlignTop : Qt.AlignVCenter
            radius: 12
            color: "#2a2a3a"
            clip: true

            Image {
                anchors.fill: parent
                source: MprisState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MprisState.artUrl !== ""
            }

            CFVI {
                anchors.centerIn: parent
                size: 26
                gray: true
                icon: "notch/music.svg"
                visible: MprisState.artUrl === ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: MprisState.hasPlayer ? (MprisState.trackTitle !== "" ? MprisState.trackTitle : "Unknown") : "Not Playing"
                elide: Text.ElideRight
                color: root.look.primary
                font.pixelSize: 14
                font.weight: Font.Medium
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                visible: MprisState.trackArtist !== ""
                text: MprisState.trackArtist
                elide: Text.ElideRight
                color: root.look.secondary
                font.pixelSize: 12
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
            }

            RowLayout {
                Layout.topMargin: 6
                spacing: 16
                visible: !root.compact

                Repeater {
                    model: [
                        { icon: "music/backward.svg", action: "previous" },
                        { icon: "music/play.svg", action: "toggle" },
                        { icon: "music/forward.svg", action: "next" }
                    ]

                    delegate: Item {
                        id: control
                        required property var modelData
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26

                        CFVI {
                            anchors.centerIn: parent
                            size: 20
                            icon: control.modelData.action === "toggle" && MprisState.isPlaying ? "music/pause.svg" : control.modelData.icon
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (control.modelData.action === "previous") MprisState.previous()
                                else if (control.modelData.action === "next") MprisState.next()
                                else MprisState.togglePlaying()
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.compact
        cursorShape: Qt.PointingHandCursor
        onClicked: MprisState.togglePlaying()
    }
}
