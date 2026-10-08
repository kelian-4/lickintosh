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
- Forme : le superellipse de l'original est normalisé par le quad, donc une barre large donne des extrémités en lentille. `powerFactor: 6.0` sur le dock atténue le problème (angles plus serrés, mais anisotropes) sans le supprimer. Une forme à rayon constant demanderait de modifier la SDF, donc les formules d'origine : décision à prendre.
- Syntaxe `hyprctl dispatch` de ce Hyprland (config Lua) : `hl.dsp.window.*({ ..., window = "address:0x..." })`. Les anciens dispatchers `movewindowpixel` etc. échouent.

## 7. Compatibilité avec l'API de BoxGlass

| BoxGlass | LiquidGlass | Remarque |
| --- | --- | --- |
| `color` (teinte translucide) | aucun équivalent | L'original n'a pas de teinte. Ajouter un mélange dans le shader ajoute une ligne de logique : à décider. |
| `radius` | aucun équivalent fidèle | Voir § 6, forme. `powerFactor` est le seul levier existant. |
| `light`, `lightDir`, `rimSize`, `rimStrength`, `highlightEnabled` | `glowWeight`, `glowBias`, `glowEdge0/1` | La lueur d'origine est une sinusoïde unique selon l'angle ; `lightDir` n'a pas d'équivalent. |
| `transparent` | aucun | Inutile : le verre n'a pas de fond propre. |

Migration en masse : non entamée. La question de la teinte et de la forme doit être tranchée avant.

## 8. Prochaines étapes proposées

1. Décider teinte et forme (§ 7).
2. Valider un second écran réel (control center : fenêtre plein écran à `(0,0)`, `exclusiveZone: -1`).
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
