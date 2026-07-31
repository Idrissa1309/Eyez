import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/brand_icons.dart';
import '../../../home/presentation/providers/interaction_providers.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';

class PlatformChannelScreen extends ConsumerWidget {
  final String platformName;

  const PlatformChannelScreen({super.key, required this.platformName});

  static const Map<String, Map<String, String>> platformData = {
    'Netflix': {
      'subscribers': '260M',
      'description': 'Netflix est un service de divertissement par abonnement de premier plan, proposant des films et des séries télévisées.',
      'url': 'https://www.netflix.com',
      'banner': 'https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?q=80&w=2069&auto=format&fit=crop',
    },
    'Disney+': {
      'subscribers': '150M',
      'description': 'Disney, Pixar, Marvel, Star Wars et National Geographic réunis.',
      'url': 'https://www.disneyplus.com',
      'banner': 'https://images.unsplash.com/photo-1633613286991-611fe299c4be?q=80&w=2070&auto=format&fit=crop',
    },
    'Amazon Prime Video': {
      'subscribers': '200M',
      'description': 'Profitez de films et séries exclusifs, ainsi que des avantages Amazon Prime.',
      'url': 'https://www.primevideo.com',
      'banner': 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?q=80&w=2070&auto=format&fit=crop',
    },
    'Apple TV+': {
      'subscribers': '50M',
      'description': 'Des histoires originales des esprits les plus créatifs de la télévision et du cinéma.',
      'url': 'https://tv.apple.com',
      'banner': 'https://images.unsplash.com/photo-1628155930542-3c7a64e2c833?q=80&w=1974&auto=format&fit=crop',
    },
    'Crunchyroll': {
      'subscribers': '12M',
      'description': 'Le leader mondial du streaming d\'animes, proposant la plus grande bibliothèque de titres.',
      'url': 'https://www.crunchyroll.com',
      'banner': 'https://images.unsplash.com/photo-1578632738981-433069c3a378?q=80&w=2070&auto=format&fit=crop',
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String normalizedName = platformData.keys.firstWhere(
      (k) {
        final key = k.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
        final name = platformName.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
        return key.contains(name) || name.contains(key);
      },
      orElse: () => platformName,
    );
    
    final data = platformData[normalizedName] ?? {
      'subscribers': '1M+',
      'description': 'Découvrez tout le contenu disponible sur $normalizedName.',
      'url': '',
      'banner': 'https://images.unsplash.com/photo-1485846234645-a62644f84728?q=80&w=2059&auto=format&fit=crop',
    };

    final followData = ref.watch(platformFollowStatusProvider(normalizedName));
    final isFollowing = followData.value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, normalizedName, data, isFollowing, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['description']!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Contenu populaire',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildPopularContent(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name, Map<String, String> data, bool isFollowing, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: data['banner']!,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  PlatformIcon(
                    name: name,
                    size: 60,
                    isCircular: true,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${data['subscribers']} abonnés',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildFollowButton(name, isFollowing, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(String name, bool isFollowing, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await SupabaseService.togglePlatformFollow(name);
        ref.invalidate(platformFollowStatusProvider(name));
        ref.invalidate(followedPlatformsProvider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white10 : AppColors.neonBlue,
          borderRadius: BorderRadius.circular(20),
          border: isFollowing ? Border.all(color: Colors.white24) : null,
        ),
        child: Text(
          isFollowing ? 'Suivi' : 'Suivre',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPopularContent(BuildContext context, WidgetRef ref) {
    final platformContent = ref.watch(platformContentProvider(platformName));
    
    return platformContent.when(
      data: (items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.7,
        ),
        itemCount: 6, // Limit for demo
        itemBuilder: (context, index) {
          final item = items[index];
          final posterPath = item['poster_path'];
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => MovieDetailsSheet(movie: item),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.surface,
                image: posterPath != null ? DecorationImage(
                  image: CachedNetworkImageProvider('${TMDBService.imageBaseUrl}$posterPath'),
                  fit: BoxFit.cover,
                ) : null,
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, s) => const SizedBox(),
    );
  }
}
