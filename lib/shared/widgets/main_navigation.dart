import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ambient_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../features/home/presentation/screens/video_feed_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'app_border_wrapper.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const ExplorerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ambientColor = ref.watch(ambientColorProvider);
    final selectedIndex = ref.watch(navigationIndexProvider);

    return AppBorderWrapper(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          height: 120, // Reduced to 120 to fix overflow and balance design
          color: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 10),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Custom Background and Glowing Wave Border
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 120),
                painter: _NavBarPainter(
                  color: AppColors.background.withValues(alpha: 0.95),
                  glowColor: ambientColor,
                ),
              ),
              
              // 2. Interactive Icons Layer
              Container(
                height: 65, // Standard height for alignment
                padding: const EdgeInsets.symmetric(horizontal: 45),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, CupertinoIcons.house, CupertinoIcons.house_fill, ambientColor, selectedIndex),
                    _buildCentralItem(ambientColor, selectedIndex),
                    _buildNavItem(2, CupertinoIcons.person_crop_circle, CupertinoIcons.person_crop_circle_fill, ambientColor, selectedIndex),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    Color accentColor,
    int selectedIndex,
  ) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(navigationIndexProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Center(
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.3),
            size: 26, 
          ),
        ),
      ),
    );
  }

  Widget _buildCentralItem(Color accentColor, int selectedIndex) {
    bool isSelected = selectedIndex == 1;
    return GestureDetector(
      onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 45), // Centered perfectly in the wave
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating Glow Halo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isSelected ? 0.5 : 0.2),
                    blurRadius: 35,
                    spreadRadius: 3,
                  ),
                ],
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Minimalist Neon Ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3), 
                  width: 1.5,
                ),
              ),
              child: OverflowBox(
                maxWidth: 110,
                maxHeight: 110,
                child: Image.asset(
                  'assets/icons/icon_transparent.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  _NavBarPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    const barH = 65.0; // Restored to 65 to fit screen perfectly
    final topY = h - barH;
    const margin = 20.0;

    path.moveTo(margin, h);
    path.lineTo(margin, topY + 20);
    path.quadraticBezierTo(margin, topY, margin + 20, topY);

    final centerX = w / 2;
    const waveW = 60.0;
    const waveH = 35.0;

    path.lineTo(centerX - waveW, topY);

    // THE WAVE (Perfectly symmetrical using cubic bezier)
    path.cubicTo(
      centerX - waveW * 0.75, topY,
      centerX - waveW * 0.75, topY - waveH,
      centerX, topY - waveH
    );
    path.cubicTo(
      centerX + waveW * 0.75, topY - waveH,
      centerX + waveW * 0.75, topY,
      centerX + waveW, topY
    );

    path.lineTo(w - margin - 20, topY);
    path.quadraticBezierTo(w - margin, topY, w - margin, topY + 20);

    path.lineTo(w - margin, h);
    path.close();

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor;
  }
}
