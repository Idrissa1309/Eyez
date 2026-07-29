import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('INFORMATIONS DU PROFIL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      await picker.pickImage(source: ImageSource.gallery);
                      // Future: Upload logic
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.neonCyan, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(hintText: 'Pseudo'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Bio'),
              ),
              const SizedBox(height: 30),
              NeonButton(
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
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('CHANGER LE MOT DE PASSE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Nouveau mot de passe'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirmer'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(
            onPressed: () async {
              if (passwordController.text == confirmController.text) {
                await SupabaseService.updatePassword(passwordController.text);
                if (context.mounted) Navigator.pop(context);
              }
            }, 
            child: const Text('VALIDER', style: TextStyle(color: AppColors.neonCyan))
          ),
        ],
      ),
    );
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            const SizedBox(height: 20),
            _buildSectionHeader('Général'),
            _buildSettingItem(
              icon: Icons.palette_outlined,
              title: 'Thème',
              trailing: const Text('Sombre', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.language_outlined,
              title: 'Langue',
              trailing: const Text('Français', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {},
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('Support'),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Aide et support',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'À propos',
              onTap: () {},
            ),
            const SizedBox(height: 50),
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
      padding: const EdgeInsets.only(left: 10, bottom: 15),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.neonCyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
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
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: titleColor ?? Colors.white70, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing ?? (showArrow ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary) : null),
        ),
      ),
    );
  }
}
