import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/brand_icons.dart';
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
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg',
    },
    'Amazon Prime Video': {
      'subscribers': '200M',
      'description': 'Profitez de films et séries exclusifs, ainsi que des avantages Amazon Prime.',
      'url': 'https://www.primevideo.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Prime_Video.png',
    },
    'Apple TV+': {
      'subscribers': '50M',
      'description': 'Des histoires originales des esprits les plus créatifs de la télévision et du cinéma.',
      'url': 'https://tv.apple.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/2/28/Apple_TV_Plus_Logo.svg',
    },
    'Crunchyroll': {
      'subscribers': '12M',
      'description': 'Le leader mondial du streaming d\'animes, proposant la plus grande bibliothèque de titres.',
      'url': 'https://www.crunchyroll.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/0/08/Crunchyroll_Logo.svg',
    },
    'HBO': {
      'subscribers': '95M',
      'description': 'HBO propose les séries et films les plus acclamés par la critique, dont Game of Thrones et Succession.',
      'url': 'https://www.hbo.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/d/de/HBO_logo.svg',
    },
    'Paramount Plus': {
      'subscribers': '63M',
      'description': 'Une montagne de divertissement avec les films de Paramount, CBS et des séries originales.',
      'url': 'https://www.paramountplus.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Paramount_Plus.svg',
    },
    'Peacock Premium': {
      'subscribers': '30M',
      'description': 'Le service de streaming de NBCUniversal avec des sports en direct, des films et des séries cultes.',
      'url': 'https://www.peacocktv.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Peacock_Logo.svg',
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? foundKey;
    try {
      foundKey = platformData.keys.firstWhere(
        (k) {
          final key = k.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
          final name = platformName.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
          return key.contains(name) || name.contains(key);
        },
      );
    } catch (_) {
      foundKey = null;
    }

    final String normalizedName = foundKey ?? platformName;
    
    final data = foundKey != null ? platformData[foundKey]! : {
      'subscribers': 'N/A',
      'description': 'Découvrez les contenus exclusifs de $platformName sur Eyez.',
      'url': '',
      'logo': '',
    };
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
            
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlatformChannelScreen(platformName: normalizedName),
                  ),
                );
              },
              child: PlatformIcon(
                name: normalizedName,
                size: 80,
                isCircular: true,
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
