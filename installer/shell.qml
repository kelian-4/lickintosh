import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "I18n.js" as I18n
import "Fonts.js" as Fonts

Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string script: Quickshell.env("LICKINTOSH_SETUP") || (Quickshell.shellDir + "/../setup.fish")
    readonly property string repoDir: script.substring(0, script.lastIndexOf("/"))
    readonly property string shellInstallDir: home + "/.config/quickshell/lickintosh"
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")) + "/lickintosh"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/lickintosh"
    readonly property string projectUrl: "https://github.com/kelian-4/lickintosh"
    property string windowTitle: "Lickintosh Installer"

    property bool darkMode: true
    readonly property string build: "glass+fixed-12"
    property bool featherBlur: true       // scroll-under blur across the top of the page (testing)
    property bool glassOk: false          // turns on once the shader is ready; off again if it fails to load
    onGlassOkChanged: if (!glassOk && glassShaderUrl.toString() !== "") console.log("[lickintosh-installer] glass shader failed to load:", glassShaderUrl)
    property url glassShaderUrl: ""
    readonly property string glassSrc: decodeURIComponent(Qt.resolvedUrl("liquidglass.frag").toString().replace("file://", ""))
    Process {
        id: glassProc
        property string out: ""
        command: ["sh", "-c",
            "o=\"${XDG_CACHE_HOME:-$HOME/.cache}/lickintosh-installer/liquidglass.frag.qsb\"; mkdir -p \"$(dirname \"$o\")\"; "
            + "for q in qsb qsb6 qsb-qt6 /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb /usr/lib/qt/bin/qsb; do "
            + "  if command -v \"$q\" >/dev/null 2>&1; then \"$q\" --qt6 -o \"$o\" \"$1\" 2>&1 && { echo \"$o\"; exit 0; }; fi; "
            + "done; "
            + "if [ -f \"$1.qsb\" ]; then cp \"$1.qsb\" \"$o\" && echo \"$o\" && exit 0; fi; exit 1",
            "sh", root.glassSrc]
        stdout: SplitParser { onRead: d => { var l = d.trim(); if (l.indexOf("/") === 0) glassProc.out = l; } }
        onExited: (code, status) => {
            if (code === 0 && out !== "") { root.glassShaderUrl = "file://" + out; root.glassOk = true; console.log("[lickintosh-installer] glass shader:", out); }
            else console.log("[lickintosh-installer] glass shader could not be built: plain controls");
        }
    }
    readonly property real glassLiquid: 1.0
    readonly property real glassRim: 0.45
    readonly property real glassGrain: 0.03
    readonly property real glassOpacity: 0.42
    readonly property color glassBorder: "#8A9AB5"
    property color accent: "#0A84FF"
    property string fam: "SF Pro Text"
    QtObject {
        id: palObj
        readonly property bool dark: root.darkMode
        readonly property color accent: root.accent
        readonly property string fam: root.fam
        readonly property color contentSolid: dark ? "#1E1E1E" : "#F5F5F7"
        readonly property color sidebarGlass: dark ? Qt.rgba(0.17, 0.17, 0.18, 0.55) : Qt.rgba(0.94, 0.94, 0.96, 0.60)
        readonly property color sidebar: dark ? "#292929" : "#E9E9EC"
        readonly property color card: dark ? "#2B2B2D" : "#FFFFFF"
        readonly property color cardBorder: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.12)
        readonly property color edgeOuter: Qt.rgba(1, 1, 1, 0.50)
        readonly property color edgeInner: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.65)
        readonly property color sep: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.12)
        readonly property color text: dark ? "#F5F5F7" : "#1D1D1F"
        readonly property color text2: dark ? Qt.rgba(1, 1, 1, 0.56) : Qt.rgba(0, 0, 0, 0.52)
        readonly property color text3: dark ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(0, 0, 0, 0.30)
        readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.13)
        readonly property color switchOff: dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.14)
        readonly property color ctrl: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color ctrlSel: dark ? "#636366" : "#FFFFFF"
        readonly property color button: dark ? Qt.rgba(1, 1, 1, 0.13) : "#FFFFFF"
        readonly property color buttonPressed: dark ? Qt.rgba(1, 1, 1, 0.24) : "#E4E4E7"
        readonly property color buttonBorder: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.20)
        readonly property color field: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
        readonly property color selInactive: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
        readonly property color lightOff: dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.15)
        readonly property color logBg: dark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.04)
        readonly property color good: "#30D158"
        readonly property color warn: "#FF9F0A"
        readonly property color danger: "#FF453A"
        function lightBorder(active, c) { return active ? Qt.darker(c, dark ? 1.12 : 1.22) : "transparent"; }
    }
    readonly property var pal: palObj
    function fw(weight) { return Fonts.forWeight(weight, root.fam); }

    property bool busy: false
    property string runKind: ""
    property string raw: ""
    property string notice: ""                 // a short result line under the Install button
    property bool confirmUninstall: false

    property bool installed: false
    property var plan: null                    // install.sh --deps-plan
    property bool planBusy: false

    property bool optLaunch: true

    DepsSteps { id: depsSteps; host: root }

    ListModel { id: logModel }
    readonly property var logM: logModel

    readonly property var groups: [
        { name: "The shell", about: I18n.tr("Quickshell, the engine that runs the whole interface"),
          pkgs: ["quickshell"] },
        { name: "Pictures and links", about: I18n.tr("Wallpaper thumbnails, pictures, links and user folders"),
          pkgs: ["imagemagick", "curl", "jq", "xdg-utils", "xdg-user-dirs"] },
        { name: "Screenshots and colours", about: I18n.tr("Screenshots, the colour picker and the clipboard"),
          pkgs: ["grim", "slurp", "hyprpicker", "wl-clipboard"] },
        { name: "System controls", about: I18n.tr("Sound, brightness, media, Bluetooth, Wi-Fi, battery and power profiles"),
          pkgs: ["pipewire", "wireplumber", "brightnessctl", "playerctl", "networkmanager", "bluez", "upower", "power-profiles-daemon"] }
    ]
    function stateOf(p) {
        if (!plan) return "";
        if (!plan.supported) return "manual";
        if (plan.have && plan.have.indexOf(p) >= 0) return "installed";
        var sk = plan.skipped || [];
        for (var i = 0; i < sk.length; i++) if (String(sk[i]).split("|")[0] === p) return "skipped";
        if (plan.repo && plan.repo.indexOf(p) >= 0) return "install";
        return "installed";
    }
    function reasonOf(p) {
        var sk = plan ? (plan.skipped || []) : [];
        for (var i = 0; i < sk.length; i++) { var r = String(sk[i]).split("|"); if (r[0] === p) return r[1] || ""; }
        return "";
    }
    readonly property var otherPkgs: {
        if (!plan || !plan.supported) return [];
        var known = {}, out = [], g, i, j;
        for (g = 0; g < groups.length; g++) for (j = 0; j < groups[g].pkgs.length; j++) known[groups[g].pkgs[j]] = true;
        var lists = [plan.have || [], plan.repo || []];
        for (i = 0; i < lists.length; i++) for (j = 0; j < lists[i].length; j++) if (!known[lists[i][j]]) { known[lists[i][j]] = true; out.push(lists[i][j]); }
        return out;
    }
    readonly property int missing: plan && plan.supported && plan.repo ? plan.repo.length : 0
    readonly property string depsText: planBusy ? I18n.tr("Checking what is installed…")
        : !plan ? I18n.tr("Could not read the dependency list")
        : !plan.supported ? I18n.tr("Unsupported distribution: install the packages with your own package manager")
        : missing > 0 ? missing + (missing === 1 ? I18n.tr(" package is") : I18n.tr(" packages are")) + I18n.tr(" missing")
        : I18n.tr("Everything Lickintosh needs is installed")
    readonly property string installedText: installed ? "Installed" : I18n.tr("Not installed yet")

    function clean(s) { return String(s).replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").replace(/\r/g, ""); }
    function classify(l) {
        if (/^==>/.test(l)) return "step";
        if (/^\s*\[ok\]/.test(l) || /Aucun probleme detecte|Quickshell lance|Termine\./.test(l)) return "ok";
        if (/^\s*\[!!\]/.test(l) || /probleme\(s\) a regler|indisponible|manque :/.test(l)) return "warn";
        if (/^\s*\[\.\.\]/.test(l) || /^\s*-\s/.test(l)) return "dim";
        return "n";
    }
    function onLine(d) {
        var l = clean(d);
        if (l.trim() === "") return;
        raw += l + "\n";
        logModel.append({ t: l, k: classify(l) });
    }
    function clearLog() { logModel.clear(); raw = ""; }
    function sh(args) { return ["fish", script].concat(args); }
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }
    function runMain(kind, cmd) {
        if (busy) return;
        clearLog(); notice = "";
        runKind = kind; busy = true;
        runner.command = cmd;
        runner.running = true;
    }
    function installArgs() {
        var a = ["-y", "--skip-deps"];
        if (!optLaunch) a.push("--no-launch");
        return a;
    }
    function openPath(p) { Quickshell.execDetached(["xdg-open", p]); }
    function shellDetached(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function runPlan() {
        if (planBusy) return;
        planBusy = true; plan = null;
        planProc.buf = "";
        planProc.command = sh(["--deps-plan"]);
        planProc.running = true;
    }
    readonly property string startCmd: "setsid sh " + q(shellInstallDir + "/tools/lickintosh-start") + " >/dev/null 2>&1 &"
    function startShell() { shellDetached(startCmd); }
    function stopShell() { shellDetached("pkill -f lickintosh-start; qs -c lickintosh kill"); }
    function restartShell() { shellDetached("qs -c lickintosh kill >/dev/null 2>&1; sleep 1; " + startCmd); }

    Process {
        id: runner
        stdout: SplitParser { onRead: d => root.onLine(d) }
        stderr: SplitParser { onRead: d => root.onLine(d) }
        onExited: (code, status) => {
            root.busy = false;
            var k = root.runKind;
            if (k === "install" || k === "update" || k === "uninstall") {
                root.onLine(code === 0 ? "✓ Finished" : "! Finished with exit code " + code);
                root.notice = code === 0 ? (k === "uninstall" ? "Lickintosh was removed. Your settings were kept." : "Done.") : "Something went wrong: see the output above.";
                stateWatch.reload();
                if (k === "install" || k === "update") root.runPlan();
            }
        }
    }
    Process {
        id: planProc
        property string buf: ""
        stdout: SplitParser { onRead: d => planProc.buf += root.clean(d) + "\n" }
        stderr: SplitParser { onRead: d => planProc.buf += root.clean(d) + "\n" }
        onExited: (code, status) => {
            root.planBusy = false;
            var lines = buf.split("\n");
            for (var i = lines.length - 1; i >= 0; i--) {
                if (lines[i].charAt(0) === "{") {
                    try { root.plan = JSON.parse(lines[i]); } catch (e) { root.plan = null; }
                    break;
                }
            }
        }
    }
    FileView {
        id: stateWatch
        path: root.shellInstallDir + "/shell.qml"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.installed = true
        onLoadFailed: root.installed = false
    }
    Component.onCompleted: { console.log("[lickintosh-installer] build", build); glassProc.running = true; runPlan(); }

    component T: Text {
        property bool semi: false
        color: root.pal.text
        font.family: root.fw(semi ? Font.DemiBold : Font.Normal)
        font.pixelSize: 13
    }

    component SCard: Rectangle {
        id: card
        default property alias content: col.data
        width: parent ? parent.width : 0
        height: col.implicitHeight
        radius: 10
        color: root.pal.card
        border.width: 1
        border.color: root.pal.cardBorder
        Column { id: col; width: parent.width }
    }

    component SRow: Item {
        id: r
        property string title: ""
        property string subtitle: ""
        default property alias control: slot.data
        width: parent ? parent.width : 0
        height: Math.max(44, textCol.height + 22, slot.height + 20)
        Rectangle { visible: r.y > 0.5; x: 14; width: parent.width - 14; height: 1; color: root.pal.sep }
        Column {
            id: textCol
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, r.width - 14 - slot.width - 28)
            spacing: 2
            T { width: parent.width; text: r.title; elide: Text.ElideRight }
            T { visible: r.subtitle !== ""; width: parent.width; text: r.subtitle; wrapMode: Text.WordWrap; color: root.pal.text2; font.pixelSize: 12 }
        }
        Item {
            id: slot
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width; height: childrenRect.height
        }
    }

    component SLabel: Text {
        property bool header: false
        width: parent ? parent.width : 0
        leftPadding: 4
        topPadding: header ? 8 : 0
        wrapMode: Text.WordWrap
        color: root.pal.text2
        font.family: root.fw(header ? Font.DemiBold : Font.Normal)
        font.pixelSize: 12
        font.weight: header ? Font.DemiBold : Font.Normal
    }

    component SSwitch: GlassSwitch {
        accentColor: "#30D158"
        offColor: root.pal.switchOff
        knobColor: root.pal.dark ? "#DCDDDA" : "white"
        dark: root.pal.dark
        baseColor: root.pal.dark ? "#2B2B2D" : "#FFFFFF"
        glass: root.glassOk
        shaderUrl: root.glassShaderUrl
        glassLiquid: root.glassLiquid
        glassRim: root.glassRim
        glassGrain: root.glassGrain
        glassTint: root.glassOpacity
        borderTint: root.glassBorder
        onGlassFailed: root.glassOk = false
    }

    component SSegmented: GlassSegmented {
        segWidth: 88
        dark: root.pal.dark
        textColor: root.pal.text
        fontFamily: root.fam
        fontSize: 12
        trackColor: root.pal.ctrl
        pillColor: root.pal.ctrlSel
        baseColor: root.pal.dark ? "#2B2B2D" : "#FFFFFF"
        glass: root.glassOk
        shaderUrl: root.glassShaderUrl
        glassLiquid: root.glassLiquid
        glassRim: root.glassRim
        glassGrain: root.glassGrain
        glassTint: root.glassOpacity
        borderTint: root.glassBorder
        onGlassFailed: root.glassOk = false
    }

    component SButton: Rectangle {
        id: b
        property string text: ""
        property bool main: false
        property bool destructive: false
        signal clicked()
        width: lbl.implicitWidth + 26
        height: 24
        radius: 10
        opacity: enabled ? 1 : 0.45
        color: main ? (ma.pressed ? Qt.darker(root.accent, 1.18) : root.accent)
                    : (ma.pressed ? root.pal.buttonPressed : root.pal.button)
        border.width: main ? 0 : 1
        border.color: root.pal.buttonBorder
        Text {
            id: lbl
            anchors.centerIn: parent
            text: b.text
            color: b.main ? "white" : (b.destructive ? root.pal.danger : root.pal.text)
            font.family: root.fw(b.main ? Font.DemiBold : Font.Normal)
            font.pixelSize: 13
        }
        MouseArea { id: ma; anchors.fill: parent; enabled: b.enabled; onClicked: b.clicked() }
    }

    component STile: Rectangle {
        id: tl
        property string glyph: ""
        property color c1: "#3D9BFF"
        property color c2: "#0A6CFF"
        width: 24; height: 24; radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: tl.c1 }
            GradientStop { position: 1.0; color: tl.c2 }
        }
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.14)
        Text { anchors.centerIn: parent; text: tl.glyph; color: "white"; font.pixelSize: 14; font.bold: true }
    }

    component LogCard: Rectangle {
        id: lc
        property int viewHeight: 230
        width: parent ? parent.width : 0
        height: viewHeight
        radius: 10
        color: root.pal.logBg
        border.width: 1
        border.color: root.pal.cardBorder
        clip: true
        T { visible: root.logM.count === 0; anchors.centerIn: parent; text: I18n.tr("Output appears here"); color: root.pal.text3; font.pixelSize: 12 }
        ListView {
            id: lv
            anchors.fill: parent; anchors.margins: 10
            model: root.logM
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()
            delegate: Text {
                required property string t
                required property string k
                width: lv.width
                text: t
                wrapMode: Text.WrapAnywhere
                font.family: "monospace"
                font.pixelSize: 11
                font.weight: k === "step" ? Font.Bold : Font.Normal
                color: k === "ok" ? root.pal.good : k === "warn" ? root.pal.warn
                     : k === "step" ? root.pal.text : k === "dim" ? root.pal.text2 : root.pal.text2
            }
        }
    }

    component ProgressBar: Rectangle {
        id: track
        property bool running: false
        width: parent ? parent.width : 0; height: 6; radius: 3
        color: root.pal.ctrl
        clip: true
        visible: running
        Rectangle {
            height: parent.height; radius: 3
            width: track.width * 0.3
            color: root.accent
            SequentialAnimation on x {
                running: track.running; loops: Animation.Infinite
                NumberAnimation { from: -track.width * 0.3; to: track.width; duration: 1300; easing.type: Easing.InOutQuad }
            }
        }
    }

    Window {
        id: win
        title: root.windowTitle
        width: 820; height: 660
        minimumWidth: 820; maximumWidth: 820
        minimumHeight: 660; maximumHeight: 660
        visible: true
        color: "transparent"
        flags: Qt.Window | Qt.FramelessWindowHint
        onClosing: Qt.quit()

        readonly property var panes: [
            { id: "install",   sec: 1, name: "Install",      glyph: "↓", c1: "#3D9BFF", c2: "#0A6CFF", keys: "install shell options launch start" },
            { id: "deps",      sec: 1, name: "Dependencies", glyph: "≡", c1: "#FFB340", c2: "#FF9500", keys: "packages missing libraries tools quickshell terminal" },
            { id: "updates",   sec: 2, name: "Updates",      glyph: "↻", c1: "#8E8E93", c2: "#636366", keys: "update git pull latest backups" },
            { id: "doctor",    sec: 2, name: "Doctor",       glyph: "+", c1: "#4CD964", c2: "#28A745", keys: "diagnose problems fix check log environment services doctor" },
            { id: "tools",     sec: 3, name: "Tools",        glyph: "⚙", c1: "#8E8E93", c2: "#636366", keys: "start stop restart lock screen test config backups folder" },
            { id: "uninstall", sec: 4, name: "Uninstall",    glyph: "✕", c1: "#FF5E57", c2: "#E8342A", keys: "remove delete uninstall" },
            { id: "about",     sec: 4, name: "About",        glyph: "i", c1: "#A7A7AD", c2: "#7C7C82", keys: "version project website github" }
        ]
        property int cur: 0
        property var backStack: []
        property var fwdStack: []
        property string query: ""
        readonly property var filtered: {
            var qy = query.trim().toLowerCase(), out = [];
            for (var i = 0; i < panes.length; i++) {
                var hay = (panes[i].name + " " + panes[i].keys).toLowerCase();
                if (qy === "" || hay.indexOf(qy) >= 0) out.push(i);
            }
            return out;
        }
        function go(i) { if (i === cur) return; backStack = backStack.concat([cur]); fwdStack = []; cur = i; root.confirmUninstall = false; }
        function back() { if (backStack.length === 0) return; var b = backStack.slice(); var p = b.pop(); fwdStack = fwdStack.concat([cur]); backStack = b; cur = p; }
        function forward() { if (fwdStack.length === 0) return; var f = fwdStack.slice(); var p = f.pop(); backStack = backStack.concat([cur]); fwdStack = f; cur = p; }
        onCurChanged: flick.contentY = 0

        Shortcut { sequences: ["Escape", "Ctrl+W"]; onActivated: { if (root.confirmUninstall) root.confirmUninstall = false; else Qt.quit(); } }

        property int floatTries: 0
        onVisibleChanged: if (visible) { floatTries = 0; floatTimer.restart(); }
        Timer {
            id: floatTimer
            interval: 60
            repeat: true
            onTriggered: {
                var sel = 'window = "title:^(' + win.title + ')$"';
                Hyprland.dispatch('hl.dsp.window.float({ action = "enable", ' + sel + ' })');
                Hyprland.dispatch('hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", ' + sel + ' })');
                Hyprland.dispatch('hl.dsp.window.set_prop({ prop = "border_size", value = "0", ' + sel + ' })');
                Hyprland.dispatch('hl.dsp.window.set_prop({ prop = "rounding", value = "' + frame.radius + '", ' + sel + ' })');
                if (win.floatTries >= 2) {
                    Hyprland.dispatch('hl.dsp.window.resize({ x = ' + win.width + ', y = ' + win.height + ', "exact", ' + sel + ' })');
                    Hyprland.dispatch('hl.dsp.window.center({ ' + sel + ' })');
                }
                if (++win.floatTries >= 12) stop();
            }
        }

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.width: 1
            border.color: root.pal.edgeOuter

            Rectangle {
                anchors.fill: parent; anchors.margins: 1
                radius: frame.radius - 1
                color: "transparent"
                border.width: 1; border.color: root.pal.edgeInner
                z: 900
            }

            Item {
                id: pillBack
                z: -100
                readonly property real m: 64
                x: header.x + navPill.x - m; y: header.y + navPill.y - m
                width: navPill.width + 2 * m; height: navPill.height + 2 * m
                Rectangle { anchors.fill: parent; color: root.pal.contentSolid }
                Rectangle { x: 0; y: 0; width: Math.max(0, sidebar.x + sidebar.width - pillBack.x); height: parent.height; color: root.pal.sidebar }
                Rectangle { x: Math.max(0, sidebar.x + sidebar.width - pillBack.x); y: 0; width: 1; height: parent.height; color: root.pal.sep }
                ShaderEffectSource {
                    x: flick.x - pillBack.x; y: flick.y - pillBack.y
                    width: Math.max(1, parent.width - x); height: Math.max(1, parent.height - y)
                    sourceItem: flick
                    sourceRect: Qt.rect(0, 0, width, height)
                    live: true
                }
            }
            ShaderEffectSource { id: pillSes; sourceItem: pillBack; hideSource: true; live: true; mipmap: true; visible: false }

            Item {
                anchors.fill: parent
                z: 1000
                visible: root.confirmUninstall
                MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }
                Rectangle { anchors.fill: parent; radius: frame.radius; color: Qt.rgba(0, 0, 0, root.pal.dark ? 0.45 : 0.25) }
                Rectangle {
                    anchors.centerIn: parent
                    width: 320; height: 176
                    radius: 14
                    color: root.pal.contentSolid
                    border.width: 1; border.color: root.pal.buttonBorder
                    T { x: 0; y: 26; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: I18n.tr("Uninstall Lickintosh?"); semi: true; font.pixelSize: 17 }
                    T {
                        x: 22; y: 60; width: parent.width - 44
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                        text: I18n.tr("Lickintosh moves to the backups folder. Your settings are kept.")
                        color: root.pal.text2; font.pixelSize: 13
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                        spacing: 10
                        SButton { text: I18n.tr("Cancel"); onClicked: root.confirmUninstall = false }
                        SButton { text: I18n.tr("Uninstall"); destructive: true; onClicked: { root.confirmUninstall = false; root.runMain("uninstall", root.sh(["--uninstall", "-y"])); } }
                    }
                }
            }

            Rectangle {
                x: sidebar.x + sidebar.width; y: 1
                width: parent.width - x - 1; height: parent.height - 2
                radius: 11
                color: root.pal.contentSolid
                Rectangle { anchors.left: parent.left; width: 12; height: parent.height; color: parent.color }
            }

            Item {
                z: 3
                width: parent.width; height: 52
                DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
            }

            Rectangle {
                id: sidebar
                z: 4
                x: 1; y: 1
                width: 232
                height: parent.height - 2
                radius: 11
                color: "transparent"
                Item {
                    anchors.fill: parent
                    z: -1
                    layer.enabled: true
                    opacity: root.pal.sidebarGlass.a
                    Rectangle { anchors.fill: parent; radius: sidebar.radius; color: Qt.rgba(root.pal.sidebarGlass.r, root.pal.sidebarGlass.g, root.pal.sidebarGlass.b, 1) }
                    Rectangle { anchors.right: parent.right; width: 14; height: parent.height; color: Qt.rgba(root.pal.sidebarGlass.r, root.pal.sidebarGlass.g, root.pal.sidebarGlass.b, 1) }
                }
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.pal.sep }

                Item {
                    id: lights
                    x: 17; y: 14
                    width: 58; height: 14
                    Row {
                        scale: 0.93; transformOrigin: Item.TopLeft
                        spacing: 8
                        Repeater {
                            model: [{ c: "#FF5F57", g: "×", on: true }, { c: "#FEBC2E", g: "−", on: true }, { c: "#28C840", g: "↗", on: false }]
                            delegate: Rectangle {
                                required property var modelData
                                width: 14; height: 14; radius: 7
                                readonly property bool lit: modelData.on && (win.active || lightsMa.containsMouse)
                                color: lit ? modelData.c : root.pal.lightOff
                                Behavior on color { ColorAnimation { duration: 220 } }
                                border.width: 1
                                border.color: lit ? root.pal.lightBorder(true, modelData.c) : "transparent"
                                TLGlyph { anchors.fill: parent; kind: parent.modelData.g; opacity: (lightsMa.containsMouse && parent.modelData.on) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 140 } } }
                            }
                        }
                    }
                    MouseArea {
                        id: lightsMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: mouse => {
                            if (mouse.x < 22) Qt.quit();
                            else if (mouse.x < 44) root.shellDetached("hyprctl dispatch movetoworkspacesilent special:installer >/dev/null 2>&1");
                        }
                    }
                }

                Rectangle {
                    id: search
                    x: 12; y: 50
                    width: parent.width - 24; height: 28; radius: 7
                    color: root.pal.field
                    Rectangle {
                        anchors.fill: parent; anchors.margins: -2; radius: 9
                        color: "transparent"
                        border.width: 3
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
                        visible: searchInput.activeFocus
                    }
                    Item {
                        x: 9; anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14
                        Rectangle { width: 9; height: 9; radius: 4.5; color: "transparent"; border.width: 2; border.color: root.pal.text3 }
                        Rectangle { x: 8; y: 9; width: 5; height: 1.6; radius: 0.8; color: root.pal.text3; rotation: 45; transformOrigin: Item.Left }
                    }
                    TextInput {
                        id: searchInput
                        x: 30; width: parent.width - 54
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true; selectByMouse: true
                        color: root.pal.text; selectionColor: root.accent
                        font.family: root.fw(Font.Normal); font.pixelSize: 13
                        onTextChanged: win.query = text
                    }
                    T { x: 30; anchors.verticalCenter: parent.verticalCenter; visible: searchInput.text === ""; text: I18n.tr("Search"); color: root.pal.text3 }
                    Rectangle {
                        visible: searchInput.text !== ""
                        anchors.right: parent.right; anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: root.pal.text3
                        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -0.5; text: "×"; color: root.pal.sidebar; font.pixelSize: 12; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: searchInput.text = "" }
                    }
                }

                Rectangle {
                    id: acct
                    x: 10; y: 90; width: parent.width - 20; height: 52; radius: 10
                    visible: win.query === ""
                    readonly property bool sel: win.cur === 0
                    color: sel ? (win.active ? root.accent : root.pal.selInactive) : (acctMa.containsMouse ? root.pal.hover : "transparent")
                    Image {
                        x: 6; anchors.verticalCenter: parent.verticalCenter
                        width: 38; height: 38
                        source: Qt.resolvedUrl("../assets/icons/logo.svg")
                        sourceSize: Qt.size(96, 96)
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                    }
                    Column {
                        x: 52; anchors.verticalCenter: parent.verticalCenter
                        T { text: "Lickintosh"; semi: true; color: acct.sel && win.active ? "white" : root.pal.text }
                        T {
                            text: root.installedText
                            color: acct.sel && win.active ? Qt.rgba(1, 1, 1, 0.8) : root.pal.text2
                            font.pixelSize: 11
                        }
                    }
                    MouseArea { id: acctMa; anchors.fill: parent; hoverEnabled: true; onClicked: win.go(0) }
                }

                Flickable {
                    id: navFlick
                    x: 10; y: acct.visible ? 150 : 92
                    width: parent.width - 20
                    height: parent.height - y - 8
                    contentHeight: navCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: navCol
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: win.filtered
                            delegate: Item {
                                id: navItem
                                required property int modelData
                                required property int index
                                readonly property var p: win.panes[modelData]
                                readonly property bool gap: index > 0 && win.panes[win.filtered[index - 1]].sec !== win.panes[modelData].sec
                                readonly property bool sel: win.cur === modelData
                                width: parent.width
                                height: 34 + (gap ? 12 : 0)
                                Rectangle {
                                    y: navItem.gap ? 12 : 0
                                    width: parent.width; height: 34; radius: 8
                                    color: navItem.sel ? (win.active ? root.accent : root.pal.selInactive)
                                                       : (navMa.containsMouse ? root.pal.hover : "transparent")
                                    STile { x: 8; anchors.verticalCenter: parent.verticalCenter; glyph: navItem.p.glyph; c1: navItem.p.c1; c2: navItem.p.c2 }
                                    T {
                                        x: 42; anchors.verticalCenter: parent.verticalCenter
                                        text: I18n.tr(navItem.p.name)
                                        color: (navItem.sel && win.active) ? "white" : root.pal.text
                                        font.pixelSize: 14
                                    }
                                    Rectangle {
                                        readonly property string txt: navItem.p.id === "updates" && root.updateState === "available" ? "1"
                                                                    : navItem.p.id === "deps" && root.missing > 0 ? String(root.missing) : ""
                                        visible: txt !== ""
                                        anchors.right: parent.right; anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(18, bdg.implicitWidth + 10); height: 18; radius: 9
                                        color: "#FF3B30"
                                        Text { id: bdg; anchors.centerIn: parent; text: parent.txt; color: "white"; font.pixelSize: 11; font.bold: true }
                                    }
                                    MouseArea { id: navMa; anchors.fill: parent; hoverEnabled: true; onClicked: win.go(navItem.modelData) }
                                }
                            }
                        }
                        T { visible: win.filtered.length === 0; width: parent.width; topPadding: 14; horizontalAlignment: Text.AlignHCenter; text: I18n.tr("No Results"); color: root.pal.text2; font.pixelSize: 12 }
                    }
                }
            }

            Item {
                id: header
                z: 6
                x: sidebar.x + sidebar.width + 1
                width: parent.width - sidebar.x - sidebar.width - 2
                height: 52
                GlassSlab {          // Liquid Glass pill behind the back / forward buttons (same glass as Settings)
                    id: navPill
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 66; height: 36
                    cornerR: 18
                    glass: root.glassOk
                    shaderUrl: root.glassShaderUrl
                    dark: root.pal.dark
                    src: pillSes
                    srcSize: Qt.size(pillBack.width, pillBack.height)
                    origin: Qt.point(pillBack.m, pillBack.m)
                    baseColor: root.pal.dark ? "#3C3C40" : "#FBFBFD"
                    blurPx: 6
                    thickness: 14; strengthMul: 0.6
                    liquid: root.glassLiquid
                    rim: root.glassRim * 0.25
                    grain: root.glassGrain
                    tint: root.glassOpacity
                    shadowAmt: 0; flatInner: 1
                    onFailed: root.glassOk = false
                    CornerBorder {
                        z: 2; anchors.fill: parent
                        cornerR: 18; dark: root.pal.dark
                        tint: root.glassBorder
                        amount: 1; lineW: 0.8
                    }
                }
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: [{ g: "‹", dir: -1 }, { g: "›", dir: 1 }]
                        delegate: Item {
                            id: navBtn
                            required property var modelData
                            readonly property bool ok: modelData.dir < 0 ? win.backStack.length > 0 : win.fwdStack.length > 0
                            width: 26; height: 28
                            Text {
                                anchors.centerIn: parent; anchors.verticalCenterOffset: -2
                                text: navBtn.modelData.g
                                font.family: root.fw(Font.Normal); font.pixelSize: 28
                                color: navBtn.ok ? root.pal.text : root.pal.text3
                                opacity: navBtn.ok ? 1 : 0.5
                                scale: (navBtn.ok && nbMa.pressed) ? 0.86 : 1
                                Behavior on scale { NumberAnimation { duration: 230; easing.type: Easing.OutBack; easing.overshoot: 3.2 } }
                            }
                            MouseArea {
                                id: nbMa
                                anchors.fill: parent; hoverEnabled: true
                                enabled: navBtn.ok
                                onClicked: { if (navBtn.modelData.dir < 0) win.back(); else win.forward(); }
                            }
                        }
                    }
                }
                T { x: 90; anchors.verticalCenter: parent.verticalCenter; text: I18n.tr(win.panes[win.cur].name); semi: true; font.pixelSize: 15 }
            }

            Flickable {
                id: flick
                x: sidebar.x + sidebar.width + 1
                y: 1
                width: parent.width - sidebar.x - sidebar.width - 2
                height: parent.height - 2
                contentWidth: width
                contentHeight: paneLoader.height + 36 + 52
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                Loader {
                    id: paneLoader
                    x: 22; y: 58
                    width: flick.width - 44
                    sourceComponent: ({
                        install: paneInstall, deps: paneDeps, updates: paneUpdates, doctor: paneDoctor,
                        tools: paneTools, uninstall: paneUninstall, about: paneAbout
                    })[win.panes[win.cur].id]
                    onLoaded: fadeIn.restart()
                }
            }
            FeatherBlur {
                z: 1
                x: flick.x; y: flick.y; width: flick.width; height: flick.height
                target: root.featherBlur ? flick : null
                topHold: 36                  // height of the fully blurred band (was 52)
                topDepth: 22                 // short, soft fade-out (was 64)
                radiusScale: 1.4             // a bit more blur
                blurMax: 32
                topAmount: Math.max(0, Math.min(1, flick.contentY / 18))
            }
            NumberAnimation { id: fadeIn; target: paneLoader; property: "opacity"; from: 0; to: 1; duration: 160 }
            Rectangle {   // thin overlay scrollbar
                visible: flick.contentHeight > flick.height + 1
                x: frame.width - 8
                y: 52 + flick.visibleArea.yPosition * (flick.height - 52)
                width: 4
                height: Math.max(28, flick.visibleArea.heightRatio * (flick.height - 52))
                radius: 2
                color: root.pal.text3
                opacity: flick.moving ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }


        Component {
            id: paneInstall
            Column {
                spacing: 10
                SLabel { header: true; text: I18n.tr("Status") }
                SCard {
                    SRow {
                        title: I18n.tr("Dependencies")
                        subtitle: root.depsText
                        Row {
                            spacing: 8
                            SButton { visible: root.missing > 0; text: I18n.tr("Install…"); onClicked: depsSteps.open() }
                            SButton { text: I18n.tr("Re-check"); enabled: !root.planBusy; onClicked: root.runPlan() }
                        }
                    }
                    SRow {
                        title: "Lickintosh"
                        subtitle: root.installedText
                    }
                }

                SLabel { header: true; text: I18n.tr("Options") }
                SCard {
                    SRow {
                        title: I18n.tr("Start the shell when done")
                        subtitle: I18n.tr("Starts or restarts Quickshell after copying the files")
                        SSwitch { checked: root.optLaunch; onToggled: v => root.optLaunch = v }
                    }
                }
                SLabel { text: I18n.tr("Installing copies the shell, fonts, icons, cursor and Hyprland configuration. Existing files are backed up first and your settings are kept.") }

                Row {
                    spacing: 12
                    SButton {
                        main: true
                        text: root.busy && root.runKind === "install" ? I18n.tr("Installing…") : (root.installed ? I18n.tr("Reinstall Lickintosh") : I18n.tr("Install Lickintosh"))
                        enabled: !root.busy
                        onClicked: root.runMain("install", root.sh(root.installArgs()))
                    }
                    T { anchors.verticalCenter: parent.verticalCenter; text: root.notice; color: root.pal.text2; font.pixelSize: 12 }
                }
                ProgressBar { running: root.busy && root.runKind === "install" }
                LogCard { viewHeight: 220 }
            }
        }

        Component {
            id: paneDeps
            Column {
                spacing: 10
                SCard {
                    SRow {
                        title: I18n.tr("Status")
                        subtitle: root.depsText
                        Row {
                            spacing: 8
                            SButton { text: I18n.tr("Re-check"); enabled: !root.planBusy; onClicked: root.runPlan() }
                            SButton {
                                main: true
                                text: I18n.tr("Install…")
                                onClicked: depsSteps.open()
                            }
                        }
                    }
                }
                SLabel { text: I18n.tr("Nothing you already have is replaced. Installing opens a window with the steps; your system asks for your password.") }
                Repeater {
                    model: root.groups.concat(root.otherPkgs.length > 0 ? [{ name: "Other", about: I18n.tr("Other requirements in the plan"), pkgs: root.otherPkgs }] : [])
                    delegate: SCard {
                        id: gcard
                        required property var modelData
                        Item {
                            width: parent.width
                            height: gcol.implicitHeight + 24
                            Column {
                                id: gcol
                                x: 14; y: 12; width: parent.width - 28
                                spacing: 6
                                T { text: I18n.tr(gcard.modelData.name); semi: true }
                                T { width: parent.width; wrapMode: Text.WordWrap; text: gcard.modelData.about; color: root.pal.text3; font.pixelSize: 11 }
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    Repeater {
                                        model: gcard.modelData.pkgs
                                        delegate: Rectangle {
                                            required property string modelData
                                            readonly property string st: root.stateOf(modelData)
                                            height: 22; width: pkgT.implicitWidth + 26; radius: 11
                                            color: st === "installed" ? Qt.rgba(0.19, 0.82, 0.35, 0.16)
                                                 : st === "install" ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                                                 : (st === "skipped") ? Qt.rgba(1, 0.62, 0.04, 0.18) : root.pal.ctrl
                                            T {
                                                id: pkgT
                                                anchors.centerIn: parent
                                                font.pixelSize: 11
                                                text: (parent.st === "installed" ? "✓ " : parent.st === "install" ? "+ " : parent.st === "skipped" ? "– " : "") + parent.modelData
                                            }
                                            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true }
                                            Rectangle {
                                                readonly property string tip: parent.st === "skipped" ? "Left alone: " + root.reasonOf(parent.modelData) : ""
                                                visible: pma.containsMouse && tip !== ""
                                                y: -height - 6; x: (parent.width - width) / 2; z: 10
                                                width: ttT.implicitWidth + 16; height: 22; radius: 6
                                                color: root.pal.dark ? "#3A3A3C" : "#1D1D1F"
                                                Text { id: ttT; anchors.centerIn: parent; text: parent.tip; color: "white"; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: paneUpdates
            Column {
                spacing: 10
                SCard {
                    SRow { title: I18n.tr("Installed"); subtitle: root.installedText }
                    SRow {
                        title: I18n.tr("Update from Git")
                        subtitle: I18n.tr("Pulls the latest changes of this clone, then installs them. The old version is backed up first (the last 3 are kept).")
                        SButton {
                            main: true; text: I18n.tr("Update")
                            enabled: !root.busy
                            onClicked: root.runMain("update", ["sh", "-c", "git -C \"$1\" pull --ff-only && fish \"$1/setup.fish\" -y --skip-deps --no-launch", "sh", root.repoDir])
                        }
                    }
                    SRow {
                        title: I18n.tr("Backups")
                        subtitle: root.dataDir + "/backups"
                        SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.dataDir + "/backups") }
                    }
                }
                ProgressBar { running: root.busy && root.runKind === "update" }
                T { visible: root.notice !== "" && root.runKind === "update"; leftPadding: 4; text: root.notice; color: root.pal.text2; font.pixelSize: 12 }
                LogCard { viewHeight: 240 }
            }
        }

        Component {
            id: paneDoctor
            Column {
                spacing: 10
                SCard {
                    SRow {
                        title: I18n.tr("Check the setup")
                        subtitle: I18n.tr("Looks at the session, Hyprland, Quickshell, QML modules, tools, services, the installation and the last start log, and explains what is wrong.")
                        Row {
                            spacing: 8
                            SButton { text: I18n.tr("Open Start Log"); onClicked: root.openPath(root.stateDir + "/shell.log") }
                            SButton { main: true; text: root.busy && root.runKind === "doctor" ? I18n.tr("Checking…") : I18n.tr("Run Doctor"); enabled: !root.busy; onClicked: root.runMain("doctor", root.sh(["--doctor"])) }
                        }
                    }
                }
                ProgressBar { running: root.busy && root.runKind === "doctor" }
                LogCard { viewHeight: 380 }
            }
        }

        Component {
            id: paneTools
            Column {
                spacing: 10
                SLabel { header: true; text: "Lickintosh" }
                SCard {
                    SRow { title: I18n.tr("Start"); subtitle: I18n.tr("Runs the shell in your Hyprland session"); SButton { main: true; text: I18n.tr("Start"); onClicked: root.startShell() } }
                    SRow { title: I18n.tr("Restart"); subtitle: I18n.tr("Stops the shell and starts it again"); SButton { text: I18n.tr("Restart"); onClicked: root.restartShell() } }
                    SRow { title: I18n.tr("Stop"); subtitle: I18n.tr("Quits the running shell"); SButton { text: I18n.tr("Stop"); destructive: true; onClicked: root.stopShell() } }
                    SRow { title: I18n.tr("Lock Screen"); subtitle: I18n.tr("Try the lock screen"); SButton { text: I18n.tr("Lock Now"); onClicked: root.shellDetached("qs -c lickintosh ipc call lock lock") } }
                }
                SLabel { header: true; text: I18n.tr("Configuration") }
                SCard {
                    SRow { title: I18n.tr("Hyprland Config Folder"); SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.home + "/.config/hypr") } }
                    SRow { title: I18n.tr("Shell Folder"); subtitle: "~/.config/quickshell/lickintosh"; SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.shellInstallDir) } }
                    SRow { title: I18n.tr("Backups"); subtitle: I18n.tr("Where updates and uninstall keep older versions"); SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.dataDir + "/backups") } }
                }
            }
        }

        Component {
            id: paneUninstall
            Column {
                spacing: 10
                SCard {
                    SRow {
                        title: I18n.tr("Uninstall Lickintosh")
                        subtitle: I18n.tr("Moves the shell to the backups folder. Fonts, icons and the cursor are left in place.")
                        SButton { text: I18n.tr("Uninstall…"); destructive: true; enabled: !root.busy; onClicked: root.confirmUninstall = true }
                    }
                }
                SLabel { text: I18n.tr("Your settings are kept, so installing again brings everything back. The Hyprland configuration is not modified.") }
                ProgressBar { running: root.busy && root.runKind === "uninstall" }
                T { visible: root.notice !== "" && root.runKind === "uninstall"; leftPadding: 4; text: root.notice; color: root.pal.text2; font.pixelSize: 12 }
                LogCard { viewHeight: 240 }
            }
        }

        Component {
            id: paneAbout
            Column {
                spacing: 10
                SCard {
                    Item {
                        width: parent.width; height: 150
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 16; width: 84; height: 84
                            source: Qt.resolvedUrl("../assets/icons/logo.svg")
                            sourceSize: Qt.size(168, 168)
                            fillMode: Image.PreserveAspectFit
                            smooth: true; mipmap: true
                        }
                        T { y: 106; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Lickintosh Installer"; semi: true; font.pixelSize: 18 }
                        T { y: 130; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.installedText; color: root.pal.text2; font.pixelSize: 12 }
                    }
                }
                SCard {
                    SRow { title: I18n.tr("Build"); subtitle: root.build + " · Liquid Glass: " + (root.glassOk ? "on" : "failed, plain controls") + " · window " + win.width + "×" + win.height + " (fixed)" }
                    SRow { title: I18n.tr("Installer script"); subtitle: root.script }
                    SRow { title: I18n.tr("Project"); subtitle: root.projectUrl; SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.projectUrl) } }
                    SRow { title: I18n.tr("Backups"); subtitle: root.dataDir + "/backups"; SButton { text: I18n.tr("Open"); onClicked: root.openPath(root.dataDir + "/backups") } }
                }
                SLabel { text: I18n.tr("This window drives setup.fish: install, update, doctor and uninstall run the same code as the terminal.") }
            }
        }
    }
}
