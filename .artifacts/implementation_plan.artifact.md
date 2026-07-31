# Plan d'implémentation - Logo Haute Fidélité (Neon Cyberpunk)

Ce plan vise à recréer l'image du logo fournie en utilisant du code Flutter (`CustomPainter`) pour obtenir un rendu "parfait", indépendant de la résolution (vectoriel), et optimisé pour les performances.

## Modifications proposées

### 1. Refonte du `EyeLogo` (Design Haute Fidélité)
- **Structure Multi-Couches** : Dessiner plusieurs chemins concentriques pour simuler les "tubes néon" de la paupière.
- **Effets de Lueur (Glow)** : Utiliser des `MaskFilter.blur` successifs pour créer l'effet de halo magenta/violet intense.
- **Iris Électrique** : Recréer l'iris avec un dégradé radial cyan ultra-brillant et une texture de "fibre optique".
- **Pupille Glossy** : Ajouter des reflets spéculaires nets et des ombres portées pour un aspect 3D/verre.

### 2. Environnement Immersif
- **Particules/Étoiles** : Ajouter un générateur de particules aléatoires en arrière-plan pour simuler le "cosmos" visible dans l'image.
- **Reflet au Sol** : Intégrer un dégradé linéaire en bas du widget pour simuler la lumière se reflétant sur une surface.

### 3. Optimisation des Performances
- **Peinture Statique** : S'assurer que le `shouldRepaint` retourne `false` pour éviter des calculs inutiles si la taille ne change pas.
- **Calculs Pré-calculés** : Mettre en cache les chemins (`Path`) complexes.

## Détails Techniques

### [MODIFY] [eye_logo.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/shared/widgets/eye_logo.dart)
- Remplacement du dessin actuel par une implémentation multi-couches (Outer Glow, Neon Tubes, Iris Glow, Pupil, Specular).
- Ajout d'une boucle pour dessiner les "étoiles" en arrière-plan.

## Plan de vérification

### Tests Visuels
- [ ] Comparer le rendu du SplashScreen avec l'image originale.
- [ ] Vérifier que le logo reste net lors des changements d'échelle (size variable).
- [ ] Confirmer que l'effet de néon ne cause pas de ralentissements (jank) lors des transitions.

> [!NOTE]
> En utilisant du code pour dessiner le logo, nous garantissons une qualité "Rétina/4K" sans alourdir le poids de l'APK (0 octets d'images ajoutés).
