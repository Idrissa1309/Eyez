# Plan d'implémentation - Mise à jour de l'icône de l'application

Ce plan détaille la procédure pour remplacer l'icône par défaut de Flutter par le nouveau logo "Eyez" haute résolution que nous avons généré.

## Modifications proposées

### 1. Préparation de l'Asset
- **Action** : Copier le logo généré (`app_logo.png`) vers le dossier `assets/images/app_icon.png`.
- **Raison** : Pour que l'outil de génération puisse y accéder de manière permanente.

### 2. Configuration de l'automatisation
- **Outil** : Utiliser le package `flutter_launcher_icons`.
- **Ajout Dépendance** : Ajouter `flutter_launcher_icons: ^0.13.1` dans les `dev_dependencies` du fichier `pubspec.yaml`.
- **Paramétrage** : Ajouter le bloc de configuration dans `pubspec.yaml` pour cibler Android et iOS.

### 3. Génération des icônes
- **Commande** : Exécuter `flutter pub get` suivi de `flutter pub run flutter_launcher_icons`.
- **Résultat** : Cela va générer automatiquement toutes les tailles d'icônes nécessaires pour Android (mipmaps) et iOS (AppIcon).

## Détails Techniques

### [MODIFY] [pubspec.yaml](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/pubspec.yaml)
- Ajout de la dépendance de développement.
- Ajout de la configuration :
  ```yaml
  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/images/app_icon.png"
    adaptive_icon_background: "#05050D" # AppColors.background
    adaptive_icon_foreground: "assets/images/app_icon.png"
  ```

## Plan de vérification

### Tests Manuels
- [ ] Vérifier que l'icône de l'application sur le bureau du téléphone Oppo a bien changé.
- [ ] Vérifier l'apparence de l'icône dans le sélecteur d'applications (multitâche).

> [!IMPORTANT]
> Après l'exécution, il est conseillé de désinstaller et réinstaller l'application sur le téléphone pour s'assurer que le cache des icônes d'Android soit bien mis à jour.
