import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/app_border_wrapper.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Découvrez.',
      description: 'Explorez des films, séries, animes et musiques à travers des vidéos courtes et immersives.',
      imagePath: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=2072&auto=format&fit=crop',
      icon: Icons.remove_red_eye_outlined,
    ),
    OnboardingItem(
      title: 'Interagissez.',
      description: 'Aimez, commentez, sauvegardez et partagez vos contenus préférés en un seul geste.',
      imagePath: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?q=80&w=2059&auto=format&fit=crop',
      icon: Icons.favorite_border,
    ),
    OnboardingItem(
      title: 'Créez votre univers.',
      description: 'Suivez vos goûts, créez vos listes et retrouvez tout votre univers au même endroit.',
      imagePath: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?q=80&w=2144&auto=format&fit=crop',
      icon: Icons.bookmark_border,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBorderWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            // Background Images PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _items[index].imagePath,
                      fit: BoxFit.cover,
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.4),
                            AppColors.background.withValues(alpha: 0.8),
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Header (Skip button)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Passer',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 60,
              left: 30,
              right: 30,
              child: Column(
                children: [
                  // Icon with circle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(_items[_currentIndex].icon, color: Colors.white, size: 35),
                  ),
                  const SizedBox(height: 35),
                  Text(
                    _items[_currentIndex].title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      _items[_currentIndex].description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Indicators
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _items.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color(0xFF9D44FF), // Purple stop from gradient
                      dotColor: Colors.white24,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 45),
                  // Button
                  NeonButton(
                    text: _currentIndex == _items.length - 1 ? 'Commencer' : 'Suivant',
                    onPressed: () {
                      if (_currentIndex < _items.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
