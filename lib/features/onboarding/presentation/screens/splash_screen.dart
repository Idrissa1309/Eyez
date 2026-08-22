import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../main.dart' show supabaseReady;
import 'onboarding_screen.dart';
import '../../../../shared/widgets/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Démarrage...';
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _status = 'Connexion au serveur...';
        _showRetry = false;
      });
    }

    try {
      // Wait for the Supabase init that was already kicked off in main().
      // This avoids a duplicate init call and saves the time between main()
      // and the first frame (~100-300 ms).
      await supabaseReady.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          if (mounted) {
            setState(() {
              _status = 'Connexion difficile...';
              _showRetry = true;
            });
          }
          throw TimeoutException('Supabase timeout');
        },
      );

      if (mounted) setState(() => _status = "Préparation de l'interface...");

      if (!mounted) return;

      final currentUser = SupabaseService.currentUser;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => currentUser != null
              ? const MainNavigation()
              : const OnboardingScreen(),
        ),
      );
    } catch (e) {
      // On retry, supabaseReady may have already completed (success or error).
      // If it failed, try a direct init as fallback.
      if (e is! TimeoutException) {
        try {
          await SupabaseService.init().timeout(const Duration(seconds: 12));
          if (!mounted) return;
          final currentUser = SupabaseService.currentUser;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => currentUser != null
                  ? const MainNavigation()
                  : const OnboardingScreen(),
            ),
          );
          return;
        } catch (_) {
          // Fall through to error UI
        }
      }
      if (mounted) {
        setState(() {
          _status = 'Problème de connexion';
          _showRetry = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.neonGradient,
              ),
              child: const Icon(
                Icons.remove_red_eye,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'EYEZ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            if (!_showRetry)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                ),
              )
            else
              TextButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
                label: const Text(
                  'RÉESSAYER',
                  style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
