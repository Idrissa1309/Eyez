import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/social_button.dart';
import '../../../../shared/widgets/main_navigation.dart';
import '../../../../shared/widgets/app_border_wrapper.dart';
import '../../../../shared/widgets/eye_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
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
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1462331940025-496dfbfc7564?q=80&w=2111&auto=format&fit=crop'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const EyeLogo(size: 140),
                const SizedBox(height: 10),
                const Text(
                  'Eyez',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Regardez autrement.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email ou pseudo',
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (_isLoading)
                  const CircularProgressIndicator(color: AppColors.neonCyan)
                else
                  NeonButton(
                    text: 'Se connecter',
                    onPressed: _handleLogin,
                  ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('OU', style: TextStyle(color: Colors.white38, fontSize: 14)),
                    ),
                    Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 40),
                SocialButton(
                  icon: Icons.g_mobiledata,
                  text: 'Continuer avec Google',
                  onPressed: () {},
                ),
                const SizedBox(height: 18),
                SocialButton(
                  icon: Icons.apple,
                  text: 'Continuer avec Apple',
                  onPressed: () {},
                ),
                const SizedBox(height: 18),
                SocialButton(
                  icon: Icons.facebook,
                  text: 'Continuer avec Facebook',
                  onPressed: () {},
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte ? ', style: TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'S\'inscrire',
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
      ),
    );
  }
}
