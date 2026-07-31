# Plan d'implémentation - Icônes Officielles, Filtrage Explorer et Diversité

Ce plan vise à rendre l'explorateur plus fonctionnel (filtrage par genre et plateforme), à corriger le manque de diversité des données dans l'explorateur, et à intégrer les icônes de marque avec leurs couleurs officielles.

## Modifications proposées

### 1. Enrichissement des Données et Filtrage
- **TMDB Service** :
    - Ajouter une méthode pour récupérer du contenu par **Genre**.
    - Améliorer la récupération pour inclure les plateformes de streaming même dans les listes simples.
- **Providers Explorer** :
    - Ajouter `selectedGenreProvider` (StateProvider).
    - Mettre à jour `filteredContentProvider` pour écouter le genre sélectionné.

### 2. Interface Explorateur (Explorer)
- **Genres** : Rendre les badges de genres cliquables pour filtrer la grille de tendances.
- **Plateformes** :
    - Utiliser les icônes officielles (Logos).
    - Rendre les logos cliquables pour naviguer vers la page de la chaîne (`PlatformChannelScreen`).
- **Diversité** : S'assurer que la grille de tendances affiche les langues et plateformes réelles au lieu d'un défaut "EN/Netflix".

### 3. Icônes de Marque (Auth & Explorer)
- **Google** : Créer un widget `GoogleColoredIcon` pour afficher le logo "G" avec ses 4 couleurs officielles.
- **Plateformes** : Utiliser des couleurs et icônes plus fidèles pour Netflix (Rouge), Disney+ (Bleu), Prime Video (Cyan/Bleu), Apple TV (Blanc/Gris).

## Détails Techniques

### [MODIFY] [tmdb_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/tmdb_service.dart)
- Ajouter `getMoviesByGenre(int genreId)`.
- Extraire la logique de "enrichissement plateforme" dans une méthode réutilisable pour que l'Explorateur en profite aussi.

### [MODIFY] [explorer_providers.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/explorer/presentation/providers/explorer_providers.dart)
- Ajouter la gestion de l'état du genre sélectionné.

### [MODIFY] [explorer_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/explorer/presentation/screens/explorer_screen.dart)
- Connecter l'UI aux nouveaux providers de filtrage.
- Ajouter la navigation vers les chaînes.

### [NEW] [BrandIcons](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/shared/widgets/brand_icons.dart)
- Créer un composant pour le logo Google multicolore.

## Plan de vérification

### Tests Manuels
- [ ] Vérifier que cliquer sur "Action" filtre les films pour n'afficher que de l'action.
- [ ] Vérifier que cliquer sur le logo Netflix ouvre la page Netflix.
- [ ] Confirmer que l'icône Google dans l'Auth est bien en 4 couleurs.
- [ ] Vérifier que l'Explorateur affiche maintenant des films en Chinois/Français/etc. comme l'Accueil.
