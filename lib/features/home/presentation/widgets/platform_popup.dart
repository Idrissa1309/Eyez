import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class PlatformPopup extends StatelessWidget {
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
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg', // SVG might need flutter_svg, using png fallback
    },
    'Amazon Prime Video': {
      'subscribers': '200M',
      'description': 'Profitez de films et séries exclusifs, ainsi que des avantages Amazon Prime.',
      'url': 'https://www.primevideo.com',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/1/11/Amazon_Prime_Video_logo.svg',
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
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/0/08/Crunchyroll_Logo.png',
    },
  };

  @override
  Widget build(BuildContext context) {
    // Get normalized name to match map
    final String normalizedName = platformData.keys.firstWhere(
      (k) => platformName.contains(k) || k.contains(platformName),
      orElse: () => 'Netflix',
    );
    
    final data = platformData[normalizedName]!;

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
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ),
            
            // Platform Logo
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.neonCyan, AppColors.neonBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  normalizedName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Name
            Text(
              normalizedName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            // Subscribers
            Text(
              '${data['subscribers']} abonnés',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Text(
              data['description']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            
            const SizedBox(height: 30),
            
            // Follow Button
            GestureDetector(
              onTap: () {
                // Future: Subscription logic
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF007BFF), const Color(0xFF00D2FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Suivre',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Link Button
            TextButton(
              onPressed: () async {
                final url = Uri.parse(data['url']!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
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
