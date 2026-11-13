import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.glass
import qs.services

ColumnLayout {
    id: root

    property int step: 0
    readonly property var steps: [I18n.tr("Introduction"), I18n.tr("Composants"), I18n.tr("Installation"), I18n.tr("Résumé")]

    Layout.fillWidth: true
    spacing: 12

    Row {
        spacing: 8
        Repeater {
            model: root.steps
            Row {
                id: _s
                required property string modelData
                required property int index
                spacing: 6
                Rectangle {
                    width: 20; height: 20; radius: 10
                    color: _s.index <= root.step ? Theme.accent : Theme.controlTrack
                    CFText {
                        anchors.centerIn: parent
                        text: _s.index < root.step ? "✓" : String(_s.index + 1)
                        font.pixelSize: 11
                        color: _s.index <= root.step ? Theme.onAccent : Theme.textSecondary
                    }
                }
                CFText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: _s.modelData
                    font.pixelSize: 12
                    font.weight: _s.index === root.step ? Font.DemiBold : Font.Normal
                    gray: _s.index !== root.step
                }
                Rectangle {
                    visible: _s.index < root.steps.length - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 1
                    color: Theme.separator
                }
            }
        }
    }

    CFText {
        visible: root.step === 0
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.pixelSize: 13
        gray: true
        text: I18n.tr("Cela installe les programmes dont Lickintosh a besoin : Quickshell, images et liens, captures d'écran et contrôles système.") + "\n\n"
            + I18n.tr("Rien de ce que tu as déjà n'est remplacé : les paquets déjà présents restent tels quels.") + "\n\n"
            + I18n.tr("Ton mot de passe peut être demandé pendant l'installation.")
    }

    ColumnLayout {
        visible: root.step === 1
        Layout.fillWidth: true
        spacing: 6
        CFText {
            visible: InstallerState.planBusy || !InstallerState.plan
            text: InstallerState.planBusy ? I18n.tr("Vérification de ce qui est installé…") : I18n.tr("Impossible de lire la liste des dépendances")
            font.pixelSize: 13
            gray: true
        }
        Repeater {
            model: InstallerState.plan ? InstallerState.groups : []
            RowLayout {
                id: _g
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                CFText {
                    Layout.preferredWidth: 170
                    text: I18n.tr(_g.modelData.name)
                    font.pixelSize: 13
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }
                CFText {
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    gray: true
                    wrapMode: Text.WordWrap
                    text: {
                        var out = []
                        for (var i = 0; i < _g.modelData.pkgs.length; i++) {
                            var p = _g.modelData.pkgs[i]
                            var s = InstallerState.stateOf(p)
                            out.push((s === "installed" ? "✓ " : s === "skipped" ? "– " : "• ") + p)
                        }
                        return out.join("   ")
                    }
                }
            }
        }
    }

    ColumnLayout {
        visible: root.step === 2
        Layout.fillWidth: true
        spacing: 8
        CFText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            gray: true
            text: InstallerState.depsRunning ? I18n.tr("Installation…")
                : InstallerState.depsResult === "cancelled" ? I18n.tr("Annulé : rien n'a été installé.")
                : InstallerState.depsResult === "failed" ? I18n.tr("Une erreur est survenue (voir au-dessus). Rien de ce que tu avais n'a été supprimé.")
                : !InstallerState.plan ? ""
                : !InstallerState.plan.supported ? I18n.tr("Cette distribution n'est pas gérée automatiquement : installe les éléments indiqués avec ton gestionnaire de paquets.")
                : InstallerState.missing === 0 ? I18n.tr("Tout ce dont Lickintosh a besoin est déjà installé.")
                : InstallerState.missing + " " + I18n.tr("prérequis à installer") + " : " + InstallerState.plan.repo.join(", ") + "."
        }
        BarProgress { running: InstallerState.depsRunning }
        BoxGlass {
            visible: InstallerState.depsLog !== ""
            Layout.fillWidth: true
            implicitHeight: 140
            radius: 10
            color: Theme.fillSubtle
            clip: true
            Flickable {
                id: _fl
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: _t.implicitHeight
                clip: true
                onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
                Text {
                    id: _t
                    width: _fl.width
                    text: InstallerState.depsLog
                    wrapMode: Text.WrapAnywhere
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }
        }
    }

    CFText {
        visible: root.step === 3
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.pixelSize: 13
        gray: true
        text: InstallerState.missing === 0 ? I18n.tr("Tout ce dont Lickintosh a besoin est installé.") : InstallerState.missing + " " + I18n.tr("prérequis manquent encore") + " : " + (InstallerState.plan ? InstallerState.plan.repo.join(", ") : "") + "."
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Item { Layout.fillWidth: true }
        IButton {
            visible: root.step > 0 && root.step < 3
            enabled: !InstallerState.depsRunning
            text: I18n.tr("Retour")
            onClicked: root.step -= 1
        }
        IButton {
            main: true
            enabled: !InstallerState.depsRunning && !(root.step === 1 && !InstallerState.plan)
            text: root.step < 2 ? I18n.tr("Continuer")
                : root.step === 3 ? I18n.tr("Recommencer")
                : InstallerState.depsRunning ? I18n.tr("Installation…")
                : (InstallerState.missing > 0 && InstallerState.plan && InstallerState.plan.supported ? I18n.tr("Installer") : I18n.tr("Terminé"))
            onClicked: {
                if (root.step < 2) root.step += 1
                else if (root.step === 3) root.step = 0
                else if (InstallerState.missing > 0 && InstallerState.plan && InstallerState.plan.supported) { InstallerState.installDeps() }
                else root.step = 3
            }
        }
    }

    Connections {
        target: InstallerState
        function onDepsRunningChanged() {
            if (!InstallerState.depsRunning && InstallerState.depsResult === "ok") root.step = 3
        }
    }
}
