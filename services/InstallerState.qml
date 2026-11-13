pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")) + "/lickintosh"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/lickintosh"
    readonly property string shellInstallDir: home + "/.config/quickshell/lickintosh"
    readonly property string repoFromFile: repoFile.loaded ? repoFile.text().trim() : ""
    readonly property string script: Quickshell.env("LICKINTOSH_SETUP") || ((repoFromFile !== "" ? repoFromFile : Quickshell.shellDir) + "/setup.fish")
    readonly property string repoDir: script.substring(0, script.lastIndexOf("/"))
    readonly property string projectUrl: "https://github.com/kelian-4/lickintosh"

    property bool installed: false
    property bool busy: false
    property string runKind: ""
    property string notice: ""
    property bool optLaunch: true
    signal pageRequested(string page)
    function requestPage(page) { pageRequested(page) }

    property var plan: null
    property bool planBusy: false
    property string planError: ""
    property bool depsRunning: false
    property string depsLog: ""
    property string depsResult: ""

    property bool logEmpty: true
    property var logLines: []
    signal logChanged()

    readonly property var groups: [
        { name: "Le shell", about: "Quickshell, le moteur qui fait tourner toute l'interface",
          pkgs: ["quickshell"] },
        { name: "Images et liens", about: "Miniatures de fonds d'écran, images, liens et dossiers utilisateur",
          pkgs: ["imagemagick", "curl", "jq", "xdg-utils", "xdg-user-dirs"] },
        { name: "Captures et couleurs", about: "Captures d'écran, pipette à couleurs et presse-papiers",
          pkgs: ["grim", "slurp", "hyprpicker", "wl-clipboard"] },
        { name: "Contrôles système", about: "Son, luminosité, médias, Bluetooth, Wi-Fi, batterie et profils d'énergie",
          pkgs: ["pipewire", "wireplumber", "brightnessctl", "playerctl", "networkmanager", "bluez", "upower", "power-profiles-daemon"] }
    ]

    function stateOf(p) {
        if (!plan) return ""
        if (!plan.supported) return "manual"
        if (plan.have && plan.have.indexOf(p) >= 0) return "installed"
        var sk = plan.skipped || []
        for (var i = 0; i < sk.length; i++) if (String(sk[i]).split("|")[0] === p) return "skipped"
        if (plan.repo && plan.repo.indexOf(p) >= 0) return "install"
        return "installed"
    }

    function reasonOf(p) {
        var sk = plan ? (plan.skipped || []) : []
        for (var i = 0; i < sk.length; i++) {
            var r = String(sk[i]).split("|")
            if (r[0] === p) return r[1] || ""
        }
        return ""
    }

    readonly property var otherPkgs: {
        if (!plan || !plan.supported) return []
        var known = {}, out = [], g, i, j
        for (g = 0; g < groups.length; g++) for (j = 0; j < groups[g].pkgs.length; j++) known[groups[g].pkgs[j]] = true
        var lists = [plan.have || [], plan.repo || []]
        for (i = 0; i < lists.length; i++) for (j = 0; j < lists[i].length; j++) {
            if (!known[lists[i][j]]) { known[lists[i][j]] = true; out.push(lists[i][j]) }
        }
        return out
    }

    readonly property int missing: plan && plan.supported && plan.repo ? plan.repo.length : 0

    function clean(s) { return String(s).replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").replace(/\r/g, "") }

    function classify(l) {
        if (/^==>/.test(l)) return "step"
        if (/^\s*\[ok\]/.test(l) || /Aucun probleme detecte|Quickshell lance|Termine\./.test(l)) return "ok"
        if (/^\s*\[!!\]/.test(l) || /probleme\(s\) a regler|problem\(s\) to fix|problema\(s\) por resolver|indisponible|unavailable|no disponible|manque :|missing:|falta:/.test(l)) return "warn"
        if (/^\s*\[\.\.\]/.test(l) || /^\s*-\s/.test(l)) return "dim"
        return "n"
    }

    function clearLog() { logLines = []; logEmpty = true; logChanged() }

    function onLine(d) {
        var t = clean(d)
        if (t.trim() === "") return
        var a = logLines.slice(-400)
        a.push({ text: t, kind: classify(t) })
        logLines = a
        logEmpty = false
        logChanged()
    }

    function sh(args) { return ["fish", script].concat(args) }
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function runMain(kind, cmd) {
        if (busy) return
        clearLog()
        notice = ""
        runKind = kind
        busy = true
        runner.command = cmd
        runner.running = true
    }

    function installArgs() {
        var a = ["--cli", "-y", "--skip-deps"]
        if (!optLaunch) a.push("--no-launch")
        return a
    }

    function install() { runMain("install", sh(installArgs())) }
    function update() {
        runMain("update", ["sh", "-c", "git -C \"$1\" pull --ff-only && fish \"$1/setup.fish\" --cli -y --skip-deps --no-launch", "sh", repoDir])
    }
    function doctor() { runMain("doctor", sh(["--doctor"])) }
    function uninstall() { runMain("uninstall", sh(["--uninstall", "-y"])) }

    function runPlan() {
        if (planBusy) return
        planBusy = true
        plan = null
        planProc.buf = ""
        planProc.command = sh(["--deps-plan"])
        planProc.running = true
    }

    readonly property string polkitPrelude:
        "agent() { pgrep -f '^(/[^ ]*/)?(hyprpolkitagent|polkit-gnome-authentication-agent-1|polkit-kde-authentication-agent-1|lxqt-policykit-agent|polkit-mate-authentication-agent-1|xfce-polkit|lxpolkit)' >/dev/null; }; " +
        "agent || { systemctl --user start hyprpolkitagent >/dev/null 2>&1; sleep 1; }; " +
        "agent || for b in /usr/lib/hyprpolkitagent/hyprpolkitagent /usr/libexec/hyprpolkitagent /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 /usr/libexec/polkit-gnome-authentication-agent-1 /usr/lib/polkit-kde-authentication-agent-1 /usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1; do " +
        "if [ -x \"$b\" ]; then setsid \"$b\" >/dev/null 2>&1 & sleep 2; break; fi; done; " +
        "agent || { echo \"Aucun agent polkit actif : installe hyprpolkitagent ou lance ./setup.fish dans un terminal\"; echo \"[exit 1]\"; exit 1; }; "

    function installDeps() {
        if (!plan || missing === 0 || depsRunning) return
        depsRunning = true
        depsResult = ""
        depsLog = ""
        depsProc.command = ["sh", "-c", root.polkitPrelude + "LICKINTOSH_ROOT_CMD=pkexec fish \"$1\" --cli -y --deps-only 2>&1; echo \"[exit $?]\"", "sh", script]
        depsProc.running = true
    }

    function detached(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    readonly property string startCmd: "setsid sh " + q(shellInstallDir + "/tools/lickintosh-start") + " >/dev/null 2>&1 &"
    function startShell() { detached(startCmd) }
    function stopShell() { detached("pkill -f lickintosh-start; qs -c lickintosh kill") }
    function restartShell() { detached("qs -c lickintosh kill >/dev/null 2>&1; sleep 1; " + startCmd) }
    function lockScreen() { detached("qs -c lickintosh ipc call lock lock") }
    function openPath(p) { Quickshell.execDetached(["xdg-open", p]) }

    Process {
        id: runner
        stdout: SplitParser { onRead: d => root.onLine(d) }
        stderr: SplitParser { onRead: d => root.onLine(d) }
        onExited: (code, status) => {
            root.busy = false
            var k = root.runKind
            if (k === "install" || k === "update" || k === "uninstall") {
                root.onLine(code === 0 ? "✓ Terminé" : "! Terminé avec le code " + code)
                root.notice = code === 0 ? (k === "uninstall" ? "Lickintosh a été retiré. Tes réglages sont conservés." : "Terminé.") : "Une erreur est survenue : voir la sortie ci-dessous."
                stateWatch.reload()
                if (k === "install" || k === "update") root.runPlan()
            }
        }
    }

    Process {
        id: planProc
        property string buf: ""
        stdout: SplitParser { onRead: d => planProc.buf += root.clean(d) + "\n" }
        stderr: SplitParser { onRead: d => planProc.buf += root.clean(d) + "\n" }
        onExited: (code, status) => {
            root.planBusy = false
            var lines = planProc.buf.split("\n")
            root.planError = ""
            for (var i = lines.length - 1; i >= 0; i--) {
                if (lines[i].charAt(0) === "{") {
                    try { root.plan = JSON.parse(lines[i]) } catch (e) { root.plan = null }
                    break
                }
            }
            if (!root.plan) {
                var tail = lines.filter(function(l) { return l.trim() !== "" })
                root.planError = tail.length > 0 ? tail[tail.length - 1] : "code " + code
            }
        }
    }

    Process {
        id: depsProc
        stdout: SplitParser {
            onRead: line => {
                var m = /^\[exit (\d+)\]$/.exec(line)
                if (m) {
                    root.depsRunning = false
                    root.depsResult = m[1] === "0" ? "ok" : (m[1] === "126" || m[1] === "127" ? "cancelled" : "failed")
                    root.runPlan()
                    return
                }
                root.depsLog += root.clean(line) + "\n"
                if (root.depsLog.length > 12000) root.depsLog = root.depsLog.slice(-12000)
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

    FileView {
        id: repoFile
        path: root.dataDir + "/repo"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    Component.onCompleted: runPlan()
}
