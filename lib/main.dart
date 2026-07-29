import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'shared/widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Critical: Could not load .env file');
  }
  
  await SupabaseService.init();
  
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
    // Determine the initial screen based on auth session
    final initialScreen = SupabaseService.currentUser != null 
      ? const MainNavigation() 
      : const OnboardingScreen();

    return MaterialApp(
      title: 'Eyez',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialScreen,
    );
  }
}
