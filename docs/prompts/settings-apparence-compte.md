# Mission : compléter la page « Apparence » (options de capture du verre) et construire la page « Compte » des Réglages de lickintosh

Tu travailles sur lickintosh, un shell Quickshell (QML) sous Hyprland/NixOS qui reproduit macOS. Dépôt : https://github.com/kelian-4/lickintosh (compte `kelian-4`). L'utilisateur lit le français, veut des réponses courtes et directes, et n'aime pas qu'on lui récite les règles. Ne dis jamais « vérifié » pour quelque chose que tu as seulement relu : distingue ce qui est exécuté, ce qui est relu, et ce qui est une hypothèse. Aucun check QML n'existe en CI : un QML invalide passe le CI.

## 0. Résumé

- Les Réglages sont une application Quickshell séparée (`settings.qml` à la racine, pages dans `ui/settings/pages/`). **Apparence** existe déjà (`ui/settings/pages/AppearancePage.qml`, branchée sur le singleton `services/Theme.qml`) : style verre / clair / sombre, teinte, accent, section « Liquid Glass par élément » (tous les réglages de rendu, par élément), thèmes de flou Hyprland, fenêtres et couches. Il lui manque l'interface des **options de capture des fenêtres** derrière le verre (section 3). **Compte** (icône `user.svg`) est encore marquée `implemented: false` : à construire (section 4).
- Les réglages sont persistés par `services/ShellConfig.qml` (un `FileView` + `JsonAdapter` sur `~/.config/lickintosh/shell-config.json`, relu à chaud). Écrire `ShellConfig.options.<section>.<propriété> = valeur` suffit : le fichier est réécrit et le shell principal se met à jour tout seul.
- Ne modifie pas le travail existant (animations, composants, autres pages, `Theme`) : tu ajoutes une section à Apparence, une page Compte et, au besoin, de petites propriétés. En cas de doute, demande.

## 1. Git, accès, règles strictes

- Token GitHub : `[À FOURNIR PAR L'UTILISATEUR]`. Ne l'écris jamais dans un fichier, un commit ou une URL de remote ; passe-le avec `git -c http.extraheader="Authorization: Basic $(printf 'x-access-token:%s' "$TOKEN" | base64 -w0)" ...`. S'il échoue de façon inattendue (401, 403, 404), ne cherche aucun contournement : signale et demande.
- Clone : `git clone -b dev https://github.com/kelian-4/lickintosh.git`, puis `git config user.email "kelian-4@users.noreply.github.com"` et `git config user.name "kelian-4"`. Aucun trailer `Co-authored-by`, aucune mention de Claude dans les commits.
- Travaille sur la branche **`dev`** uniquement. Ne touche ni à `main`, ni à `liquid_Glass_Reseacrh` (conservée, elle servira après la beta 1). Fais `git fetch` avant de commencer, pousse seulement en fast-forward, jamais de force-push. L'utilisateur gère lui-même les fusions entre branches.
- Pousse tôt et souvent (le bac à sable peut être réinitialisé sans prévenir). Messages de commit détaillés : le « pourquoi », ce qui est vérifié et ce qui ne l'est pas.
- CI au push : syntaxe Python (`tools/**/*.py`) et ShellCheck (`tools/**/*.sh`). Échec connu et ignoré : `tools/energy-usage/sample-processes copie.sh` (SC2034), n'y touche pas.
- Imports QML : uniquement `import qs.chemin.avec.points` (le dossier de `shell.qml` est le module `qs`) ; jamais de chemin relatif, jamais de `qmldir` dans le dépôt. Singletons : `pragma Singleton` + `Singleton {}` de Quickshell.
- Annonce (fichier, changement, raison) avant de modifier un fichier existant hors des pages que tu crées ; ne modifie `shell.qml` du shell principal que si c'est indispensable.

## 2. Comment fonctionnent les Réglages

Lis d'abord, dans cet ordre : `ui/settings/pages/AppearancePage.qml` et `services/Theme.qml` (à lire en entier : tu dois t'y intégrer sans rien casser), `settings.qml` (modèle de la barre latérale : `{ name, icon, component, implemented }` ; cherche comment le nom de `component` est converti en page affichée), `ui/settings/pages/GeneralPage.qml` et `LockScreenPage.qml` (modèles de pages), `ui/settings/widgets/` (`ContentPage`, `ContentSection`, `ConfigSwitch`, `ConfigSlider`, `PlaceholderPage`, `WallpaperThumb`), et `services/ShellConfig.qml`.

