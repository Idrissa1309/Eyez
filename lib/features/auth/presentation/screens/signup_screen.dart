import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/social_button.dart';
import '../../../../shared/widgets/brand_icons.dart';
import '../../../../shared/widgets/main_navigation.dart';
import '../../../../shared/widgets/app_border_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _acceptTerms = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _handleSignup() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions d\'utilisation')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBorderWrapper(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rejoignez Eyez et découvrez\nun univers de contenus.',
                style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 50),
              
              // Input Fields
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Nom d\'utilisateur',
                  prefixIcon: Icon(Icons.person_outline, size: 22, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 22, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 22, 
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 22, 
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                      activeColor: AppColors.neonPurple,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'J\'accepte les ',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Conditions d\'utilisation',
                            style: TextStyle(color: AppColors.neonFuchsia, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'Politique de confidentialité',
                            style: TextStyle(color: AppColors.neonFuchsia, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
              else
                NeonButton(
                  text: 'S\'inscrire',
                  onPressed: _handleSignup,
                ),
              
              const SizedBox(height: 40),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('OU', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ),
                  Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                ],
              ),
              const SizedBox(height: 40),
              
              SocialButton(
                icon: const GoogleColoredIcon(),
                text: 'S\'inscrire avec Google',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              SocialButton(
                icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 19),
                text: 'S\'inscrire avec Apple',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              SocialButton(
                icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2), size: 19),
                text: 'S\'inscrire avec Facebook',
                onPressed: () {},
              ),
              
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ? ', style: TextStyle(color: Colors.white70)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: AppColors.neonPurple, 
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
