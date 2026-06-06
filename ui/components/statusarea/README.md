# Right StatusArea Components

## Rôle du dossier
Gérer et afficher les icônes système, les widgets et les contrôles sur la partie droite de la Top Bar.

## Responsabilité dans le shell
Agir comme la zone de notification (systray / status area) de macOS, affichant l'état du matériel (batterie, wifi, volume), l'horloge et des accès rapides.

## Composants présents
- `StatusArea.qml` : Conteneur principal (`RowLayout`) alignant tous les widgets.
- `Battery.qml` : Indicateur de niveau et d'état de charge de la batterie.
- `Clock.qml` : Horloge textuelle.
- `Volume.qml` : Indicateur du niveau de volume et du statut "Muted".
- `Wifi.qml` : Indicateur de signal réseau.

## État d'avancement
- Les widgets Batterie, Horloge et Volume sont avancés et réactifs grâce aux services intégrés de Quickshell.
- Le Wifi utilise un script Shell `nmcli` parsé manuellement (fonctionnel mais non natif).
- L'horloge est opérationnelle.
- Les icônes Spotlight (SEARCH), Control Center (CC) et AI sont de simples placeholders textuels pour l'instant.

## Dépendances utilisées
- `QtQuick`, `QtQuick.Layouts`, `QtQuick.VectorImage`
- `Quickshell.Services.UPower` (pour la batterie)
- `Quickshell.Services.Pipewire` (pour le volume)
- `Quickshell.Io` (`Process`, `SplitParser`, `StdioCollector` pour le Wifi)

## Liens avec les autres modules
- Importé asynchronement par `ui/modules/TopBar.qml`.
- Dépend lourdement des assets graphiques (`../../../assets/icons/` et polices `../../../assets/fonts/`).

## Conventions de code
- Chargement dynamique des images SVG via `VectorImage` et concaténation de chaines de caractères (`"battery-" + level + ".svg"`).
- Utilisation des `FontLoader` dans chaque composant (possible duplication).

## Inspirations UI/macOS
- Les icônes SVG sont des répliques des symboles macOS (SF Symbols).
- L'ordre des icônes respecte la disposition classique de macOS.

## Problèmes connus
- `FontLoader` est instancié plusieurs fois (`StatusArea.qml`, `Battery.qml`, `Volume.qml`), ce qui peut impacter légèrement les performances.
- Le composant `Wifi.qml` crée de multiples processus `nmcli` (polling), ce qui n'est pas optimal et peut consommer des ressources.

## TODO potentiels
- Remplacer l'approche `nmcli` par une intégration NetworkManager native via dbus ou un service Quickshell futur.
- Centraliser le chargement des polices dans une classe ou un fichier singleton.
- Remplacer les placeholders textuels par des icônes cliquables ouvrant des popup (menus).

## Notes techniques utiles
- La logique SVG dans `Battery.qml` (avec 10 niveaux + état de charge) démontre une grande attention au détail visuel.
- `VectorImage.CurveRenderer` est explicitement demandé pour optimiser le rendu SVG dans QtQuick.
