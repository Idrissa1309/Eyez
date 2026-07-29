import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ambient_provider.dart';
import '../../features/home/presentation/screens/video_feed_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'app_border_wrapper.dart';
import 'eye_logo.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0; // Default to Accueil (Home)

  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const ExplorerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ambientColor = ref.watch(ambientColorProvider);

    return AppBorderWrapper(
      child: Scaffold(
        extendBody: true,
        body: _screens[_selectedIndex],
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: ambientColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ambientColor.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'ACCUEIL', ambientColor),
                _buildCentralItem(ambientColor),
                _buildNavItem(2, Icons.person_outline, 'PROFIL', ambientColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              icon,
              key: ValueKey('${icon}_$isSelected'),
              color: isSelected ? accentColor : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? accentColor : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralItem(Color accentColor) {
    //bool isSelected = _selectedIndex == 1;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
          gradient: RadialGradient(
            colors: [accentColor, Colors.transparent],
            stops: const [0.2, 1.0],
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EyeLogo(size: 28, showGlow: false),
            Text(
              'ŒIL FLOTTANT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 4.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
