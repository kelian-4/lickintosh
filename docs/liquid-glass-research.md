# Liquid Glass dans lickintosh : rapport de recherche

Branche : `liquid_Glass_Reseacrh`. Source de l'effet : https://github.com/OverShifted/LiquidGlass (MIT, commit 3797fa5). Texte de licence et liste des adaptations : `THIRD_PARTY_LICENSES/LiquidGlass-MIT.txt`.

Les sections « Testé », « Non testé » et « Hypothèses » sont séparées volontairement. Une chose n'est dans « Testé » que si elle a été exécutée et regardée sur une capture.

## 1. Architecture retenue

```
Fenêtre layer-shell (une par panneau : dock, control center, ...)
 ├─ LiquidGlassBackdrop            un par fenêtre
 │    ├─ scène : Image du wallpaper + GlassWindows (optionnel)
 │    ├─ fb          ShaderEffectSource de la scène (pleine résolution)
 │    ├─ blur H      LiquidGlassBlur.frag, direction (1,0), sortie à blurDownscale
 │    ├─ blur V      LiquidGlassBlur.frag, direction (0,1)
 │    └─ blurFinal   texture floutée exposée en blurSource
 └─ LiquidGlass × N                un quad par élément de verre
      └─ ShaderEffect (LiquidGlass.frag) qui échantillonne blurSource
```

Pourquoi ce découpage : l'original (`LiquidGlass.cpp`) floute la scène une seule fois et tous les quads de verre échantillonnent la même texture. `BoxGlass` est utilisé dans 22 fichiers (hors `components/glass`), souvent sur de petits éléments (poignées de slider, interrupteurs). Un pipeline complet par instance serait inutilement lourd.

Pourquoi un backdrop par fenêtre : chaque `PanelWindow` a son propre scene graph Qt. Une `ShaderEffectSource` ne peut pas lire un item d'une autre fenêtre (non vérifié, voir « Hypothèses ») ; chaque fenêtre recharge donc le wallpaper depuis le cache d'images de Qt.

Sources de pixels à réfracter :

1. Wallpaper : l'`Image` est rechargée dans la scène de chaque backdrop, avec le même `PreserveAspectCrop` que la fenêtre Background.
2. Fenêtres d'applications : `GlassWindows.qml` empile une `ScreencopyView` live par toplevel Hyprland (`HyprlandToplevel.wayland` comme `captureSource`), placée avec `at`/`size` de `hyprctl clients`. Filtres : même moniteur, workspace actif, non cachée, intersecte `captureRegion`.
3. Capture de l'écran entier : écartée. Elle contiendrait le panneau lui-même (boucle de rétroaction).

Position écran d'un quad : `windowPosition` du backdrop (donnée par la fenêtre qui le porte) + `mapToItem(null, 0, 0)`, recalculée à chaque `afterAnimating`.

Fichiers : `components/glass/{LiquidGlassBackdrop,LiquidGlass,GlassWindows}.qml`, `assets/shaders/liquidglass/*`, `tools/liquid-glass/build-shaders.sh`, `tools/liquid-glass/test-shell/`, `tools/liquid-glass/research/`.

## 2. Fidélité du portage

