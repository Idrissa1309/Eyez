import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../shared/widgets/app_border_wrapper.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfile(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    final usernameController = TextEditingController(text: user?.userMetadata?['username'] ?? '');
    final bioController = TextEditingController(); // In a real app, fetch bio from profile provider
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('INFORMATIONS DU PROFIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 33,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      await picker.pickImage(source: ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: AppColors.neonCyan, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(hintText: 'Pseudo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                style: const TextStyle(fontSize: 11),
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Bio'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 37,
                child: NeonButton(
                  text: 'Enregistrer',
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await SupabaseService.updateProfile(
                      username: usernameController.text.trim(),
                      bio: bioController.text.trim(),
                    );
                    ref.invalidate(profileDataProvider);
                    navigator.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('MODIFIER MOT DE PASSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(fontSize: 10),
              decoration: const InputDecoration(hintText: 'Ancien mot de passe'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(fontSize: 10),
              decoration: const InputDecoration(hintText: 'Nouveau mot de passe'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              style: const TextStyle(fontSize: 10),
              decoration: const InputDecoration(hintText: 'Confirmer nouveau'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('ANNULER', style: TextStyle(fontSize: 9, color: Colors.white54))
          ),
          TextButton(
            onPressed: () async {
              final old = oldPasswordController.text.trim();
              final pass = newPasswordController.text.trim();
              final conf = confirmController.text.trim();

              if (old.isEmpty || pass.isEmpty || conf != pass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vérifiez vos informations', style: TextStyle(fontSize: 10)))
                );
                return;
              }

              final isValid = await SupabaseService.verifyPassword(old);
              if (isValid) {
                await SupabaseService.updatePassword(pass);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe mis à jour', style: TextStyle(fontSize: 10)))
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ancien mot de passe incorrect', style: TextStyle(fontSize: 10)))
                  );
                }
              }
            }, 
            child: const Text('VALIDER', style: TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('À PROPOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonCyan),
              child: const Icon(Icons.remove_red_eye, color: Colors.black, size: 24),
            ),
            const SizedBox(height: 15),
            const Text(
              'EYEZ v1.0.0',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cette application est développée par\nIdrissa Sow et Ousmane Sow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9, height: 1.5),
            ),
            const SizedBox(height: 15),
            const Text(
              '© 2026 EYEZ Team',
              style: TextStyle(color: Colors.white24, fontSize: 8),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('FERMER', style: TextStyle(fontSize: 9, color: AppColors.neonCyan))
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupport() async {
    final url = Uri.parse('https://autorunsite.netlify.app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBorderWrapper(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'PARAMÈTRES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          children: [
            _buildSectionHeader('Mon Compte'),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Informations du profil',
              onTap: () => _showEditProfile(context, ref),
            ),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              onTap: () => _showChangePassword(context),
            ),
            const SizedBox(height: 15),
            _buildSectionHeader('Général'),
            _buildSettingItem(
              icon: Icons.palette_outlined,
              title: 'Thème',
              trailing: const Text('Sombre', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le thème sombre est activé par défaut', style: TextStyle(fontSize: 9)))
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications système gérées par l\'appareil', style: TextStyle(fontSize: 9)))
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.language_outlined,
              title: 'Langue',
              trailing: const Text('Français', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Support'),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Aide et support',
              onTap: _launchSupport,
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'À propos',
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 35),
            _buildSettingItem(
              icon: Icons.logout,
              title: 'Se déconnecter',
              titleColor: Colors.redAccent,
              showArrow: false,
              onTap: () async {
                final navigator = Navigator.of(context);
                await SupabaseService.signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 7, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.neonCyan,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    Color? titleColor,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          onTap: onTap,
          dense: true,
          leading: Icon(icon, color: titleColor ?? Colors.white70, size: 15),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing ?? (showArrow ? const Icon(Icons.arrow_forward_ios, size: 9, color: AppColors.textSecondary) : null),
        ),
      ),
    );
  }
}
