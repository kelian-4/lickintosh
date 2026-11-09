pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.components.glass
import qs.services
import qs.ui.topbar.statusarea.notifcenter

WlSessionLockSurface {
    id: root

    readonly property bool themed: false

    required property WlSessionLock lock
    required property LockContext context

    readonly property bool unlocking: unlockAnim.running
    readonly property bool controlCenterAvailable: ShellConfig.options.lockscreen.showControlCenter
    property bool controlCenterOpen: false

    LiquidGlassBackdrop {
        id: lockBackdrop
        tint: "transparent"
        wallpaperPath: root.context.wallpaperSource.toString().replace(/^file:\/\//, "")
        screenSize: Qt.size(root.width, root.height)
        windowPosition: Qt.point(0, 0)
        blurRadius: 1.0

        Component.onCompleted: GlassRegistry.register(root, lockBackdrop)
        Component.onDestruction: GlassRegistry.unregister(lockBackdrop)
    }
    readonly property bool reduceMotion: ShellConfig.options.appearance.reduceMotion

    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property string timeText: Qt.formatTime(clock.date, "h:mm")
    readonly property string dateText: Qt.formatDate(clock.date, "ddd d MMM")

    function playUnlock() {
        if (unlockAnim.running) return
        unlockAnim.start()
    }

    Connections {
        target: root.context
        function onUnlocking() { root.playUnlock() }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration - 100; easing.type: Easing.InQuad }
            NumberAnimation { target: content; property: "scale"; to: 0.96; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration - 100; easing.type: Easing.InQuad }
            NumberAnimation { target: background; property: "opacity"; to: 0; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration; easing.type: Easing.InQuad }
        }
    }

    Item {
        id: background
        anchors.fill: parent
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: root.reduceMotion ? 1 : 200; easing.type: Easing.OutCubic }
        }

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.context.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true

            sourceSize: Qt.size(root.width * (root.screen?.devicePixelRatio ?? 1),
                                 root.height * (root.screen?.devicePixelRatio ?? 1))

            onStatusChanged: {
                if (status === Image.Ready) background.opacity = 1
            }

            scale: root.reduceMotion ? 1 : 1.04
            Behavior on scale {
                NumberAnimation { duration: root.reduceMotion ? 1 : 900; easing.type: Easing.OutCubic }
            }
            Component.onCompleted: {
                wallpaperImage.scale = 1
            }
        }

        Item {
            id: albumBackdrop
            anchors.fill: parent
            opacity: mediaPlayer.visible ? Math.max(0, Math.min(1, mediaPlayer.artT)) : 0
            visible: opacity > 0.003

            Rectangle {
                anchors.fill: parent
                color: "#0c0c10"
            }

            Image {
                id: albumImage
                anchors.fill: parent
                source: mediaPlayer.fileUrl(MprisState.artUrl)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(400, 400)
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: albumImage
                visible: albumImage.status === Image.Ready
                scale: 1.25
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                saturation: 0.25
                brightness: -0.16
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.12
        }
    }

    Item {
        id: content
        anchors.fill: parent

        opacity: reduceMotion ? 1 : 0
        scale: reduceMotion ? 1 : 1.06

        transform: Translate {
            id: contentTranslate
            y: root.reduceMotion ? 0 : -24
            Behavior on y {
                NumberAnimation { duration: root.reduceMotion ? 1 : 480; easing.type: Easing.OutCubic }
            }
        }

        Component.onCompleted: {
            content.opacity = 1
            content.scale = 1
            contentTranslate.y = 0
        }
        Behavior on opacity {
            NumberAnimation { duration: root.reduceMotion ? 1 : 380; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: root.reduceMotion ? 1 : 380; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.controlCenterOpen
            onClicked: root.controlCenterOpen = false
        }

        LockStatusIndicators {
            id: statusIndicators
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 24
        }

        MouseArea {
            visible: root.controlCenterAvailable
            anchors.fill: statusIndicators
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            onClicked: root.controlCenterOpen = !root.controlCenterOpen
        }

        LockControlCenter {
            id: lockControlCenter
            glassBackdrop: lockBackdrop
            open: root.controlCenterOpen && root.controlCenterAvailable
            anchors.top: statusIndicators.bottom
            anchors.topMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.06)
            text: root.dateText
            color: "#ffffff"
            opacity: 0.85
            font.family: "SF Pro Display"
            font.pixelSize: 16
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#40000000"
                shadowBlur: 0.6
            }
        }

        Row {
            id: clockRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dateLabel.bottom
            anchors.topMargin: 4
            spacing: 0

            layer.enabled: true

            layer.smooth: true

            readonly property var clockCfg: ShellConfig.options.lockscreen
            readonly property var clockStyle: LockClockStyle.styleAt(clockCfg.clockStyle)
            readonly property int clockWeightQt: LockClockStyle.weightFor(clockCfg.clockWeight)

            readonly property int baseDigitSize: Math.round(Math.min(root.width * 0.09, 92))
            readonly property int targetDigitSize: clockCfg.clockLarge ? baseDigitSize : Math.round(baseDigitSize * 0.58)

            property int digitSize: targetDigitSize
            onTargetDigitSizeChanged: digitSize = targetDigitSize
            Behavior on digitSize { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            readonly property var timeParts: root.timeText.split(":")

            readonly property color textColor: "#f2ffffff"

            Text {
                text: clockRow.timeParts[0] ?? ""
                color: clockRow.textColor
                font.family: clockRow.clockStyle.family
                font.italic: clockRow.clockStyle.italic
                font.letterSpacing: clockRow.clockStyle.spacing
                font.pixelSize: clockRow.digitSize
                font.weight: clockRow.clockWeightQt
                renderType: Text.NativeRendering
            }

            Text {
                text: ":"
                color: clockRow.textColor
                font.family: clockRow.clockStyle.family
                font.italic: clockRow.clockStyle.italic

                font.pixelSize: Math.round(clockRow.digitSize * 1.12)
                font.weight: clockRow.clockWeightQt
                renderType: Text.NativeRendering
                topPadding: -Math.round(clockRow.digitSize * 0.06)
            }

            Text {
                text: clockRow.timeParts[1] ?? ""
                color: clockRow.textColor
                font.family: clockRow.clockStyle.family
                font.italic: clockRow.clockStyle.italic
                font.letterSpacing: clockRow.clockStyle.spacing
                font.pixelSize: clockRow.digitSize
                font.weight: clockRow.clockWeightQt
                renderType: Text.NativeRendering
            }
        }

        ShaderEffectSource {
            id: clockBackdropSource
            anchors.fill: clockRow
            sourceItem: background
            sourceRect: Qt.rect(
                clockRow.mapToItem(content, 0, 0).x,
                clockRow.mapToItem(content, 0, 0).y,
                clockRow.width,
                clockRow.height
            )
            hideSource: false
            live: true
            visible: false
        }

        MultiEffect {
            id: clockBackdropBlur
            anchors.fill: clockRow
            source: clockBackdropSource
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            blurMultiplier: 1.2
            brightness: 0.15
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: clockRow

            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            visible: !clockGlass.glassOn
        }

        ShaderEffect {
            id: clockGlass
            anchors.fill: clockRow
            blending: true

            readonly property bool glassOn: lockBackdrop.ready && lockBackdrop.captureSettled
            visible: glassOn && clockRow.width > 0 && clockRow.height > 0

            property variant maskTex: clockRow
            property variant backTex: lockBackdrop.blurSource
            property vector2d size: Qt.vector2d(clockRow.width, clockRow.height)
            property vector2d screenOrigin: Qt.vector2d(0, 0)
            property vector2d backgroundSize: Qt.vector2d(lockBackdrop.screenSize.width, lockBackdrop.screenSize.height)
            property real ringRadius: Math.max(3, clockRow.digitSize * 0.075)
            property real thickness: clockRow.digitSize * 0.09
            property real highlightStrength: 0.55
            property real highlightWidth: Math.max(1.5, clockRow.digitSize * 0.033)
            property real saturation: 1.33
            property real lift: 0.10

            function syncOrigin() {
                var p = clockRow.mapToItem(null, 0, 0)
                if (p.x !== screenOrigin.x || p.y !== screenOrigin.y)
                    screenOrigin = Qt.vector2d(p.x, p.y)
            }

            Component.onCompleted: syncOrigin()
            onWidthChanged: syncOrigin()
            onHeightChanged: syncOrigin()

            Connections {
                target: clockGlass.Window.window
                ignoreUnknownSignals: true

                function onAfterAnimating() {
                    clockGlass.syncOrigin()
                }
            }

            vertexShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/GlyphGlass.vert.qsb")
            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/liquidglass/GlyphGlass.frag.qsb")
        }

        LockNotifications {
            id: notifStack
            glassBackdrop: lockBackdrop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: mediaPlayer.top
            anchors.bottomMargin: visible ? 16 : 0
        }

        LockMediaPlayer {
            id: mediaPlayer
            maxArt: loginArea.y - 20 - 138 - 22 - (clockRow.y + clockRow.height) - 28
            screenW: root.width
            lyricsH: Math.max(140, Math.min(root.height * 0.42, 440, loginArea.y - 20 - 150 - 24 - (clockRow.y + clockRow.height) - 28))
            glassBackdrop: lockBackdrop
            visible: ShellConfig.options.lockscreen.showMediaPlayer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: loginArea.top
            anchors.bottomMargin: (MprisState.hasPlayer && mediaPlayer.visible) ? 20 : 0
        }

        Column {
            id: loginArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(parent.height * 0.09)
            spacing: 8

            Item {
                id: avatarWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56
                height: 56

                CFClippingRect {
                    anchors.fill: parent
                    radius: width / 2

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: root.context.avatarUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0

                        sourceSize: Qt.size(56 * (root.screen?.devicePixelRatio ?? 1), 56 * (root.screen?.devicePixelRatio ?? 1))

                        Behavior on opacity {
                            NumberAnimation { duration: root.reduceMotion ? 1 : 150; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        opacity: avatarImg.status === Image.Ready ? 0 : 1
                        color: Qt.rgba(1, 1, 1, 0.14)

                        Behavior on opacity {
                            NumberAnimation { duration: root.reduceMotion ? 1 : 150; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: "#ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.35)
                    border.width: 1
                }
            }

            Item {
                id: passField
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 34

                readonly property bool active: passHasInteracted || passInput.text.length > 0

                property bool passHasInteracted: false

                Text {
                    anchors.centerIn: parent
                    text: Quickshell.env("USER") || ""
                    color: "#ffffff"
                    font.family: "SF Pro Display"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    opacity: passField.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                    }
                }

                CFClippingRect {
                    id: pill
                    anchors.fill: parent
                    radius: height / 2
                    opacity: passField.active ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                    }

                    BoxGlass {
                        anchors.fill: parent
                        backdrop: lockBackdrop
                        radius: pill.radius
                        color: Qt.rgba(1, 1, 1, 0.14)
                        light: Qt.rgba(1, 1, 1, 0.32)
                        rimStrength: 0.8
                        highlightEnabled: true
                    }

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 34
                        verticalAlignment: Text.AlignVCenter
                        color: "#ffffff"
                        font.family: "SF Pro Display"

                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.letterSpacing: 4
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        passwordMaskDelay: 0
                        clip: true
                        renderType: Text.NativeRendering
                        selectionColor: Qt.rgba(1, 1, 1, 0.35)
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        enabled: !root.context.unlockInProgress

                        focus: true
                        onActiveFocusChanged: {
                            if (!activeFocus && !root.unlocking)
                                passInput.forceActiveFocus()
                        }

                        Keys.onPressed: event => {
                            passField.passHasInteracted = true
                        }

                        property bool _syncingFromContext: false

                        onTextChanged: {
                            if (!_syncingFromContext)
                                root.context.updateText(text)
                        }
                        onAccepted: root.context.tryUnlock()

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                if (passInput.text === root.context.currentText)
                                    return
                                passInput._syncingFromContext = true
                                passInput.text = root.context.currentText
                                passInput._syncingFromContext = false
                            }
                            function onFailed() { wiggleAnim.restart() }
                        }

                        Text {
                            anchors.fill: parent
                            visible: passInput.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: qsTr("Enter Password")
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: "SF Pro Display"
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }
                    }

                    Rectangle {
                        id: submitRing
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.18)
                        opacity: passInput.text.length === 0 ? 0 : 1
                        visible: !root.context.unlockInProgress

                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u2192"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.context.tryUnlock()
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.context.unlockInProgress
                        text: "…"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 13
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    z: -1
                    onClicked: {
                        passField.passHasInteracted = true
                        passInput.forceActiveFocus()
                    }
                }

                SequentialAnimation {
                    id: wiggleAnim
                    loops: 1
                    running: false

                    PropertyAction { target: passField; property: "x"; value: 0 }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : -8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : 8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : -5; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : 5; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: 0; duration: 60; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                id: subtitleLabel
                anchors.horizontalCenter: parent.horizontalCenter
                width: passField.width + 16
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.context.lockMessage.length > 0
                    ? root.context.lockMessage
                    : (root.context.showFailure
                        ? qsTr("Wrong Password")
                        : (root.context.fprintActive
                            ? qsTr("Scanning fingerprint…")
                            : qsTr("Touch ID or Enter Password")))
                color: root.context.showFailure || root.context.lockMessage.length > 0
                    ? "#ffb4ab"
                    : Qt.rgba(1, 1, 1, 0.65)
                font.family: "SF Pro Display"
                font.weight: Font.DemiBold
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }
    }
}