Les formules (`sdSuperellipse`, `f`, `Glow`, `rand`, `LiquidGlass()`, `blur13`) sont reprises sans modification. Adaptations de syntaxe uniquement : `#version 440`, bloc `std140`, un seul sampler à la place de `sampler2D[32]` (seul l'indice 5 sert au verre), varyings `flat` devenus uniforms, inversion du Y (origine haut-gauche de Qt), `qt_Opacity`, suppression du code mort, commentaires retirés. Détail dans le fichier de licence.

Valeurs par défaut : celles envoyées au shader par `LiquidGlass.cpp`, pas celles écrites dans le GLSL (qui diffèrent). Résolution du flou : `u_resolution` vaut la taille du framebuffer d'entrée, comme dans `BlurPass::Run`, y compris pour la passe verticale.

Non porté : plusieurs itérations de flou (`blurIters > 1`, défaut d'origine : 1).

Défauts hérités de l'original : bord du verre sans anti-aliasing (`discard`), `smoothstep` avec `edge0 > edge1` (indéfini selon la spec GLSL, mais fonctionne dans mes rendus), forme normalisée par le quad (voir § 6).

## 3. Testé

Environnement : VM QEMU (TCG, 1 CPU) avec Hyprland headless et Quickshell précompilés de `kelian-4/dumb-code`, Qt 6.8.3 (Ubuntu 25.04), `QSG_RHI_BACKEND=opengl` sur llvmpipe, sans `QT_QUICK_BACKEND=software`. Versions exactes de Hyprland et de Quickshell non relevées.

- Les `ShaderEffect` s'exécutent dans cette VM (contrairement à l'hypothèse de départ).
- Les `.qsb` compilés avec `qsb` 6.11.2 (format v9) se chargent avec Qt 6.8.3. Le `qsb` 6.4.2 d'Ubuntu ne lit pas ce format.
- Rendu Xvfb + llvmpipe (Qt 6.11.2) avec la texture et les paramètres du screenshot de référence du projet d'origine : rendu visuellement très proche (réfraction, grain, bord clair en haut à gauche, sombre en bas à droite). Comparaison faite à l'œil, pas par mesure d'écart d'image.
- Verre dans une `PanelWindow` sur le wallpaper d'une autre `PanelWindow` : réfraction correcte.
- `ScreencopyView` live sur une toplevel : `hasContent true`, 1236×704 pour une fenêtre tilée. Géométrie `at`/`size` lue via `lastIpcObject`.
- Verre au-dessus d'une fenêtre flottante : tuiles floutées et déformées, alignées sur leur position réelle ; le wallpaper reste visible autour. Deux fenêtres tilées : le verre compose les deux et la bande de wallpaper entre elles.
- Déplacement d'une fenêtre (tilée → flottante, `[380,200]`) : le verre a suivi.
- Backdrop partagé : un grand verre, une petite pilule et une barre dans deux fenêtres (plein écran, et ancrée en bas) : alignement correct.
- Dock réel (`ui/dock/Dock.qml` modifié, `hoverToReveal` désactivé) avec une fenêtre flottante dessous : le fond du dock floute et réfracte la fenêtre, alignement correct.
- `hyprctl layers -j` donne la géométrie exacte d'un panneau ; pour un panneau centré sans ancre elle coïncide avec le calcul à partir des ancres.

## 4. Non testé

- GPU réel, dmabuf (dans la VM, Quickshell retombe sur SHM faute de nœud de rendu).
- Toute mesure de performance (la VM est en émulation logicielle ; ses temps ne disent rien).
- Révélation et masquage animés du dock, fenêtres animées par Hyprland (je ne sais pas si `at` donne la position cible ou animée).
- Fenêtres minimisées, plein écran, autre workspace, workspaces spéciaux.
- Multi-écrans, échelle d'écran différente de 1 (la taille de texture ignore `devicePixelRatio`).
- Control center, spotlight, notifications, OSD, lockscreen, settings, menus : aucun de ces fichiers n'est migré.
- Panneau avec marges ou zone exclusive d'autres surfaces : le calcul à partir des ancres n'a été comparé à `hyprctl layers` que pour un panneau centré.
- Plusieurs verres animés simultanément dans une même fenêtre.
- Exécution sur ta machine NixOS.

## 5. Hypothèses (non vérifiées)

- Une `ShaderEffectSource` ne peut pas lire un item d'une autre fenêtre : je ne l'ai pas testé, j'ai simplement évité le cas.
- Ordre d'empilement des fenêtres : floating au-dessus, puis `focusHistoryID`. Réaliste pour des cas simples, non validé en cas d'empilements complexes.
- Coût mémoire estimé par arithmétique, pas mesuré : par fenêtre, wallpaper décodé + `fb` en pleine résolution + deux buffers à demi-résolution, soit environ 20 Mo à 1920×1080.
- Coût GPU : sans fenêtre capturée, le flou ne devrait se recalculer que si le wallpaper change ; avec capture live, la scène et les deux passes de flou se rejouent à chaque nouvelle frame d'une fenêtre capturée. Le coût suit donc le taux de rafraîchissement des fenêtres sous le verre, multiplié par le nombre de fenêtres layer-shell qui capturent.
- La cause exacte du bug « capture invisible avec `scene.visible: false` » : les logs montrent `visible false` sur les `ScreencopyView` (parent invisible) et la capture n'apparaît pas ; `hideSource` règle le problème. Le mécanisme côté Quickshell n'est pas vérifié.

## 6. Limites

- Seules les toplevels sont capturées (exigence de la doc Quickshell : protocole `hyprland-toplevel-export-v1`). La barre, le dock et les autres panneaux ne sont pas dans ce que le verre réfracte.
- `lastIpcObject` n'est pas poussé par Hyprland (doc Quickshell) : `GlassWindows` appelle `refreshToplevels()` sur événement IPC et toutes les 500 ms. Une fenêtre déplacée à la souris peut être en retard.
- Le wallpaper du verre suit `ShellConfig.options.wallpaper.path`, pas l'aperçu temporaire de `SpotlightWindow`.
- Forme : le superellipse de l'original est normalisé par le quad, donc une barre large donne des extrémités en lentille. Sur demande du propriétaire, un chemin « rectangle arrondi à rayon constant » a été ajouté (`u_cornerRadius ≥ 0`, voir § 11). Le chemin d'origine reste disponible (`cornerRadius: -1`).
- Syntaxe `hyprctl dispatch` de ce Hyprland (config Lua) : `hl.dsp.window.*({ ..., window = "address:0x..." })`. Les anciens dispatchers `movewindowpixel` etc. échouent.

## 7. Compatibilité avec l'API de BoxGlass

`BoxGlass.qml` garde exactement son API publique. Le verre réfractant est ajouté sous le `GlassRim` existant, qui continue de dessiner la teinte (`color`) et la lueur de bord (`light`, `lightDir`, `rimSize`, `highlightEnabled`).

| BoxGlass | Comportement |
| --- | --- |
| `radius` | Rayon constant du verre, plafonné à la moitié du plus petit côté comme dans `GlassRim` (donc `999` donne une pilule). |
| `color`, `light`, `lightDir`, `rimSize`, `rimStrength`, `highlightEnabled`, `transparent` | Inchangés, toujours rendus par `GlassRim`. |
| `animationSpeed`, `animationSpeed2`, `negLight`, `highlight`, `shadowOpacity` | Conservés, sans effet nouveau. |

Le verre n'est affiché que si `GlassSettings.enabled`, `transparent` est faux, `GlassSettings.minAlpha < color.a < 0.99` (un fond opaque ou nul n'a rien à réfracter) et le plus petit côté vaut au moins `GlassSettings.minSize` (28 px). Ces seuils sont mes choix, à ajuster.