- Une page = un composant dans `ui/settings/pages/`, référencé par son nom dans `settings.qml` (`component: "MaPage"`, `implemented: true`).
- Mise en page : `ContentPage` contenant des `ContentSection`. Contrôles : `ConfigSwitch` (propriétés `text`, `description`, `checked` ; signal `toggled(bool value)`) et `ConfigSlider` (propriétés `text`, `value`, `from`, `to`, `decimals`, `valueSuffix` ; signal `moved(real value)`). Copie leur usage dans les pages existantes plutôt que d'inventer une API.
- Écriture, schéma des pages existantes : une propriété locale `cfg` pointe sur la section (`readonly property var cfg: ShellConfig.options.glass`), puis `checked: root.cfg.captureWindows` et `onToggled: function(v) { root.cfg.captureWindows = v }` ; pour un curseur, `value: root.cfg.windowOpacity` et `onMoved: function(v) { root.cfg.windowOpacity = v }`. Vérifie la forme exacte dans `LockScreenPage.qml` avant de l'imiter.
- Les Réglages tournent dans un autre processus que le shell : la synchronisation passe uniquement par le fichier JSON, relu à chaud des deux côtés.
- Chaîne de caractères de l'interface en français, ton sobre et proche de macOS. Les icônes sont dans `assets/icons/` (la barre latérale cite par exemple `settings/appearance.svg` et `user.svg`) ; réutilise-les.

## 3. Page « Apparence » : ajouter la section « Fenêtres derrière le verre »

`AppearancePage.qml` existe et gère déjà le style (`Theme.mode`), la teinte, l'accent, le verre par élément (`Theme.elementSpecs`, `ShellConfig.options.appearance.glassElements`) et le flou Hyprland : **ne la réécris pas**. Lis-la en entier, reprends ses composants (ses curseurs et interrupteurs locaux, `ContentSection`) et son ton, puis ajoute une section à la fin, avant ou après « Fenêtres et couches » selon ce qui lit le mieux.

### 3.1 Options à exposer : `ShellConfig.options.glass`

Elles sont déjà dans `ShellConfig` ; tu construis seulement l'interface. Le verre peut refléter les fenêtres derrière lui grâce à une capture d'écran de ces fenêtres ; c'est expérimental parce qu'un échec de capture peut faire planter la connexion Wayland de Quickshell (`wl_display error 0: invalid object`, défaut de Quickshell ou Hyprland, voir `docs/liquid-glass-research.md` section 22).

| Clé | Type | Défaut | Effet | Contrôle proposé |
|---|---|---|---|---|
| `captureWindows` | bool | `false` | Fait voir les fenêtres derrière le verre | interrupteur « expérimental » |
| `captureIntervalMs` | entier | `400` | Rafraîchissement des fenêtres capturées | curseur 200 à 2000, pas 100 (avancé) |
| `windowOpacity` | réel | `1.0` | Opacité des fenêtres capturées | curseur 0 à 1, pas 0,05 (avancé) |
| `windowOpacityByClass` | objet classe → opacité | `{ "kitty": 0.3 }` | Opacité par application ; 0 exclut l'application | éditeur de liste (avancé) |

Consignes :

