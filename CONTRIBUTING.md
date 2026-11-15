# Contribuer à lickintosh / Contributing

🇫🇷 Français · 🇬🇧 [English below](#contributing-en)

## Contribuer (FR)

Merci de t'intéresser au projet. Les contributions (code, traductions, corrections, retours de test) sont les bienvenues.

### Signaler un bug
Ouvre une issue avec : ta distribution, la version de Hyprland et de Quickshell, la sortie de `./setup.fish --doctor` et les dernières lignes de `~/.local/state/lickintosh/shell.log`. Une capture d'écran aide beaucoup.

### Proposer une modification
1. Fais un fork, puis crée ta branche à partir de `dev` (jamais de `main`).
2. Garde chaque modification petite et ciblée, avec un message de commit clair.
3. Teste sur une vraie session Hyprland : relance complètement Quickshell après tes changements.
4. Ouvre ta pull request vers `dev`. `main` ne reçoit que des fusions de `dev` faites par le mainteneur.

### Conventions
- **QML** : un composant par fichier, les états partagés dans `services/` (singletons), les composants réutilisables dans `components/`. Les animations passent par `ShellMotion` (pas de durées ni de courbes écrites en dur).
- **Texte affiché** : écris-le en français, puis ajoute sa traduction dans `assets/i18n/en.json` et `assets/i18n/es.json` (les clés sont les textes français).
- **`setup.fish`** : fish uniquement. Ses messages sont traduits via `tools/setup-i18n.txt`. Vérifie la syntaxe avec `fish -n setup.fish`.
- **Shaders** : après avoir modifié un `.frag` ou `.vert`, recompile avec `tools/liquid-glass/build-shaders.sh` (nécessite `qsb`) et commite aussi les `.qsb`.
- **Valeurs en dur** : pas de chemin, de nom d'utilisateur ni de thème écrits en dur. Tout ce qui est réglable passe par `ShellConfig`.
- **Fichiers de tiers** : ajoute leur licence dans `THIRD_PARTY_LICENSES/` et cite-les dans le README.

### Licence
En contribuant, tu acceptes que ta contribution soit publiée sous [GPL-3.0-or-later](LICENSE), comme le reste du projet.

---

<a id="contributing-en"></a>
## Contributing (EN)

Thanks for your interest. Code, translations, fixes and test reports are all welcome.

### Reporting a bug
Open an issue with your distribution, your Hyprland and Quickshell versions, the output of `./setup.fish --doctor` and the last lines of `~/.local/state/lickintosh/shell.log`. A screenshot helps a lot.

### Proposing a change
1. Fork the repository and branch from `dev` (never from `main`).
2. Keep each change small and focused, with a clear commit message.
3. Test in a real Hyprland session: fully restart Quickshell after your changes.
4. Open your pull request against `dev`. `main` only receives merges from `dev`, done by the maintainer.

### Conventions
- **QML**: one component per file, shared state in `services/` (singletons), reusable components in `components/`. Animations go through `ShellMotion` (no hard-coded durations or curves).
- **User-facing text**: write it in French, then add its translation to `assets/i18n/en.json` and `assets/i18n/es.json` (keys are the French strings).
- **`setup.fish`**: fish only. Its messages are translated through `tools/setup-i18n.txt`. Check syntax with `fish -n setup.fish`.
- **Shaders**: after editing a `.frag` or `.vert`, rebuild with `tools/liquid-glass/build-shaders.sh` (needs `qsb`) and commit the `.qsb` files too.
- **Hard-coded values**: no hard-coded paths, user names or themes. Anything adjustable goes through `ShellConfig`.
- **Third-party files**: add their license to `THIRD_PARTY_LICENSES/` and credit them in the README.

### License
By contributing, you agree that your contribution is released under [GPL-3.0-or-later](LICENSE), like the rest of the project.