## 8. Prochaines étapes proposées

1. Relire visuellement chaque panneau sur ta machine et ajuster `GlassSettings`.
2. Traiter les fenêtres non layer-shell (voir § 11).
3. Mesurer sur un vrai GPU : mémoire par fenêtre, coût du flou avec et sans capture.
4. Ne capturer que quand un verre est visible (dock masqué, control center fermé).
5. Gérer `devicePixelRatio` et le multi-écrans.
6. Tester la révélation animée du dock et les fenêtres animées.

## 9. Rejouer les tests

Recompiler les shaders : `nix shell nixpkgs#qt6.qtshadertools -c ./tools/liquid-glass/build-shaders.sh` (non testé sur NixOS).

Shell de test : `env LG_TEST_BG=/chemin/image.jpg quickshell -p tools/liquid-glass/test-shell`. Il ouvre une fenêtre plein écran (grand verre et pilule) et une fenêtre ancrée en bas (barre), chacune avec son backdrop. Pour voir la réfraction d'une fenêtre, en ouvrir une dessous.

Sondes : `tools/liquid-glass/research/client` (fenêtre colorée) et `tools/liquid-glass/research/probe` (capture de toplevel et journal de la géométrie).

## 10. Sources

- Quickshell, `ScreencopyView` : https://quickshell.org/docs/types/Quickshell.Wayland/ScreencopyView
- Quickshell, `HyprlandToplevel` : https://quickshell.org/docs/v0.2.1/types/Quickshell.Hyprland/HyprlandToplevel
- Quickshell, `QsWindow` : https://quickshell.org/docs/types/Quickshell/QsWindow
- Hyprland, dispatchers (Lua) : https://wiki.hypr.land/0.56.0/Configuring/Basics/Dispatchers/
- Projet d'origine : https://github.com/OverShifted/LiquidGlass

## 11. Mise en œuvre à l'échelle du shell

Changements :