- `captureWindows` : mets un avertissement visible. Libellé suggéré : « Expérimental : peut faire planter le shell sur certaines configurations. » Grise les trois autres réglages tant que l'interrupteur est éteint, et dans les modes où le verre n'est pas utilisé (vois `Theme.useGlass` et `Theme.mode`).
- `windowOpacityByClass` : éditeur de lignes (classe, opacité). Aide : les classes se lisent avec `hyprctl clients -j | jq -r '.[].class'`. C'est un objet JSON libre (`property var`) : écris un nouvel objet complet à chaque modification pour déclencher la sauvegarde, pas une mutation en place. À cause de la façon dont la capture perd la transparence des fenêtres, une valeur entre 0 et 1 restitue un fond translucide tout en gardant le texte opaque ; 0 exclut l'application.
- Ajoute un bouton « Rétablir les valeurs par défaut » pour cette section (relis les défauts dans `services/ShellConfig.qml` plutôt que de les dupliquer).
- Deux options d'apparence sont sans interface : `appearance.reduceMotion` (lue par l'écran de verrouillage, `ui/lockscreen/LockSurface.qml`) : propose un interrupteur « Réduire les animations » ; `appearance.panelOpacity` : déclarée mais lue nulle part (`grep` à refaire) : ne l'expose pas sans demander, soit on la branche, soit on la retire. Pose la question à l'utilisateur.
- Ne montre pas de valeurs qui ne sont pas des préférences (délais internes, paramètres de l'horloge de verrouillage, etc.).

## 4. Section « Compte »

Crée `ui/settings/pages/AccountPage.qml`. Rien n'existe encore pour cette page ; commence par lire ce qui existe déjà autour de l'identité de l'utilisateur :

- Avatar : `~/.face`, `~/.face.icon` et AccountsService, détectés par `ui/lockscreen/LockContext.qml` (`avatarUrl`, `avatarDetectionDone`) et par `ui/topbar/notch/dashboard/ProfilePhotoModule.qml` (même logique). Lis comment ces deux endroits détectent et rechargent l'avatar avant d'écrire quoi que ce soit.
- Informations système : `services/GeneralState.qml` (nom d'hôte, système, noyau...). Il n'y a pas encore de nom complet ni de nom d'utilisateur : ajoute-les proprement (par exemple un `Process` qui lit `id -un` et le champ GECOS de `getent passwd "$USER"`), dans un service ou dans `GeneralState`, sans casser l'existant.

Contenu suggéré (à valider avec l'utilisateur avant de coder ce qui est incertain) :

1. En-tête : avatar (rond), nom complet, nom d'utilisateur, nom d'hôte.
2. Changer la photo : choisir une image, la recadrer en carré, l'enregistrer dans `~/.face` (PNG), et prévoir « Supprimer la photo ». Après le changement, l'avatar de l'écran de verrouillage et du tableau de bord du notch doit se mettre à jour : vérifie comment forcer la relecture (cache d'image, URL avec paramètre de révision) et ajoute au besoin un compteur de révision partagé, sans modifier le comportement existant.
3. Écran de verrouillage : renvoie vers la page « Écran de verrouillage » existante plutôt que de dupliquer ses options.
4. Mot de passe : le shell s'authentifie par PAM (voir `ui/lockscreen/pam.d`). Ne tente pas de changer le mot de passe toi-même ; au mieux, propose un bouton qui ouvre un terminal sur `passwd`, et demande à l'utilisateur s'il le veut.

Questions à poser à l'utilisateur avant d'implémenter le point 3 et le point 4 : quelles options exactement doivent apparaître dans « Compte » ?

## 5. Vérification

- Lance `qmllint` (PySide6 : `pip download PySide6-Essentials` puis `PySide6/qmllint`) sur chaque fichier QML touché ; il détecte les erreurs de syntaxe mais pas les erreurs d'exécution. Les imports `qs.*` apparaissent comme introuvables : ignore ces messages.
- Si tu peux rendre une page sur un banc (PySide6 + Xvfb avec `LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl`), fournis des modules factices pour `Quickshell` et `qs.services` hors du dépôt, et envoie des captures. Sinon, dis clairement que le rendu n'a pas été vu.
- Teste l'écriture : change une valeur dans la page, relis `~/.config/lickintosh/shell-config.json`, et vérifie que la valeur y est. Dis si tu n'as pas pu le faire.
- Pour tout ce qui touche au verre : l'utilisateur teste sur sa machine réelle (NixOS, Hyprland, fish). Demande-lui un retour précis plutôt que de présumer.

## 6. Livrables

- `ui/settings/pages/AppearancePage.qml` et `AccountPage.qml` (et leurs petits composants si besoin), `settings.qml` mis à jour (`component` + `implemented: true`).
- Messages de commit clairs, poussés sur `dev`.
- Un court compte rendu en français : ce qui est fait, ce qui est vérifié (et comment), ce qui ne l'est pas, les questions restantes.
