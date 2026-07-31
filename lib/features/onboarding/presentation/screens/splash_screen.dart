import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import 'onboarding_screen.dart';
import '../../../../shared/widgets/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = "Démarrage...";
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();
    if (mounted) {
      setState(() {
      _status = "Chargement des configurations...";
      _showRetry = false;
    });
    }

    try {
      // 1. Load environment variables with timeout
      await dotenv.load(fileName: "assets/.env").timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (mounted) setState(() => _status = "Configuration lente...");
        },
      );
      
      if (mounted) setState(() => _status = "Connexion au serveur...");

      // 2. Initialize Supabase with timeout
      await SupabaseService.init().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          if (mounted) {
            setState(() {
            _status = "Connexion difficile...";
            _showRetry = true;
          });
          }
          throw TimeoutException('Supabase timeout');
        },
      );

      if (mounted) setState(() => _status = "Préparation de l'interface...");

      // 3. Ensure minimum visibility
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }

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
      if (mounted) {
        setState(() {
          _status = "Problème de connexion";
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
            // Styled Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.neonGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonFuchsia.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
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
                  "RÉESSAYER",
                  style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