- `assets/shaders/liquidglass/LiquidGlass.frag` : chemin « rectangle arrondi à rayon constant » activé par `u_cornerRadius ≥ 0` (SDF classique d'Inigo Quilez). Seule la SDF de forme est remplacée ; refraction, flou, bruit, lueur sont inchangés. Modification non syntaxique, demandée explicitement ; elle est listée dans `THIRD_PARTY_LICENSES/LiquidGlass-MIT.txt`.
- `components/glass/BoxGlass.qml` : verre sous `GlassRim`, backdrop créé automatiquement au premier verre d'une fenêtre (retrouvé ensuite par `objectName`). Les ~22 fichiers qui l'utilisent ne sont pas modifiés.
- `components/glass/GlassLayers.qml` (singleton) : lit `hyprctl layers -j`, rafraîchi sur événement Hyprland (avec délai de 60 ms) et toutes les 3 s tant qu'un backdrop existe. Une fenêtre est retrouvée par moniteur et taille (±1 px). Un seul rafraîchissement des toplevels pour tout le shell, au lieu d'un par fenêtre.
- `components/glass/GlassSettings.qml` (singleton) : `enabled`, `captureWindows`, `blurRadius`, `noise`, `glowWeight`, `minAlpha`, `minSize`. Pour comparer vite, mettre `enabled: false` ou `captureWindows: false`.
- `ui/dock/Dock.qml` : verre à rayon constant (`dockRadius` plafonné à la moitié de la hauteur), avec le `Rectangle` d'origine (teinte `#22ffffff`, bordure, filet du haut) conservé par-dessus. Backdrop explicite avec position calculée à partir des ancres.

Testé (VM Hyprland + Quickshell, vrai `ControlCenter`, `SpotlightWindow` et `Dock`, fenêtre flottante dessous, `hyprctl` dans le `PATH`) :

- Les tuiles, sliders et boutons du control center réfractent la fenêtre et le fond, avec leurs formes d'origine (pilules, rectangles arrondis).
- La barre de spotlight garde sa forme de pilule et sa teinte, avec le contenu réfracté dessous.
- Le dock a un fond à rayon constant, avec sa teinte et sa bordure d'origine.
- Sans `hyprctl` dans le `PATH` (cas de la VM au premier essai), `GlassLayers` n'a pas de position : les panneaux gardent leur ancien rendu sans erreur.
- `hyprctl layers -j` : structure `{moniteur: {levels: {n: [{x, y, w, h, namespace, ...}]}}}` confirmée ; `quickshell:dock` à `y=634, h=166` (800 − 166), identique au calcul à partir des ancres.

Non testé : notifications (popups, pile, centre), OSD, écran de verrouillage, menus et sous-menus, fenêtres `AiWindow`, `AppleMenu`, `AboutWindow`, `settings.qml`, révélation animée du dock, multi-écrans (le décalage de moniteur appliqué aux coordonnées des layers suppose qu'elles sont globales), GPU réel, performances.

Limites propres à cette étape :

- Les `PopupWindow` (xdg_popup), les `FloatingWindow` et le verrouillage de session n'apparaissent pas dans `hyprctl layers` : leurs `BoxGlass` gardent l'ancien rendu.
- Pendant une animation d'échelle ou de zoom d'un parent, la taille du verre dans le shader n'applique pas la transformation (position oui, taille non) : léger décalage possible.
- Les refractions de petits éléments sous `minSize` sont désactivées (choix de design de ma part).
- Chaque fenêtre qui contient un verre a son backdrop (wallpaper, flou, et capture de fenêtres si `captureWindows`). Sur le control center et spotlight (plein écran) la capture est donc plein écran ; aucune mesure de coût.

## 12. Retour de test : clarté du verre, rim, flash

Retours du propriétaire après un premier test sur sa machine : rim du dock mal fait, control center à rapprocher d'une référence macOS (verre clair, couleurs vives), et fond d'écran visible une fraction de seconde à l'ouverture des éléments.

Causes identifiées sur capture :

- Rim du dock : l'ancien `Rectangle` (bordure, filet du haut) gardé par-dessus un verre dont le rayon était calculé à part. Les deux formes ne coïncidaient pas. Le dock utilise maintenant `GlassRim`, comme `BoxGlass`, avec le même plafonnement du rayon.
- Aspect gris et granuleux : flou 2,0, teinte noire de 12 % (`glassColor` du control center), grain 0,03. Mesuré sur un banc de test : le verre était plus sombre que le fond (102 contre 116) et deux fois plus granuleux (gradient local 2,37 contre 1,22).
- Contenu étiré aux extrémités des formes allongées : la réfraction d'origine est un zoom radial autour du centre. Voir `THIRD_PARTY_LICENSES` : le chemin « rayon constant » déplace maintenant l'échantillon le long de la normale du bord.

Changements : `GlassSettings` (flou 0,8, grain 0, lueur 0, `tintScale` 0,25, `veil` 0,06, `fadeDuration` 160 ms), voile blanc et teinte atténuée dans `BoxGlass`, anti-aliasing du bord.

Flash : le verre apparaît en fondu seulement quand les fenêtres capturées sous lui sont prêtes (`latched` dans `GlassWindows`, délai de grâce 150 ms, plafond 800 ms). Correctif écrit, **non vérifié** : l'hypothèse sur la cause (les fenêtres ne sont pas encore capturées à l'ouverture, donc seul le fond d'écran est réfracté) n'est pas confirmée par des logs.

Problème observé dans la VM : quand une fenêtre est déplacée puis redimensionnée sous plusieurs verres, le verre d'un des panneaux (le dock une fois, le control center une autre) cessait de la réfracter et montrait le fond d'écran. Les logs montrent `hasContent` repassant à `false` pour un flux de capture qui ne revient pas seul.

Diagnostic (sondes dans `tools/liquid-glass/research/reattach`) :

- Détacher puis rattacher `captureSource` fonctionne : le flux revient en 3 à 6 s dans la VM (très lente), y compris en basculant aussi `visible`. L'hypothèse « le rattachement bloque » est donc réfutée.
- Un flux maintenu en permanence (opacité 0, source constante) garde `hasContent` à `true`.
- La victime change d'un essai à l'autre : la perte vient du redimensionnement de la fenêtre pendant plusieurs captures simultanées. La cause exacte (Quickshell ou Hyprland) n'est pas établie.

Correctifs dans `GlassWindows.qml` :

- Les flux de toutes les fenêtres du workspace actif restent attachés ; la région de verre ne sert qu'à décider quoi attendre avant d'afficher le verre. Cela évite les redémarrages à chaque entrée dans une région.
- Chien de garde : un flux visible resté sans contenu pendant 10 s est redémarré (`captureSource` mis à `null` puis rétabli).

Vérifié dans la VM sur le scénario qui échouait (control center, spotlight et dock ouverts, fenêtre déplacée et redimensionnée sous eux) : les trois verres réfractent la fenêtre ; les logs montrent une perte de contenu suivie d'un redémarrage par le chien de garde puis du retour de `hasContent`. Un seul essai concluant, dans une VM lente.

Coûts et limites de ce choix, non mesurés : chaque fenêtre qui contient du verre capture en continu toutes les fenêtres visibles du moniteur (une vidéo lue quelque part fait recalculer tous les backdrops) ; le chien de garde peut laisser un verre sans la fenêtre pendant jusqu'à 10 s après une perte. `GlassSettings.captureWindows: false` désactive la capture.

## 13. Retour de test : épaisseur du verre

Précision du propriétaire : « garder la forme de base » signifie garder les formes des composants (rond, carré, rectangle arrondi), pas rendre le verre discret. Le réglage précédent (réfraction d'origine, flou léger, teinte faible) donnait des composants plats.

Cause : avec les paramètres d'origine (`a 0.7`, `b 2.3`, `c 5.2`, `d 6.9`, `fPower 1.0`), la bande de déformation `f(x) = 1 - b (c e)^(-d x - a)` ne couvre qu'environ 15 % du demi-côté, soit quelques pixels : on ne voit presque que le contour.

Changement : profil de réfraction plus épais et lueur de bord étroite, réglables dans `GlassSettings` : `refractionB 3.2`, `refractionD 2.5`, `refractionPower 1.1`, `glowWeight 0.4`, `glowEdge0 0.15`, `glowEdge1 0.0`. Valeurs choisies à l'œil sur un banc de test comparant quatre profils sur quatre formes (rond, carré arrondi, pilule, tuile) : un profil plus fort (`b 3.5`, `d 2.2`) devient une loupe trop marquée, une lueur de bande large (`0.35`) rend le verre laiteux, une lueur à `0.7` brûle sur fond clair. `GlassRim` (rim, teinte) est inchangé. Les formes restent celles de chaque composant (rayon plafonné à la moitié du côté court).

Vérifié dans la VM (vrai control center, spotlight, dock) : les ronds, pilules et tuiles courbent le fond en bordure avec un reflet clair en haut à gauche et un bord plus sombre en bas à droite. Non vérifié sur ta machine ni avec ton fond d'écran : les valeurs sont un point de départ.

## 14. Retour de test : bords perlés et bande sombre

Note : le rim et le dégradé intérieur décrits ici ont été retirés (voir § 16). Les causes identifiées restent valables.

Constat du propriétaire (recadrages de son écran) : les bords du verre montrent des « limites » ; la référence attendue est un bord lisse, net et volumineux.

Causes identifiées (sur recadrages agrandis et sur le GLSL extrait du `.qsb` de `GlassRim`) :

- Rim perlé : le profil de `GlassRim` est `1 - cos(edge * pi / 2)` avec `edge = smoothstep(rimSize * 100, 0, |dist|)`. Pour `rimSize = 0.01` la bande vaut 1 px et la courbe la rétrécit encore : le filet effectif est plus étroit qu'un pixel et scintille en escalier sur les courbes. Son intensité `|n . lightDir|` tombe à zéro sur certaines orientations, et sa forme est calculée sur `taille + 2` pixels.
- Bande sombre : la lueur d'origine `Glow()` multiplie la couleur par `1 + glow`, partie négative incluse, donc assombrit le bord bas-droite (réglée à 0,4 à l'étape précédente).

Changement : le rim est maintenant dessiné dans le shader du verre (chemin « rayon constant ») avec le même SDF en pixels et le même anti-aliasing que le bord du verre. Filet de 1,6 px au profil lisse, intensité jamais nulle (`0.45 + 0.55 |n . L|`, reflets en haut à gauche et en bas à droite), plus un dégradé clair additif de 10 px à l'intérieur pour le volume. Aucune partie sombre. `glowWeight` revient à 0. L'ancien `GlassRim` fond quand le nouveau apparaît (il reste le rim de repli quand le verre est inactif). `highlightEnabled: false` coupe le nouveau rim, `light` (alpha) et `rimStrength` de `BoxGlass` en modulent l'intensité, `lightDir` donne l'axe (Y retourné entre écran et shader). Réfraction ramenée à `refractionB 2.8` pour atténuer la discontinuité du bord. Réglages dans `GlassSettings` : `rimStrength`, `rimWidth`, `sheenStrength`, `sheenWidth`. Premier réglage (0,6 / 1,6 px / 0,2 / 10 px) jugé un peu trop fort par le propriétaire ; réglage actuel : `rimStrength 0.35`, `rimWidth 1.4`, `sheenStrength 0.16`, `sheenWidth 10`, choisi sur le banc (non revérifié en VM, seuls des nombres ont changé).

Vérifié : banc Xvfb (comparaison avec l'état précédent et avec des variantes), VM (vrai control center, spotlight, dock) : rim continu, dégradé intérieur doux, plus de croissant sombre. Valeurs choisies à l'œil, à ajuster.

Observation de VM, sans rapport avec le rendu : juste après le déplacement d'une fenêtre, une capture montrait des backdrops encore sur l'ancienne image (spotlight affichant les tuiles de la fenêtre à son ancienne position). Une capture prise ensuite dans la même session était correcte. Cause retenue : retard de rendu logiciel (un CPU émulé, plusieurs backdrops plein écran qui rejouent scène et deux passes de flou). Non mesuré, hypothèse vérifiée seulement par ce second instantané.

## 15. Retour de test : réactivité de la capture

Constat du propriétaire : le rim convient, mais ce qui se trouve derrière le verre se met à jour trop lentement.

Sources de retard identifiées dans le code :

- La géométrie des fenêtres était lue toutes les 500 ms. Hyprland n'émet aucun événement pendant un déplacement ou un redimensionnement : seul un sondage de son IPC permet de suivre une fenêtre. Le verre pouvait donc être en retard de jusqu'à une demi-seconde.
- Le démarrage d'un panneau enchaînait un délai de 60 ms, le lancement de `hyprctl layers`, le démarrage des flux, 150 ms de grâce et 160 ms de fondu.
- Chaque événement Hyprland, y compris un changement de titre, relançait un processus `hyprctl layers`.

Changements (`GlassLayers`, `GlassWindows`, `BoxGlass`, `GlassSettings`) :

- Sondage adaptatif des toplevels : `captureFastInterval` (40 ms) tant que la signature des fenêtres change ou après un événement de géométrie, `captureIdleInterval` (200 ms) au repos.
- Événements déclencheurs restreints : `openwindow`, `closewindow`, `movewindow(v2)`, `fullscreen`, `changefloatingmode`, `workspace(v2)`, `pin`, `minimized`. `hyprctl layers` n'est relancé que sur `openlayer`/`closelayer`, immédiatement quand un backdrop apparaît, et toutes les 3 s.
- Une fenêtre plein écran est placée en `(0,0)` sans attendre `hyprctl layers`.
- Délai de grâce 60 ms, plafond 500 ms, fondu 120 ms (`fadeDuration`).
- Chien de garde de redémarrage d'un flux sans contenu : 8 s.

Vérifié dans la VM : les trois panneaux (control center, spotlight, dock) réfractent bien la fenêtre déplacée dessous, sur deux captures prises à plusieurs minutes d'écart.

Non vérifié :

- Aucun gain de latence n'est mesuré. Une mesure en VM (dock seul, ancien contre nouveau sondage, six déplacements chronométrés chacun) donne 7 à 34 s dans les deux cas et plusieurs mises à jour absentes dans l'ancienne version : la VM (un CPU émulé, rendu logiciel) bloque le fil principal de Quickshell et ses chiffres ne disent rien des intervalles de sondage.
- Le coût du sondage à 40 ms (requête IPC, analyse JSON, réévaluation des liaisons) n'est pas mesuré, ni sur de nombreuses fenêtres, ni sur un vrai GPU.
- Une tentative avec un chien de garde à 3 s a montré, sur une capture, deux tuiles du control center réfractant le fond d'écran au lieu de la fenêtre ; avec 8 s la même scène est correcte. Hypothèse (non prouvée) : dans la VM un flux redémarré met 3 à 6 s à revenir, donc un chien de garde trop court le relance avant la fin. La durée de redémarrage d'un flux sur du matériel réel n'est pas connue.
- Trois exécutions de test ont produit des captures vides ou en retard de rendu avant restriction des événements déclencheurs ; le lien avec le sondage rapide n'est pas établi.

Limite de conception non traitée : chaque fenêtre qui contient du verre ouvre ses propres flux pour toutes les fenêtres visibles du workspace, ce qui multiplie le travail de capture et peut rester le goulot indépendamment du sondage. Pistes : restreindre la capture aux rectangles de verre réels, baisser la résolution du backdrop, ne capturer que lorsqu'un verre est visible.

## 16. Retour de test : rim artificiel, fenêtres noires, workspaces, formule

Retours du propriétaire :

- Le rim est trop prononcé : sur ses références, le bord vient de l'environnement (le fond qui se courbe), pas d'un trait dessiné.
- Les panneaux s'ouvrent noirs puis passent au clair.
- Au changement de workspace, le fond d'écran est capturé un instant.
- Je me suis éloigné de la formule de réfraction du repo, et elle est parfois appliquée de façon bizarre.

Changements :

- Rim et dégradé intérieur supprimés du shader et des réglages. L'ancien rim de `GlassRim` fond toujours quand le verre apparaît. La lueur d'origine du repo revient (`glowWeight 0.25`, `glowEdge0 0.5`, `glowEdge1 -0.5`).
- Réfraction : le déplacement le long de la normale est supprimé (la normale s'inverse sur les diagonales d'un carré, ce qui plie le résultat). `u_refractionMode` : 0 = formule d'origine telle quelle, 1 (défaut) = la même formule autour du cœur de la forme. Pour un rond ou un carré arrondi c'est identique à l'original ; la forme allongée n'étire plus ses extrémités. Sur le banc, le mode 0 montre des lignes répétées aux extrémités d'une pilule. Paramètres de réfraction conservés : `refractionB 2.8`, `refractionD 2.5`, `refractionPower 1.1` (les valeurs d'origine donnent des composants plats).
- Fenêtres noires : hypothèse (non vérifiée) : une `ScreencopyView` dessine du noir tant qu'elle n'a pas reçu sa première image. Chaque vue est maintenant invisible tant que `hasContent` est faux, un délai de 50 ms laisse les textures du backdrop se rendre avant le fondu, et le plafond d'attente passe de 500 ms à 2 s (le verre n'apparaît plus avant l'arrivée des fenêtres).
- Workspaces : mon hypothèse est que, au changement, les fenêtres du nouveau workspace démarrent leur capture à zéro et le backdrop ne montre que le fond d'écran. Le verre se remet donc en repli (teinte d'origine) sur `workspace`, `workspacev2`, `activespecial(v2)` et `focusedmon(v2)`, puis revient en fondu quand les flux sont prêts.

Vérifié :

- Banc de test : mode 1 sans rim (bords uniquement par réfraction), comparaison avec le mode 0 et avec les paramètres d'origine.
- VM : après un aller-retour de workspace (fenêtre sur le workspace 1, passage au 2, retour au 1), la capture finale est identique au pixel près à celle d'avant le départ (0 pixel différent sur 1 024 000), donc le verre retrouve la fenêtre et ne reste pas bloqué sur le fond d'écran.

Non vérifié :

- Les fenêtres noires et le flash du fond au changement de workspace n'ont pas pu être observés dans la VM (instants de quelques dizaines de millisecondes, VM lente) : les correctifs reposent sur les hypothèses ci-dessus.
- Sur le workspace 2, une première capture 60 s après le changement montrait la barre spotlight encore en repli (luminosité 64 contre 134 avant). Un second essai avec des journaux montre la porte de gating réinitialisée quatre fois (quatre événements Hyprland pour un changement) puis verrouillée environ 40 s plus tard dans la VM, alors que sa grâce est de 180 ms : le fil principal de Quickshell est saturé dans cette VM. La capture suivante montre le verre revenu (luminosité 134,4). Pas de défaut de logique constaté ; le délai réel sur matériel réel n'est pas mesuré.
- Sur un fond uniforme sombre (terminal), un verre sans rim n'a plus que la lueur d'origine pour définir son bord : il peut paraître plat. `glowWeight` augmente le contraste du bord.

## 17. Retour de test : verre noir uniforme après le commit précédent

Le propriétaire a signalé, avec capture, que le control center affichait toutes ses tuiles en noir opaque et uniforme (« la capture est cassée »), et précisé que le « noir » signalé plus tôt n'était pas un trou de capture mais le thème sombre du repli qui s'éclaircit à l'arrivée du verre.

Diagnostic de la capture : le noir est opaque et uniforme, alors que le repli de ces tuiles ne teinte qu'à 12 % de noir : le verre était donc actif et échantillonnait du noir. Le seul changement du commit précédent capable de produire cela sur un autre pilote que le mien est la lueur d'origine, `smoothstep(0.5, -0.5, dist)`, dont les bornes sont inversées (indéfini selon la spécification GLSL). Dans les versions testées avant, les bornes étaient dans l'ordre. Mon rendu logiciel calcule la formule prévue, mais un autre pilote peut renvoyer NaN, affiché en noir. Hypothèse non reproduite.

Changements :

- `GlowEdge()` calcule la même valeur sans comportement indéfini : si `edge0 > edge1`, `1 - smoothstep(edge1, edge0, x)`, identique mathématiquement. Vérifié sur un banc : 0 pixel de différence avec le rendu fait avec l'appel inversé.
- Teinte réduite et voile blanc appliqués immédiatement dès que le verre est voulu, au lieu de suivre le fondu du verre : l'élément est clair dès la première image, seule la réfraction apparaît ensuite en fondu. Cela supprime la phase sombre qui s'éclaircissait, et fait que l'attente (jusqu'à 2 s) ne se voit plus.
- `focusedmon(v2)` retiré des déclencheurs de transition : fréquent sur une configuration multi-écrans, il pouvait réinitialiser sans cesse la porte de gating et empêcher le verre de se stabiliser. Autre cause possible du verre inactif, non vérifiée.

