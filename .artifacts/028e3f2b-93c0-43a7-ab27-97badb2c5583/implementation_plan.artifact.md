# Plan d'implémentation - Correctifs Profil, Icones, Performances et Plateformes

Ce plan détaille les modifications nécessaires pour corriger l'affichage des favoris, mettre à jour les icônes de navigation, optimiser la fluidité de l'application et corriger les popups de chaînes.

## Revue Utilisateur Requise

> [!IMPORTANT]
> **Migration Supabase :** La table `likes` doit être mise à jour pour stocker les métadonnées des vidéos (titre, poster). Je vais fournir le script SQL, mais il devra être exécuté dans votre console Supabase si vous ne voulez pas perdre les affichages existants.

> [!NOTE]
> **Icônes :** L'augmentation de taille de 50% impactera la disposition de la barre de navigation. J'ajusterai les conteneurs pour maintenir l'équilibre visuel.

> [!TIP]
> **Popups de Chaînes :** Je vais ajouter le support pour HBO, Paramount+, Peacock, etc., et faire en sorte que si une chaîne n'est pas reconnue, elle affiche ses propres informations génériques plutôt que de se rabattre sur Netflix.

## Modifications Proposées

### 1. Correction des Favoris (Bug "Inconnus")

Le problème vient du fait que la table `likes` ne stocke que les IDs, alors que le profil a besoin des titres et des images pour l'affichage.

#### [SQL] [social_interact.sql](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/social_interact.sql)
Proposer la migration suivante :
```sql
ALTER TABLE likes ADD COLUMN IF NOT EXISTS tmdb_id INTEGER;
ALTER TABLE likes ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE likes ADD COLUMN IF NOT EXISTS poster_path TEXT;
```

#### [MODIFY] [supabase_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/supabase_service.dart)
- Modifier `toggleLike(String videoId)` en `toggleLike(Map<String, dynamic> movie)`.
- Insérer `tmdb_id`, `title` et `poster_path` lors de l'ajout d'un like.

#### [MODIFY] [video_feed_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/screens/video_feed_screen.dart) et [interaction_overlay.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/widgets/interaction_overlay.dart)
- Passer l'objet `movie` complet à `SupabaseService.toggleLike`.

---

### 2. Mise à jour des Icônes et Taille

#### [MODIFY] [main_navigation.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/shared/widgets/main_navigation.dart)
- Remplacer `icon_foreground.png` par `icon_transparent.png`.
- Augmenter la taille de l'icône centrale de 58 à 87 (+50%).
- Ajuster les dimensions du halo (`glow halo`) et du cercle néon pour s'adapter à la nouvelle taille.

#### [MODIFY] [pubspec.yaml](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/pubspec.yaml)
- Mettre à jour `adaptive_icon_foreground` pour pointer vers `assets/icons/icon_transparent.png`.

---

### 3. Correction du Popup des Chaines

#### [MODIFY] [platform_popup.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/widgets/platform_popup.dart)
- Ajouter les données pour "HBO", "Peacock Premium", "Paramount Plus", etc. dans `platformData`.
- Modifier la logique de fallback pour utiliser le nom réel de la plateforme passé en paramètre si elle n'est pas dans la liste prédéfinie, au lieu de forcer "Netflix".

#### [MODIFY] [brand_icons.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/shared/widgets/brand_icons.dart)
- Ajouter les URLs des logos pour les nouvelles plateformes supportées.

---

### 4. Optimisation des Performances

#### [MODIFY] [profile_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/profile/presentation/screens/profile_screen.dart)
- Remplacer `SingleChildScrollView` par `CustomScrollView`.
- Convertir les `GridView.builder` (avec `shrinkWrap: true`) en `SliverGrid` pour permettre le chargement paresseux (Lazy Loading) et améliorer la fluidité du défilement.

#### [MODIFY] [explorer_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/explorer/presentation/screens/explorer_screen.dart)
- Supprimer les usages de `shrinkWrap: true` dans les listes complexes pour optimiser le rendu.

## Plan de Vérification

### Tests Manuels
- Vérifier que l'ajout d'un favori affiche correctement le titre et l'image dans le profil.
- Confirmer que la barre de navigation affiche la nouvelle icône transparente en plus grand.
- Cliquer sur HBO, Paramount+, etc., et vérifier que le popup affiche les bonnes informations.
- Tester le défilement du profil pour valider le gain de fluidité.
