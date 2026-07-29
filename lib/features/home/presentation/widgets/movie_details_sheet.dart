import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../profile/presentation/providers/my_list_providers.dart';

class MovieDetailsSheet extends ConsumerWidget {
  final dynamic movie;

  const MovieDetailsSheet({super.key, this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tmdbId = movie?['id'];
    final title = movie?['title'] ?? movie?['name'] ?? 'Inconnu';
    final rating = movie?['vote_average']?.toString() ?? '4,9';
    final voteCount = movie?['vote_count']?.toString() ?? '12.5k';
    final posterPath = movie?['poster_path'];
    final year = movie?['release_date']?.split('-')[0] ?? movie?['first_air_date']?.split('-')[0] ?? '2024';
    final synopsis = movie?['overview'] ?? 'Aucun synopsis disponible.';

    // Check if the movie is saved
    final isSaved = tmdbId != null && ref.watch(myListProvider.notifier).isSaved(tmdbId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: posterPath != null 
                    ? CachedNetworkImage(
                        imageUrl: '${TMDBService.imageBaseUrl}$posterPath',
                        width: 90,
                        height: 130,
                        fit: BoxFit.cover,
                      )
                    : Container(width: 90, height: 130, color: Colors.white10),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            rating,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($voteCount)',
                            style: const TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildDetailRow(Icons.calendar_today, 'Année', year),
            _buildDetailRow(Icons.language, 'Langue', movie?['original_language']?.toString().toUpperCase() ?? 'FR'),
            _buildPlatformRow('Netflix'),
            const SizedBox(height: 25),
            const Text(
              'Synopsis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              synopsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: NeonButton(
                    text: 'Regarder',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: isSaved ? AppColors.neonFuchsia.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSaved ? AppColors.neonFuchsia : Colors.white12),
                    ),
                    child: TextButton.icon(
                      onPressed: tmdbId == null ? null : () {
                        ref.read(myListProvider.notifier).toggleItem(movie);
                      },
                      icon: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border, 
                        color: isSaved ? AppColors.neonFuchsia : Colors.white70
                      ),
                      label: Text(
                        isSaved ? 'Retirer' : 'Ma Collection',
                        style: TextStyle(
                          color: isSaved ? AppColors.neonFuchsia : Colors.white, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPlatformRow(String platform) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, size: 20, color: Colors.redAccent),
          const SizedBox(width: 15),
          const Text('Plateforme', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const Spacer(),
          Text(platform, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
