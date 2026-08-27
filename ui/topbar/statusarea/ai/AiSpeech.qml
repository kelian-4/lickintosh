import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var resultCallback: null
    property var errorCallback: null
    property bool recording: false
    property bool transcribing: false

    property string _tmpWav: "/tmp/qs-ai-stt-" + Date.now() + ".wav"
    property string _binCache: ""
    property string _modelPath: ""
    property string _pendingBin: ""

    function start() {
        if (root.recording || root.transcribing) return
        root._tmpWav = "/tmp/qs-ai-stt-" + Date.now() + ".wav"
        recProc.command = ["pw-record", "--rate", "16000", "--channels", "1", "--format", "s16", root._tmpWav]
        recProc._stderrText = ""
        recProc.running = true
        root.recording = true
    }

    function stop() {
        if (!root.recording) return
        recProc.running = false
        root.recording = false
    }

    function _fail(msg) {
        root.recording = false
        root.transcribing = false
        globalTimer.stop()
        recProc.running = false
        whisperProc.running = false
        if (root.errorCallback) root.errorCallback(msg)
    }

    Timer {
        id: globalTimer
        interval: 25000
        repeat: false
        onTriggered: {
            root._fail("Timeout : aucune étape n'a abouti en 25s (micro, whisper-cli, ou modèle). Vérifie manuellement en CLI : pw-record test.wav puis whisper-cli -m <modele> -f test.wav")
        }
    }

    Process {
        id: recProc
        property string _stderrText: ""
        command: []
        running: false
        stderr: StdioCollector {
            onStreamFinished: { recProc._stderrText = text }
        }
        onExited: function(exitCode) {
            if (root._tmpWav === "") return
            if (exitCode !== 0) {
                var detail = recProc._stderrText.trim()
                root._fail("pw-record a échoué (code " + exitCode + ")" + (detail !== "" ? " : " + detail.substring(0, 200) : " — vérifie que PipeWire tourne et que pw-record est installé") + ".")
                return
            }
            checkWavProc.command = ["sh", "-c", "test -s '" + root._tmpWav + "' && echo ok || echo empty"]
            checkWavProc.running = true
        }
    }

    Process {
        id: checkWavProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ok") {
                    root._fail("Aucun son enregistré (fichier vide). Vérifie que ton micro est bien détecté : pw-record --list-targets")
                    return
                }
                root._transcribe()
            }
        }
    }

    function _transcribe() {
        root.transcribing = true
        globalTimer.restart()
        if (root._binCache === "") {
            detectProc.running = true
        } else {
            _runWhisper(root._binCache)
        }
    }

    Process {
        id: detectProc
        command: ["sh", "-c", "command -v whisper-cli || command -v whisper-cpp || command -v main || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var bin = text.trim().split("\n")[0]
                if (bin === "") {
                    root._fail("whisper-cpp introuvable dans le PATH. Vérifie ton installation Nix (environment.systemPackages).")
                    return
                }
                root._binCache = bin
                root._runWhisper(bin)
            }
        }
    }

    function _findModel() {
        var name = AiConfig.whisperModel
        return "for p in " +
            "\"$HOME/.cache/whisper/ggml-" + name + ".bin\" " +
            "\"$HOME/.cache/whisper.cpp/ggml-" + name + ".bin\" " +
            "\"$XDG_DATA_HOME/whisper.cpp/ggml-" + name + ".bin\" " +
            "\"$HOME/.local/share/whisper.cpp/ggml-" + name + ".bin\" " +
            "\"$HOME/.local/share/whisper/ggml-" + name + ".bin\" " +
            "/run/current-system/sw/share/whisper.cpp/ggml-" + name + ".bin " +
            "/run/current-system/sw/share/whisper-cpp/ggml-" + name + ".bin " +
            "$(find /nix/store -maxdepth 2 -iname 'whisper*' -type d 2>/dev/null | head -5 | while read d; do find \"$d\" -iname 'ggml-" + name + "*.bin' 2>/dev/null; done) " +
            "$(find /nix/store -maxdepth 3 -iname 'ggml-" + name + "*.bin' 2>/dev/null | head -1) " +
            "; do [ -f \"$p\" ] && echo \"$p\" && exit 0; done; echo ''"
    }

    Process {
        id: findModelProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p === "") {
                    root._fail("Modèle whisper introuvable (nom attendu : ggml-" + AiConfig.whisperModel + ".bin). Télécharge-le avec : mkdir -p ~/.local/share/whisper.cpp && curl -L -o ~/.local/share/whisper.cpp/ggml-" + AiConfig.whisperModel + ".bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-" + AiConfig.whisperModel + ".bin")
                    return
                }
                root._modelPath = p
                root._runWhisperWithModel(root._pendingBin, p)
            }
        }
    }

    function _runWhisper(bin) {
        if (root._modelPath !== "") {
            _runWhisperWithModel(bin, root._modelPath)
            return
        }
        root._pendingBin = bin
        findModelProc.command = ["sh", "-c", _findModel()]
        findModelProc.running = true
    }

    function _runWhisperWithModel(bin, modelPath) {
        whisperProc.command = [
            bin,
            "-m", modelPath,
            "-f", root._tmpWav,
            "-l", AiConfig.whisperLang,
            "-nt",
            "-otxt",
            "-of", root._tmpWav.replace(".wav", "")
        ]
        whisperProc._stderrText = ""
        whisperProc.running = true
    }

    Process {
        id: whisperProc
        property string _stderrText: ""
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: { whisperProc._stderrText = text }
        }
        onExited: function(exitCode) {
            if (!root.transcribing) return
            if (exitCode !== 0) {
                var detail = whisperProc._stderrText.trim()
                root._fail("whisper-cli a échoué (code " + exitCode + ")" + (detail !== "" ? " : " + detail.substring(0, 200) : "") + ".")
                return
            }
            readTxtProc.command = ["sh", "-c", "cat '" + root._tmpWav.replace(".wav", "") + ".txt' 2>/dev/null"]
            readTxtProc.running = true
        }
    }

    Process {
        id: readTxtProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                globalTimer.stop()
                root.transcribing = false
                var txt = text.trim()
                cleanupProc.command = ["sh", "-c", "rm -f '" + root._tmpWav + "' '" + root._tmpWav.replace(".wav", ".txt") + "'"]
                cleanupProc.running = true
                var meaningful = txt.replace(/[.\u2026\s]/g, "")
                if (txt === "" || meaningful === "") {
                    if (root.errorCallback) root.errorCallback("Aucune parole claire détectée (parle plus fort/près du micro, ou le modèle '" + AiConfig.whisperModel + "' est peut-être trop léger pour ce cas).")
                } else {
                    if (root.resultCallback) root.resultCallback(txt)
                }
            }
        }
    }

    Process {
        id: cleanupProc
        command: []
        running: false
    }
}
