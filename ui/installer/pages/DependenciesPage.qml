import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.ui.settings.widgets
import qs.ui.installer.widgets

ContentPage {
    id: root

    ContentSection {
        IRow {
            title: I18n.tr("État")
            subtitle: InstallerState.planBusy ? I18n.tr("Vérification de ce qui est installé…")
                : !InstallerState.plan ? I18n.tr("Impossible de lire la liste des dépendances") + (InstallerState.planError !== "" ? " : " + InstallerState.planError : "")
                : !InstallerState.plan.supported ? I18n.tr("Distribution non gérée : installe les paquets avec ton gestionnaire de paquets")
                : InstallerState.missing > 0 ? InstallerState.missing + " " + I18n.tr("paquet(s) manquant(s)")
                : I18n.tr("Tout ce dont Lickintosh a besoin est installé")
            IButton { text: I18n.tr("Revérifier"); enabled: !InstallerState.planBusy; onClicked: InstallerState.runPlan() }
        }
    }

    ContentSection {
        title: I18n.tr("Installation guidée")
        DepsStepper {}
    }

    Repeater {
        model: InstallerState.plan && InstallerState.plan.supported ? InstallerState.groups : []

        ContentSection {
            id: _sec
            required property var modelData
            title: I18n.tr(_sec.modelData.name)

            CFText {
                Layout.fillWidth: true
                text: I18n.tr(_sec.modelData.about)
                font.pixelSize: 12
                gray: true
                wrapMode: Text.WordWrap
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: _sec.modelData.pkgs
                    Chip {
                        required property string modelData
                        text: modelData
                        chipState: InstallerState.stateOf(modelData)
                    }
                }
            }
        }
    }

    ContentSection {
        title: I18n.tr("Autres")
        visible: InstallerState.otherPkgs.length > 0
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: InstallerState.otherPkgs
                Chip {
                    required property string modelData
                    text: modelData
                    chipState: InstallerState.stateOf(modelData)
                }
            }
        }
    }
}
