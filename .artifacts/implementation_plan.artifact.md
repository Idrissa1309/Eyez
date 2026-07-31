# Plan d'implémentation - Finalisation des Paramètres

Ce plan détaille l'implémentation des fonctionnalités manquantes dans l'écran des paramètres, notamment la gestion sécurisée du changement de mot de passe, les informations "À propos" et le support.

## Modifications proposées

### 1. Sécurisation du Changement de Mot de Passe
- **Vérification** : Ajouter une étape de vérification de l'ancien mot de passe avant d'autoriser la modification.
- **Logique** : Utiliser la méthode `signIn` de Supabase avec l'email actuel et l'ancien mot de passe pour confirmer l'identité.
- **UI** : Mettre à jour le dialogue pour inclure trois champs : Ancien mot de passe, Nouveau mot de passe, Confirmation.

### 2. Section "À propos"
- **Contenu** : Afficher un modal ou un dialogue précisant que l'application est développée par **Idrissa Sow** et **Ousmane Sow**.
- **Design** : Utiliser un style épuré avec le logo de l'application.

### 3. Support & Aide
- **Lien externe** : Configurer le bouton "Aide et support" pour ouvrir le site [https://autorunsite.netlify.app](https://autorunsite.netlify.app) via `url_launcher`.

### 4. Autres fonctionnalités (Général)
- **Thème & Notifications** : Ajouter des messages informatifs ou des dialogues simples pour indiquer que ces fonctionnalités sont gérées automatiquement par le système pour le moment.

## Détails Techniques

### [MODIFY] [supabase_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/supabase_service.dart)
- Ajouter une méthode `verifyPassword(String password)` qui tente une re-connexion silencieuse.

### [MODIFY] [settings_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/profile/presentation/screens/settings_screen.dart)
- Implémenter `_showAbout`.
- Mettre à jour `_showChangePassword` avec la nouvelle logique de validation.
- Connecter le bouton Support à `url_launcher`.

## Plan de vérification

### Tests Manuels
- [ ] Tenter de changer le mot de passe avec un mauvais "ancien mot de passe" (doit échouer).
- [ ] Vérifier que le changement fonctionne avec le bon ancien mot de passe.
- [ ] Cliquer sur "À propos" et vérifier les noms des développeurs.
- [ ] Cliquer sur "Aide et support" et vérifier l'ouverture du navigateur.
- [ ] Vérifier que la réduction de taille (33%) est préservée dans les nouveaux éléments.
