import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "I18n.js" as I18n
import "Fonts.js" as Fonts

Scope {
    id: root
    property var host: null
    readonly property bool darkMode: host ? host.darkMode : true
    readonly property string fam: host ? host.fam : "SF Pro Text"
    readonly property color accent: host ? host.accent : "#0A84FF"
    readonly property var plan: host ? host.plan : null
    readonly property bool planning: host ? host.planBusy : false
    readonly property var groups: host ? host.groups : []
    function stateOf(p) { return host ? host.stateOf(p) : ""; }
    function reasonOf(p) { return host ? host.reasonOf(p) : ""; }
    function hideWin(w) { w.visible = false; }

    property int step: 0
    readonly property var steps: [I18n.tr("Introduction"), I18n.tr("Components"), I18n.tr("Installation"), I18n.tr("Summary")]
    property bool running: false
    property string log: ""
    property string result: ""
    readonly property int toInstall: plan && plan.supported && plan.repo ? plan.repo.length : 0

    function open() {
        step = 0; result = ""; log = "";
        win.visible = true; win.raise(); win.requestActivate();
        if (host) host.runPlan();
    }
    function install() {
        if (!plan || toInstall === 0 || running) return;
        running = true; result = ""; log = "";
        installProc.command = ["sh", "-c", "LICKINTOSH_ROOT_CMD=pkexec fish \"$1\" -y --deps-only 2>&1; echo \"[exit $?]\"", "sh", host.script];
        installProc.running = true;
    }
    Process {
        id: installProc
        stdout: SplitParser {
            onRead: line => {
                var m = /^\[exit (\d+)\]$/.exec(line);
                if (m) {
                    root.running = false;
                    root.result = m[1] === "0" ? "ok" : (m[1] === "126" || m[1] === "127" ? "cancelled" : "failed");
                    if (root.host) root.host.runPlan();
                    if (root.result === "ok") root.step = 3;
                    return;
                }
                root.log += line.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "") + "\n";
                if (root.log.length > 12000) root.log = root.log.slice(-12000);
            }
        }
    }

    Window {
        id: win
        onClosing: close => { close.accepted = false; root.hideWin(win); }
        title: "Install Dependencies"
        onVisibleChanged: if (visible) { floatTries = 0; floatTimer.restart(); }
        property int floatTries: 0
        Timer {
            id: floatTimer
            interval: 60
            repeat: true
            onTriggered: {
                var sel = 'window = "title:^(' + win.title + ')$"';
                Hyprland.dispatch('hl.dsp.window.float({ action = "enable", ' + sel + ' })');
                Hyprland.dispatch('hl.dsp.window.set_prop({ prop = "border_size", value = "0", ' + sel + ' })');
                Hyprland.dispatch('hl.dsp.window.set_prop({ prop = "rounding", value = "12", ' + sel + ' })');
                if (win.floatTries >= 2) {
                    Hyprland.dispatch('hl.dsp.window.resize({ x = ' + win.width + ', y = ' + win.height + ', "exact", ' + sel + ' })');
                    Hyprland.dispatch('hl.dsp.window.center({ ' + sel + ' })');
                }
                if (++win.floatTries >= 12) stop();
            }
        }
        width: 720; height: 480
        minimumWidth: 640; minimumHeight: 440
        visible: false
        color: "transparent"
        flags: Qt.Window | Qt.FramelessWindowHint

        QtObject {
            id: pal
            readonly property bool dark: root.darkMode
            property color bg: dark ? "#1E1E1E" : "#F5F5F7"
            Behavior on bg { ColorAnimation { duration: 260 } }
            property color side: dark ? "#262628" : "#ECECEE"
            Behavior on side { ColorAnimation { duration: 260 } }
            property color card: dark ? "#2C2C2E" : "#FFFFFF"
            Behavior on card { ColorAnimation { duration: 260 } }
            property color text: dark ? "#F5F5F7" : "#1D1D1F"
            property color text2: dark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.55)
            property color text3: dark ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0, 0, 0, 0.32)
            property color sep: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.09)
            property color pill: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07)
            property color border: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.2)
            property color lightOff: dark ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.15)
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: pal.bg
            border.width: 1; border.color: pal.border
            clip: true

            Rectangle {
                id: side
                width: 200; height: parent.height
                color: pal.side
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: pal.sep }
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
                Item {
                    x: 17; y: 15; width: 58; height: 14
                    Row {
                        scale: 0.93; transformOrigin: Item.TopLeft      // a touch smaller
                        spacing: 8
                        Repeater {
                            model: [{ c: "#FF5F57", g: "×" }, { c: "#FEBC2E", g: "−" }, { c: "#28C840", g: "↗" }]
                            delegate: Rectangle {
                                required property var modelData
                                width: 14; height: 14; radius: 7
                                color: (win.active || tlMa.containsMouse) ? modelData.c : pal.lightOff
                                Behavior on color { ColorAnimation { duration: 220 } }
                                border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.14)
                                TLGlyph { anchors.fill: parent; kind: parent.modelData.g; opacity: tlMa.containsMouse ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 140 } } }
                            }
                        }
                    }
                    MouseArea {
                        id: tlMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: mouse => { if (mouse.x < 22) root.hideWin(win); }
                    }
                }
                                Image {
                    x: 24; y: 58; width: 60; height: 60
                    source: Qt.resolvedUrl("../assets/icons/logo.svg")
                    sourceSize: Qt.size(120, 120)
                    smooth: true; mipmap: true
                }
                Column {
                    x: 24; y: 140
                    spacing: 14
                    Repeater {
                        model: root.steps
                        delegate: Row {
                            required property string modelData
                            required property int index
                            spacing: 10
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10; height: 10; radius: 5
                                color: parent.index <= root.step ? root.accent : "transparent"
                                border.width: 1.5; border.color: parent.index <= root.step ? root.accent : pal.text3
                                Behavior on color { ColorAnimation { duration: 260 } }
                            }
                            Text {
                                text: parent.modelData
                                color: parent.index === root.step ? pal.text : pal.text2
                                font.family: Fonts.forWeight((parent.index === root.step ? Font.DemiBold : Font.Normal), root.fam); font.pixelSize: 13
                                font.weight: parent.index === root.step ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }

            Item {
                id: page
                x: side.width + 28; y: 24
                width: parent.width - side.width - 56; height: parent.height - 24 - 70
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }

                Text {
                    id: title
                    text: [I18n.tr("Welcome to the Lickintosh Installer"), I18n.tr("Components"), root.running ? I18n.tr("Installing…") : I18n.tr("Installation"), I18n.tr("The installation was successful.")][root.step]
                    color: pal.text; font.family: Fonts.forWeight(Font.DemiBold, root.fam); font.pixelSize: 18; font.weight: Font.DemiBold
                }

                Text {
                    visible: root.step === 0
                    y: 44; width: page.width; wrapMode: Text.WordWrap
                    lineHeight: 1.25
                    text: I18n.tr("This installs the programs Lickintosh needs: Quickshell, pictures and links, screenshots, and the system controls.") + "\n\n"
                        + I18n.tr("Nothing you already have is replaced: packages you already have stay as they are.") + "\n\n"
                        + I18n.tr("You may be asked for your password while installing.")
                    color: pal.text2; font.family: root.fam; font.pixelSize: 13
                }

                Rectangle {
                    visible: root.step === 1
                    y: 44; width: page.width; height: page.height - 44
                    radius: 10; color: pal.card
                    border.width: 1; border.color: pal.sep
                    clip: true
                    Text {
                        visible: root.planning || !root.plan
                        anchors.centerIn: parent
                        text: root.planning ? I18n.tr("Checking what is installed…") : I18n.tr("Couldn't read the dependency list.")
                        color: pal.text2; font.family: root.fam; font.pixelSize: 13
                    }
                    Flickable {
                        id: compFlick
                        visible: !root.planning && root.plan !== null
                        anchors.fill: parent; anchors.margins: 1
                        contentHeight: compCol.height + 12
                        clip: true
                        Column {
                            id: compCol
                            x: 14; y: 10; width: compFlick.width - 28
                            spacing: 12
                            Repeater {
                                model: root.groups
                                delegate: Column {
                                    required property var modelData
                                    width: compCol.width
                                    spacing: 4
                                    Text { text: I18n.tr(parent.modelData.name); color: pal.text; font.family: Fonts.forWeight(Font.DemiBold, root.fam); font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { width: parent.width; wrapMode: Text.WordWrap; text: parent.modelData.about; color: pal.text3; font.family: root.fam; font.pixelSize: 11 }
                                    Flow {
                                        width: parent.width
                                        spacing: 6
                                        Repeater {
                                            model: parent.parent.modelData.pkgs
                                            delegate: Rectangle {
                                                required property string modelData
                                                readonly property string st: root.stateOf(modelData)
                                                height: 22; width: pkgT.implicitWidth + 26; radius: 11
                                                color: st === "installed" ? Qt.rgba(0.19, 0.82, 0.35, 0.16)
                                                     : st === "install" ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                                                     : st === "skipped" ? Qt.rgba(1, 0.62, 0.04, 0.18) : pal.pill
                                                Text {
                                                    id: pkgT
                                                    anchors.centerIn: parent
                                                    text: (parent.st === "installed" ? "✓ " : parent.st === "install" ? "+ " : parent.st === "skipped" ? "– " : "") + parent.modelData
                                                    color: pal.text; font.family: root.fam; font.pixelSize: 11
                                                }
                                                ToolTipArea { tip: parent.st === "skipped" ? I18n.tr("Left alone: ") + root.reasonOf(parent.modelData) : "" }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    visible: root.step === 2
                    y: 44; width: page.width
                    spacing: 12
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap
                        text: !root.plan ? "" :
                              (!root.plan.supported ? I18n.tr("This distribution is not handled automatically: install the parts marked in Components with your package manager.")
                              : root.toInstall === 0 ? I18n.tr("Everything Lickintosh needs is already installed.")
                              : root.toInstall + (root.toInstall === 1 ? I18n.tr(" requirement will be installed: ") : I18n.tr(" requirements will be installed: ")) + root.plan.repo.join(", ") + ".")
                        color: pal.text2; font.family: root.fam; font.pixelSize: 13
                    }
                    Rectangle {
                        id: track
                        visible: root.running || root.log !== ""
                        width: parent.width; height: 6; radius: 3
                        color: pal.pill
                        clip: true
                        Rectangle {
                            height: parent.height; radius: 3
                            width: root.running ? track.width * 0.3 : track.width
                            color: root.result === "failed" ? "#FF453A" : root.accent
                            SequentialAnimation on x {
                                running: root.running; loops: Animation.Infinite
                                NumberAnimation { from: -track.width * 0.3; to: track.width; duration: 1300; easing.type: Easing.InOutQuad }
                            }
                            onWidthChanged: if (!root.running) x = 0
                        }
                    }
                    Rectangle {
                        visible: root.log !== ""
                        width: parent.width; height: page.height - 140
                        radius: 8; color: pal.card
                        border.width: 1; border.color: pal.sep
                        clip: true
                        Flickable {
                            id: logFlick
                            anchors.fill: parent; anchors.margins: 10
                            contentHeight: logT.height
                            clip: true
                            onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
                            Text { id: logT; width: logFlick.width; wrapMode: Text.WrapAnywhere; text: root.log; color: pal.text2; font.family: root.fam; font.pixelSize: 11 }
                        }
                    }
                    Text {
                        visible: root.result === "cancelled" || root.result === "failed"
                        text: root.result === "cancelled" ? I18n.tr("Cancelled: nothing was installed.") : I18n.tr("Something went wrong (see above). Nothing you had was removed.")
                        color: root.result === "failed" ? "#FF453A" : pal.text2; font.family: root.fam; font.pixelSize: 12
                    }
                }

                Column {
                    visible: root.step === 3
                    y: 44; width: page.width
                    spacing: 14
                    Rectangle {
                        width: 64; height: 64; radius: 32; color: Qt.rgba(0.19, 0.82, 0.35, 0.9)
                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.family: Fonts.forWeight(Font.Bold, root.fam); font.pixelSize: 34; font.weight: Font.Bold }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap
                        text: I18n.tr("Everything Lickintosh needs is installed.")
                        color: pal.text2; font.family: root.fam; font.pixelSize: 13
                    }
                }
            }

            Row {
                anchors.right: parent.right; anchors.rightMargin: 24
                anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                spacing: 10
                Btn { visible: root.step > 0 && root.step < 3; text: I18n.tr("Go Back"); enabled: !root.running; onClicked: root.step-- }
                Btn {
                    main: true
                    enabled: !root.running && (root.step !== 1 || root.plan !== null)
                    text: root.step === 0 || root.step === 1 ? I18n.tr("Continue")
                        : root.step === 3 ? I18n.tr("Close")
                        : root.running ? I18n.tr("Installing…")
                        : (root.toInstall > 0 ? I18n.tr("Install") : I18n.tr("Done"))
                    onClicked: {
                        if (root.step < 2) { root.step++; return; }
                        if (root.step === 3) { root.hideWin(win); return; }
                        if (root.toInstall > 0) root.install();
                        else root.step = 3;
                    }
                }
            }
        }
    }

    component Btn: Rectangle {
        id: b
        property string text: ""
        property bool main: false
        signal clicked()
        width: Math.max(96, bt.implicitWidth + 32); height: 30; radius: 8
        opacity: enabled ? 1 : 0.5
        color: main ? (bm.pressed ? Qt.darker(root.accent, 1.15) : root.accent) : (bm.pressed ? pal.lightOff : pal.pill)
        scale: bm.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
        Text { id: bt; anchors.centerIn: parent; text: b.text; color: b.main ? "white" : pal.text; font.family: Fonts.forWeight((b.main ? Font.DemiBold : Font.Normal), root.fam); font.pixelSize: 13; font.weight: b.main ? Font.DemiBold : Font.Normal }
        MouseArea { id: bm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }
    component ToolTipArea: MouseArea {
        id: tta
        property string tip: ""
        anchors.fill: parent
        hoverEnabled: tip !== ""
        Rectangle {
            visible: tta.containsMouse && tta.tip !== ""
            y: -height - 6; x: (tta.width - width) / 2; z: 10
            width: ttT.implicitWidth + 16; height: 22; radius: 6
            color: pal.dark ? "#3A3A3C" : "#1D1D1F"
            Text { id: ttT; anchors.centerIn: parent; text: tta.tip; color: "white"; font.family: root.fam; font.pixelSize: 11 }
        }
    }
}
