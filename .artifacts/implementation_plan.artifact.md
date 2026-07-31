# Plan d'implémentation - Optimisation du Lancement et Correction de l'Écran Noir

L'objectif est de réduire le temps de chargement initial et d'éliminer l'écran noir au démarrage en rendant l'initialisation non-bloquante et en optimisant les appels API.

## Modifications proposées

### 1. Optimisation TMDB
- **Parallélisation** : Utiliser `Future.wait` pour récupérer les détails des 15 vidéos tendances en parallèle au lieu de les récupérer séquentiellement. Cela devrait diviser le temps de chargement par ~10 sur une connexion rapide.

### 2. Initialisation Non-Bloquante
- **Splash Screen** : Introduire un `SplashScreen` qui s'affiche immédiatement.
- **Refactoring main.dart** : Déplacer l'initialisation de Supabase et Dotenv dans le `SplashScreen` ou un provider, permettant à Flutter de rendre le premier frame instantanément.

### 3. Gestion de l'état initial
- S'assurer que l'application ne reste pas bloquée si un service met du temps à répondre.

## Détails Techniques

### [MODIFY] [tmdb_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/tmdb_service.dart)
- Modifier `getTrendingWithVideos` pour utiliser `Future.wait`.

### [NEW] [SplashScreen](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/onboarding/presentation/screens/splash_screen.dart)
- Créer un écran de démarrage simple avec un logo et un indicateur de chargement.

### [MODIFY] [main.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/main.dart)
- Supprimer les `await` bloquants de `main()` (sauf `WidgetsFlutterBinding`).
- Utiliser `SplashScreen` comme `home` initial.

## Plan de vérification

### Tests Manuels
- [ ] Vérifier que l'application affiche un logo immédiatement après l'installation.
- [ ] Mesurer le temps de passage du logo à l'écran d'accueil/flux vidéo.
- [ ] Vérifier que l'application ne nécessite plus de redémarrage pour fonctionner.
