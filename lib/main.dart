import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

/// Completer signalled when Supabase.initialize() finishes (success or failure).
/// The splash screen awaits this instead of calling SupabaseService.init() itself,
/// so the init starts as early as possible – before the first frame is painted.
late final Future<void> supabaseReady;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env synchronously (< 50 ms) – required before Supabase init.
  await dotenv.load(fileName: 'assets/.env');

  // Kick off Supabase init immediately (runs in parallel with widget tree build).
  // We intentionally do NOT await here – the splash screen will await [supabaseReady].
  supabaseReady = SupabaseService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyez',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
