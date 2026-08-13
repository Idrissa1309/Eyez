import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/brand_icons.dart';
import '../../../../core/constants/platform_constants.dart';
import '../../../home/presentation/providers/interaction_providers.dart';
import '../../../home/presentation/widgets/movie_details_sheet.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';

class PlatformChannelScreen extends ConsumerWidget {
  final String platformName;
  final String? platformLogo;

  const PlatformChannelScreen({
    super.key, 
    required this.platformName,
    this.platformLogo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? foundKey = PlatformConstants.findKey(platformName);
    final String normalizedName = foundKey ?? platformName;
    
    final data = foundKey != null 
        ? PlatformConstants.platformData[foundKey]! 
        : PlatformConstants.getFallbackData(platformName);

    final String logoUrl = (foundKey != null ? data['logo'] : platformLogo) ?? '';

    final followData = ref.watch(platformFollowStatusProvider(normalizedName));
    final isFollowing = followData.value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, normalizedName, data, logoUrl, isFollowing, ref),
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
                ],
              ),
            ),
          ),
          _buildSliverPopularContent(context, ref),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name, Map<String, String> data, String logoUrl, bool isFollowing, WidgetRef ref) {
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
                    imageUrl: logoUrl,
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
                        if (data['subscribers'] != 'N/A')
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

  Widget _buildSliverPopularContent(BuildContext context, WidgetRef ref) {
    final platformContent = ref.watch(platformContentProvider(platformName));
    
    return platformContent.when(
      data: (items) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            childCount: items.length > 6 ? 6 : items.length, // Limit for demo
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan))),
      error: (e, s) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }
}
