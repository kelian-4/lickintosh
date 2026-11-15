# AGENTS.md

Consignes pour les agents de code (et utile à tout contributeur) travaillant sur lickintosh : un shell inspiré de macOS Tahoe pour Hyprland 0.57, écrit en QML avec Quickshell. Licence : GPL-3.0-or-later.

## Git
- Travaille sur la branche `dev`. Ne pousse jamais sur `main` : seul le mainteneur y fusionne `dev`.
- Avant de pousser : `git pull --rebase origin dev`.
- Les commits sont faits sous l'identité du mainteneur.
- `ci-status.md` est mis à jour par la CI (commits `[skip ci]`) : ne le modifie pas à la main.

## Structure
- `shell.qml`, `settings.qml`, `installer.qml` : points d'entrée.
- `ui/` : interface (barre, dock, bureau, verrouillage, réglages, widgets, installateur).
- `components/` : composants réutilisables, dont `components/glass/` (pipeline du verre).
- `services/` : singletons et états partagés (`ShellConfig`, `Theme`, `I18n`, `ShellMotion`, `WidgetState`…).
- `assets/` : icônes, polices, shaders, traductions (`assets/i18n/{fr,en,es}.json`), configuration Hyprland en Lua (`assets/config/hypr/hyprlua/`).
- `tools/` : scripts d'appoint, `tools/lickintosh-start` (lanceur), `tools/setup-i18n.txt` (traductions de `setup.fish`).

## Règles de code
- Les singletons QML qui utilisent `Timer` ont besoin de `import QtQuick`.
- Les animations utilisent `ShellMotion` (`spatial()`, `fade()`, `spatialCurve`, `effectsCurve`) : pas de durées ni de courbes en dur.
- Aucun chemin, nom d'utilisateur, thème de curseur ou d'icônes écrit en dur : passe par `ShellConfig` ou l'environnement.
- Ajoute les clés de traduction dans les trois fichiers `assets/i18n/*.json` ; les clés sont les textes français.
- Ne modifie pas les fichiers fournis par l'utilisateur (fonds d'écran, images) et ne place pas de ressources à sa place dans le dépôt.

## `setup.fish`
- Écrit pour fish : pas de syntaxe bash. Évite les globs sans correspondance (utilise `find`), utilise `string match -q -- (cmd)` plutôt que `test (cmd) = x`.
- Les réponses invalides de l'utilisateur ne doivent pas bloquer l'installeur : repasse à l'étape suivante.
- Tout nouveau message passe par le catalogue `tools/setup-i18n.txt` (fr/en/es, colonne de fin `||END`).
- L'installeur doit pouvoir tout désinstaller : ce qu'il crée, il sait le retirer ou le restaurer.
- Vérifie avec `fish -n setup.fish`.

## Verre (Liquid Glass)
- Chaîne : `LiquidGlassBackdrop` (fond d'écran, capture du bureau et des fenêtres) → flou → `TahoeGlass` / `SplitGlass`.
- Après toute modification d'un shader (`assets/shaders/**`), recompile avec `tools/liquid-glass/build-shaders.sh` (outil `qsb`) et commite les `.qsb`. Un nouvel uniform s'ajoute à la fin du bloc `std140`.
- Le code d'origine MacTahoe Liquid KDE (GPL-3.0) est repris dans `TahoeGlass` et `SplitLiquidGlass` : garde les mentions de `THIRD_PARTY_LICENSES/`.
- La capture ne doit jamais montrer le fond d'écran seul quand des fenêtres ou des widgets sont présents : conserve la dernière image capturée (voir `CaptureGate`).

## Vérification
Il n'y a pas de test automatisé du rendu : teste dans une session Hyprland, avec Quickshell relancé complètement, et dis clairement ce qui n'a pas pu être vérifié.