Vérifié dans la VM : le shell charge sans erreur et le control center, spotlight et le dock rendent comme attendu. Non vérifié : le noir lui-même n'a pas pu être reproduit, la correction repose sur l'hypothèse ci-dessus ; aucun test sur le GPU du propriétaire.

## 18. Analyse d'une vidéo d'écran du propriétaire (ffmpeg)

Vidéo `recording.mkv` : 1366x768, 21,6 s, 1116 images (cadence moyenne 51,7 i/s, intervalle médian 17 ms, quelques trous de ~100 ms). Méthode : décodage sans duplication d'images (`-fps_mode passthrough`), détection des instants d'activité par différence entre images, puis luminosité moyenne de la zone du panneau image par image.

Constats :

- Popup batterie (ouverture à t0 = 6,05 s) : luminosité de la zone 130 avant ouverture, minimum 81,6 à +0,20 s, puis 121,8 à +0,30 s. Le popup est d'abord un gris-violet sombre et translucide, sans floutage (fond d'écran net à travers), pendant ~170 ms, puis le verre arrive d'un coup (saut de ~38 niveaux en ~60 ms).
- Spotlight (t0 = 14,15 s) : 141,8 → minimum 82,9 à +0,27 s → 131,8 à +0,37 s. Même schéma, ~200 ms de phase sombre.
- Control center : pas de creux, mais un saut de +6 à +0,27 s à l'activation du verre.
- Popup Wi-Fi : luminosité croissante sans creux. Dock : deux pics (+9 puis retour), les icônes montent sans fond pendant ~100 ms avant l'arrivée du fond en verre.
- Les deux bascules de workspace de la vidéo (0,8 s et 20,8 s) se font sans panneau ouvert : elles ne permettent pas d'observer le flash du fond d'écran dans le verre.

