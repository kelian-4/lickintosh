pragma Singleton
import QtQuick
import Quickshell

/*
    LockClockStyle — styles disponibles pour la grande horloge de l'écran
    de verrouillage (Réglages > Écran de verrouillage > Apparence de
    l'horloge). Partagé entre LockSurface (rendu réel) et LockScreenPage
    (aperçu + tuiles de choix), pour que les deux restent identiques.

    Les familles viennent des polices déjà livrées dans assets/fonts
    (SF Pro Display, SF Pro Rounded, SF Mono) ; "serif" est la famille
    générique résolue par fontconfig.

    L'index choisi et l'épaisseur (0..1) sont persistés dans
    ShellConfig.options.lockscreen.{clockStyle,clockWeight}. Le style 0 avec
    une épaisseur de 1.0 reproduit exactement l'ancienne horloge fixe
    (SF Pro Display, Font.Black) : aucun changement visuel par défaut.
*/
Singleton {
    id: root

    readonly property var styles: [
        { name: "SF Pro",           family: "SF Pro Display", italic: false, spacing: 0 },
        { name: "SF Pro Rounded",   family: "SF Pro Rounded", italic: false, spacing: 0 },
        { name: "SF Pro Italique",  family: "SF Pro Display", italic: true,  spacing: 0 },
        { name: "SF Mono",          family: "SF Mono",        italic: false, spacing: 0 },
        { name: "Serif",            family: "serif",          italic: false, spacing: 0 },
        { name: "Arrondi espacé",   family: "SF Pro Rounded", italic: false, spacing: 6 }
    ]

    function styleAt(i) {
        const n = root.styles.length
        return root.styles[Math.max(0, Math.min(n - 1, Math.round(i)))]
    }

    // 0..1 -> 100..900 par pas de 100 (Thin..Black). Les polices statiques
    // ne fournissent que quelques graisses : Qt prend la plus proche.
    function weightFor(v) {
        const c = Math.max(0, Math.min(1, v))
        return Math.round((100 + c * 800) / 100) * 100
    }
}
