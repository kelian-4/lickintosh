# Left MenuBar Components

## Rôle du dossier
Ce dossier contient les composants spécifiques à la partie gauche de la Top Bar.

## Responsabilité dans le shell
Afficher le menu principal de type "Global Menu" de macOS, incluant le logo Apple, le nom de l'application active, et les actions de menu associées.

## Composants présents
- `MenuBar.qml` : Le layout horizontal (RowLayout) principal assemblant le menu.
- `ActiveWindow.qml` : Le label affichant le nom de la fenêtre actuellement au premier plan.

## État d'avancement
- L'affichage de la fenêtre active (`ActiveWindow.qml`) est fonctionnel via les signaux Wayland/Hyprland.
- Le reste des menus ("File", "Edit", etc.) sont des textes placeholders "en dur" (hardcoded).
- Le logo Apple est affiché via un caractère unicode (``).

## Dépendances utilisées
- `QtQuick`, `QtQuick.Layouts`
- `Quickshell.Hyprland` (pour la détection de la fenêtre active)

## Liens avec les autres modules
- Chargé dynamiquement par `ui/modules/TopBar.qml`.

## Conventions de code
- `Text.NativeRendering` pour tous les textes.
- Le formattage du nom de l'application (capitalisation ou extraction après un tiret) est contenu dans une fonction JS inline dans `ActiveWindow.qml`.

## Inspirations UI/macOS
- Reproduction exacte du layout de gauche de macOS (Logo Apple ➔ Nom de l'app en gras ➔ Menus d'actions réguliers).

## Problèmes connus
- Les menus sont factices et non interactifs.
- Pas de gestion réelle des Global Menus d'applications (DBusMenu, etc.).

## TODO potentiels
- Implémenter le support de `dbusmenu` (ou équivalent Wayland/Hyprland) pour afficher les vrais menus de l'application courante.
- Ajouter un effet de survol (hover) sur les éléments du menu.

## Notes techniques utiles
- L'approche pour formater le nom de l'application (`formatName` dans `ActiveWindow.qml`) montre un besoin pragmatique de rendre les noms d'app Wayland (souvent techniques) plus "user-friendly", comme "Finder" au lieu d'être vide sur le bureau.