Cause dans le code (version qui précède ce correctif) : dans `BoxGlass`, la teinte atténuée dépendait de `backdrop !== null` ; or le backdrop n'est créé que lorsque la fenêtre est connue (relance toutes les 100 ms). Tant qu'il n'existe pas, l'élément garde sa teinte sombre complète, ce qui correspond à la durée mesurée. Le dock liait sa teinte, son voile et son ancien rim au niveau de fondu du verre, d'où le saut.

Changements : la teinte atténuée et le voile blanc ne dépendent plus que de `GlassSettings.enabled` et des propriétés de l'élément (couleur, transparence, taille) ; seule la réfraction apparaît en fondu. La taille nulle à la création n'écarte plus l'élément. Le backdrop est recherché dès qu'une taille, une visibilité ou une fenêtre change, avec une relance toutes les 16 ms. Le dock garde un voile constant et un rim d'origine désactivé quand le verre est actif.

Vérifié : rendu en régime stable identique au pixel près avant et après (0 pixel différent sur 1 024 000) dans la VM, chargement sans erreur. Non vérifié : la disparition de la phase sombre n'a pas pu être reproduite dans la VM (phénomène de quelques centaines de millisecondes) ; elle devra être confirmée en refaisant la même mesure sur une nouvelle vidéo. Je ne sais pas quelle révision tournait lors de l'enregistrement.
