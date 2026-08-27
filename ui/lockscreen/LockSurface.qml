import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.ui.glass
import qs.ui.primitives

Item {
    id: root

    required property var context

    signal unlockAnimationFinished()

    function unlock() {
        fadeOutAnim.start()
    }

    property string _username: ""
    property string _time: ""
    property string _date: ""

    Process {
        id: whoamiProc
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._username = text.trim()
        }
    }

    Process {
        id: timeProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._time = text.trim()
        }
    }

    Process {
        id: dateProc
        command: ["date", "+%a %d %b"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._date = text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeProc.running = true
            dateProc.running = true
        }
    }

    PropertyAnimation {
        id: fadeOutAnim
        target: root
        property: "opacity"
        to: 0
        duration: 350
        easing.type: Easing.InOutQuad
        onStopped: root.unlockAnimationFinished()
    }

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/wallpapers/Colors/Colors 26 (1).jpeg")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.18
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: passwordField.forceActiveFocus()
    }

    ColumnLayout {
        id: clockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 70
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._date
            color: "#ffffff"
            font.family: "SF Pro Rounded"
            font.pixelSize: 20
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.3
                blurMax: 16
                brightness: 0.15
                shadowEnabled: true
                shadowColor: "#40ffffff"
                shadowBlur: 0.6
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._time
            color: "#ffffff"
            font.family: "SF Pro Rounded"
            font.pixelSize: 96
            font.weight: Font.Bold
            renderType: Text.NativeRendering
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.25
                blurMax: 20
                brightness: 0.15
                shadowEnabled: true
                shadowColor: "#40ffffff"
                shadowBlur: 0.8
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 92
            height: 92
            radius: 46
            color: "#25ffffff"
            border.color: "#1C7AFF"
            border.width: 2

            CFText {
                anchors.centerIn: parent
                text: root._username.length > 0 ? root._username.charAt(0).toUpperCase() : "?"
                font.pixelSize: 32
                font.weight: Font.Bold
            }
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            text: root._username
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            width: 160
            height: 30

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: Qt.rgba(1, 1, 1, 0.10)
                border.color: root.context.showFailure ? Qt.rgba(1, 0.42, 0.42, 0.5) : "transparent"
                border.width: 1
                opacity: passwordField.text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            TextField {
                id: passwordField
                anchors.fill: parent
                echoMode: TextInput.Password
                enabled: !root.context.unlockInProgress
                cursorVisible: passwordField.activeFocus && passwordField.text.length > 0
                color: "#ffffff"
                font.pixelSize: 11
                font.family: "SF Pro Rounded"
                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
                selectionColor: "#50ffffff"
                selectedTextColor: "#ffffff"
                background: Item {
                    CFText {
                        anchors.centerIn: parent
                        visible: passwordField.text.length === 0
                        text: root.context.showFailure ? "Mot de passe incorrect" : "Entrez le mot de passe"
                        color: root.context.showFailure ? "#FF6B6B" : Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 10
                    }
                }
                onTextChanged: root.context.currentText = text
                onAccepted: root.context.tryUnlock()
                Component.onCompleted: forceActiveFocus()

                SequentialAnimation {
                    id: wiggleAnim
                    PropertyAnimation { target: passwordField; property: "x"; to: passwordField.x - 8; duration: 60 }
                    PropertyAnimation { target: passwordField; property: "x"; to: passwordField.x + 8; duration: 60 }
                    PropertyAnimation { target: passwordField; property: "x"; to: passwordField.x - 5; duration: 60 }
                    PropertyAnimation { target: passwordField; property: "x"; to: passwordField.x; duration: 60 }
                }

                Connections {
                    target: root.context
                    function onFailed() {
                        passwordField.text = ""
                        wiggleAnim.start()
                        passwordField.forceActiveFocus()
                    }
                }
            }
        }

        CFText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: root.context.unlockInProgress
            text: "Vérification…"
            gray: true
            font.pixelSize: 11
        }
    }
}
