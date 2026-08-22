import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/brand_icons.dart';
import '../../../profile/presentation/screens/platform_channel_screen.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';
import '../providers/interaction_providers.dart';

class PlatformPopup extends ConsumerWidget {
  final String platformName;
  final String? platformLogo;
  final String? channelId;

  const PlatformPopup({
    super.key, 
    required this.platformName,
    this.platformLogo,
    this.channelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(platformDetailsProvider(channelId ?? platformName));
    
    return detailsAsync.when(
      data: (details) => _buildContent(context, ref, details),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, s) => _buildContent(context, ref, {
        'name': platformName,
        'logo': platformLogo,
        'description': 'Erreur lors du chargement des détails.',
        'subscribers': 'N/A',
      }),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> details) {
    final String name = details['name'] ?? platformName;
    final String logoUrl = details['logo'] ?? platformLogo ?? '';
    final String subscribers = details['subscribers'] ?? 'N/A';
    final String description = details['description'] ?? '';

    final followData = ref.watch(platformFollowStatusProvider(name));
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
                    builder: (context) => PlatformChannelScreen(
                      platformName: name,
                      platformLogo: logoUrl,
                      channelId: channelId,
                    ),
                  ),
                );
              },
              child: PlatformIcon(
                name: name,
                imageUrl: logoUrl,
                size: 80,
                isCircular: true,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            if (subscribers != 'N/A')
              Text(
                '$subscribers abonnés',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            
            const SizedBox(height: 20),
            
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: () async {
                await SupabaseService.togglePlatformFollow(name);
                ref.invalidate(platformFollowStatusProvider(name));
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
                    builder: (context) => PlatformChannelScreen(
                      platformName: name,
                      platformLogo: logoUrl,
                      channelId: channelId,
                    ),
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
