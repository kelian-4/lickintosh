import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocking()
    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: root.showFailure = false

    function tryUnlock() {
        if (root.currentText === "") return
        root.unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.currentText)
            }
        }

        onCompleted: (result) => {
            root.unlockInProgress = false
            if (result === PamResult.Success) {
                root.unlocking()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failed()
            }
        }

        onError: (error) => {
            root.unlockInProgress = false
            root.currentText = ""
            root.showFailure = true
            root.failed()
        }
    }
}
