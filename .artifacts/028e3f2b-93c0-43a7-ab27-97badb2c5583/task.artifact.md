# Tâches - Correctifs Profil, Icones et Plateformes

- `[x]` **Correction des Favoris (Bug "Inconnus")**
    - `[x]` Mettre à jour `SupabaseService.toggleLike` pour enregistrer les métadonnées (`tmdb_id`, `title`, `poster_path`)
    - `[x]` Mettre à jour `SupabaseService.getLikedMovies` si nécessaire (déjà fait, il select tout)
    - `[x]` Mettre à jour `VideoFeedScreen` pour passer l'objet `movie` à `toggleLike`
    - `[x]` Mettre à jour `InteractionOverlay` pour passer l'objet `movie` à `toggleLike`
- `[x]` **Mise à jour des Icônes et Taille**
    - `[x]` Modifier `MainNavigation` : changer l'image en `icon_transparent.png`
    - `[x]` Augmenter la taille de l'icône centrale à 87 (de 58)
    - `[x]` Ajuster le `NavBarPainter` et les conteneurs de halo/neon pour la nouvelle taille
    - `[x]` Mettre à jour `pubspec.yaml` pour l'icône adaptative
- `[x]` **Correction du Popup des Chaines**
    - `[x]` Ajouter HBO, Paramount+, Peacock, etc. à `PlatformPopup.platformData`
    - `[x]` Améliorer la logique de fallback de `PlatformPopup` pour ne plus forcer Netflix
    - `[x]` Ajouter les logos correspondants dans `BrandIcons`
- `[x]` **Optimisation des Performances**
    - `[x]` Refactoriser `ProfileScreen` avec `CustomScrollView` et `SliverGrid`
    - `[x]` Nettoyer `ExplorerScreen` des `shrinkWrap: true` inutiles (en passant à `CustomScrollView`)
    - `[x]` Nettoyer `PlatformChannelScreen` des `shrinkWrap: true`
