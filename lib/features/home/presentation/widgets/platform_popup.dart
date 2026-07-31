import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/screens/platform_channel_screen.dart';
import '../providers/interaction_providers.dart';

class PlatformPopup extends ConsumerWidget {
  final String platformName;

  const PlatformPopup({super.key, required this.platformName});

  static const Map<String, Map<String, String>> platformData = {
    'Netflix': {
      'subscribers': '260M',
      'description': 'Netflix est un service de divertissement par abonnement de premier plan, proposant des films et des séries télévisées.',
      'url': 'https://www.netflix.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/f/ff/Netflix-new-icon.png',
    },
    'Disney+': {
      'subscribers': '150M',
      'description': 'Disney, Pixar, Marvel, Star Wars et National Geographic réunis.',
      'url': 'https://www.disneyplus.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg', // SVG might be tricky, use PNG if possible
    },
    // ...
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String normalizedName = platformData.keys.firstWhere(
      (k) => platformName.contains(k) || k.contains(platformName),
      orElse: () => 'Netflix',
    );
    
    final data = platformData[normalizedName]!;
    final followData = ref.watch(platformFollowStatusProvider(normalizedName));
    final isFollowing = followData.value ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ),
            
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isFollowing 
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [AppColors.neonCyan, AppColors.neonBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFollowing ? Colors.black : AppColors.neonCyan).withValues(alpha: 0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  child: Text(
                    normalizedName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              normalizedName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            Text(
              '${data['subscribers']} abonnés',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              data['description']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: () async {
                await SupabaseService.togglePlatformFollow(normalizedName);
                ref.invalidate(platformFollowStatusProvider(normalizedName));
                ref.invalidate(followedPlatformsProvider);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: isFollowing 
                      ? null 
                      : const LinearGradient(
                          colors: [Color(0xFF007BFF), Color(0xFF00D2FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: isFollowing ? Colors.white10 : null,
                  borderRadius: BorderRadius.circular(15),
                  border: isFollowing ? Border.all(color: Colors.white10) : null,
                  boxShadow: isFollowing ? const [] : [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFollowing) const Icon(Icons.check, color: Colors.white70, size: 18),
                      if (isFollowing) const SizedBox(width: 8),
                      Text(
                        isFollowing ? 'Suivi' : 'Suivre',
                        style: TextStyle(
                          color: isFollowing ? Colors.white70 : Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlatformChannelScreen(platformName: normalizedName),
                  ),
                );
              },
              child: const Text(
                'Voir la plateforme',
                style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
