import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.components.glass
import qs.services

Item {
    id: root

    property bool opened: false
    signal closeRequested()
    signal openAbout()
    signal lockRequested()
    signal powerRequested(string action)

    readonly property int menuWidth: 260
    readonly property int rowHeight: 30
    readonly property color hoverColor: Qt.rgba(1, 1, 1, 0.9)
    readonly property color sepColor:   Qt.rgba(1, 1, 1, 0.10)
    readonly property color textColor:  "#FFFFFF"
    readonly property color hoverTextColor: "#000000"
    readonly property color dimColor:   Qt.rgba(1, 1, 1, 0.35)

    implicitWidth:  menuWidth
    implicitHeight: menuCol.implicitHeight + 12

    Process {
        id: _openSettings
        command: ["quickshell", "-p", Quickshell.shellDir + "/settings.qml"]
        running: false
    }

    function openSettingsApp() {
        SettingsLauncher.open("")
    }

    readonly property var packageSites: ({
        "arch": "https://archlinux.org/packages/",
        "manjaro": "https://packages.manjaro.org/",
        "debian": "https://packages.debian.org/",
        "ubuntu": "https://packages.ubuntu.com/",
        "fedora": "https://packages.fedoraproject.org/",
        "opensuse": "https://software.opensuse.org/",
        "nixos": "https://search.nixos.org/packages",
        "gentoo": "https://packages.gentoo.org/",
        "alpine": "https://pkgs.alpinelinux.org/packages",
        "void": "https://voidlinux.org/packages/"
    })
    property string distroIds: ""
    readonly property string packagesUrl: {
        const ids = distroIds.split(/\s+/).filter(x => x.length > 0)
        for (const id of ids) {
            if (packageSites[id]) return packageSites[id]
            if (id.indexOf("opensuse") === 0) return packageSites["opensuse"]
        }
        return ""
    }

    Process {
        id: _distro
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; echo \"$ID $ID_LIKE\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.distroIds = text.trim().toLowerCase()
        }
    }

    Process { id: _suspend;  command: ["systemctl", "suspend"];  running: false }
    Process { id: _kill;     command: ["sh", "-c", "hyprctl kill"];          running: false }

    
    BoxGlass {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(0.08, 0.08, 0.08, 0.75)
        rimStrength: 1.7
        light: "#20ffffff"
    }

    

    component MenuRow: Item {
        id: _mr
        property string label: ""
        property string shortcut: ""
        property string icon: ""
        property bool dimmed: false
        property bool hasSub: false
        signal activated()

        height: root.rowHeight
        width: root.menuWidth

        property bool _hovered: false

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            radius: 5
            color: _mr._hovered && !_mr.dimmed ? root.hoverColor : "transparent"
        }

        VectorImage {
            id: _icon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: _mr.icon !== "" ? Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/" + _mr.icon) : ""
            visible: _mr.icon !== ""
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: _mr._hovered ? "#000000" : "#FFFFFF"
            }
        }

        Text {
            anchors.left: _mr.icon !== "" ? _icon.right : parent.left
            anchors.leftMargin: _mr.icon !== "" ? 10 : 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.label
            color: _mr.dimmed ? root.dimColor : (_mr._hovered ? root.hoverTextColor : root.textColor)
            font.pixelSize: 13
            renderType: Text.NativeRendering
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: _mr.shortcut
            color: _mr._hovered ? root.hoverTextColor : Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 12
            renderType: Text.NativeRendering
            visible: !_mr.hasSub
        }

        VectorImage {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/chevron-right.svg")
            visible: _mr.hasSub
            preferredRendererType: VectorImage.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: _mr._hovered ? "#000000" : "#FFFFFF"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: _mr.dimmed ? Qt.ArrowCursor : Qt.PointingHandCursor
            onEntered: _mr._hovered = true
            onExited:  _mr._hovered = false
            onClicked: if (!_mr.dimmed) _mr.activated()
        }
    }

    component MenuSep: Rectangle {
        height: 1
        width: root.menuWidth - 20
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.sepColor
    }

    
    Column {
        id: menuCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 6
        spacing: 2

        MenuRow {
            label: I18n.tr("About this Mac")
            icon: "dropdown/mac.svg"
            onActivated: {
                root.openAbout()
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            label: I18n.tr("System Settings…")
            icon: "dropdown/settings.svg"
            onActivated: {
                root.openSettingsApp()
                root.closeRequested()
            }
        }
        MenuRow {
            label: I18n.tr("App Store")
            icon: "dropdown/store.svg"
            dimmed: root.packagesUrl === ""
            onActivated: {
                if (root.packagesUrl === "") return
                Quickshell.execDetached(["xdg-open", root.packagesUrl])
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            id: recentRow
            label: I18n.tr("Recent Items")
            icon: "dropdown/clock.svg"
            hasSub: true
        }

        MenuSep {}

        MenuRow {
            label: I18n.tr("Force Quit…")
            icon: "notch/x-circle.svg"
            shortcut: "⇧⌘⌫"
            onActivated: _kill.running = true
        }

        MenuSep {}

        MenuRow {
            label: I18n.tr("Sleep")
            icon: "dropdown/sleep.svg"
            onActivated: _suspend.running = true
        }
        MenuRow {
            label: I18n.tr("Restart…")
            icon: "dropdown/reload.svg"
            onActivated: {
                root.powerRequested("reboot")
                root.closeRequested()
            }
        }
        MenuRow {
            label: I18n.tr("Shut Down…")
            icon: "dropdown/power.svg"
            onActivated: {
                root.powerRequested("poweroff")
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            label: I18n.tr("Log Out…")
            icon: "notch/log-out.svg"
            onActivated: {
                root.powerRequested("logout")
                root.closeRequested()
            }
        }

        MenuSep {}

        MenuRow {
            label: I18n.tr("Lock Screen")
            icon: "dropdown/lock.svg"
            shortcut: "⌃⌘L"
            onActivated: {
                root.lockRequested()
                root.closeRequested()
            }
        }

        Item { height: 4; width: 1 }
    }

    readonly property bool recentOpen: recentRow._hovered || recentSub.hovered
    property bool recentShown: false

    onRecentOpenChanged: {
        if (recentOpen) {
            recentHide.stop()
            recentShown = true
        } else {
            recentHide.restart()
        }
    }

    onOpenedChanged: {
        if (opened) RecentFiles.refresh()
        else recentShown = false
    }

    Timer {
        id: recentHide
        interval: 120
        onTriggered: root.recentShown = false
    }

    Item {
        id: recentSub
        readonly property bool hovered: subHover.hovered
        readonly property var items: RecentFiles.files.slice(0, 10)
        x: root.menuWidth - 4
        y: menuCol.y + recentRow.y - 6
        width: 280
        height: subCol.implicitHeight + 12
        visible: opacity > 0
        opacity: root.recentShown ? 1 : 0
        z: 5

        Behavior on opacity {
            NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
        }

        HoverHandler { id: subHover }

        BoxGlass {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(0.08, 0.08, 0.08, 0.75)
            rimStrength: 1.7
            light: "#20ffffff"
        }

        Column {
            id: subCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 6
            spacing: 2

            Item {
                visible: recentSub.items.length === 0
                width: recentSub.width
                height: root.rowHeight

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("No Recent Items")
                    color: root.dimColor
                    font.pixelSize: 13
                    renderType: Text.NativeRendering
                }
            }

            Repeater {
                model: recentSub.items

                delegate: Item {
                    id: recentItem
                    required property string modelData
                    property bool hovered: false

                    width: recentSub.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        radius: 5
                        color: recentItem.hovered ? root.hoverColor : "transparent"
                    }

                    Image {
                        id: recentIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        sourceSize: Qt.size(64, 64)
                        mipmap: true
                        source: IconResolver.byName(IconResolver.fileIconName(RecentFiles.nameOf(recentItem.modelData)))
                    }

                    Text {
                        anchors.left: recentIcon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: RecentFiles.nameOf(recentItem.modelData)
                        elide: Text.ElideMiddle
                        color: recentItem.hovered ? root.hoverTextColor : root.textColor
                        font.pixelSize: 13
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: recentItem.hovered = true
                        onExited: recentItem.hovered = false
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", recentItem.modelData])
                            root.closeRequested()
                        }
                    }
                }
            }
        }
    }

    opacity: opened ? 1 : 0
    scale:   opened ? 1 : 0.95
    transformOrigin: Item.TopLeft

    Behavior on opacity {
        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
    }
    Behavior on scale {
        NumberAnimation { duration: ShellMotion.fade(); easing.type: Easing.BezierSpline; easing.bezierCurve: ShellMotion.effectsCurve }
    }
}
