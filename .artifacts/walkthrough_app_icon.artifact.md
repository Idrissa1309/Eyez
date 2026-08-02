# Walkthrough - Mise à jour de l'icône de l'application

J'ai mis à jour l'icône de l'application avec votre nouveau logo personnalisé.

## Actions effectuées

### 1. Configuration de l'icône
- **Fichier source** : Utilisation de `assets/images/app_icon.jpg`.
- **Outil utilisé** : `flutter_launcher_icons` pour générer automatiquement toutes les tailles d'icônes requises par Android et iOS.
- **Fond Adaptatif** : Configuration d'un fond sombre (`#05050D`) pour correspondre au thème de l'application sur les versions récentes d'Android.

### 2. Génération automatique
- Exécution de la commande de génération qui a mis à jour les ressources natives :
    - `android/app/src/main/res/mipmap-*` pour Android.
    - `ios/Runner/Assets.xcassets/AppIcon.appiconset` pour iOS.

## Comment voir le changement ?

> [!IMPORTANT]
> Pour que le changement soit visible sur votre téléphone Oppo, vous devez effectuer un build complet et réinstaller l'application :
>
> 1. Désinstallez l'ancienne version de votre téléphone.
> 2. Lancez un nouveau build :
> ```bash
> flutter build apk --release --split-per-abi
> ```
> 3. Installez le nouvel APK.

L'icône "Eyez" devrait maintenant apparaître fièrement sur votre écran d'accueil !
