import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';
import '../../../../core/services/youtube_service.dart';

final youtubeServiceProvider = Provider((ref) => YouTubeService());

/// In-memory cache for direct video URLs (MP4) to avoid re-resolving YouTube keys.
final resolvedVideoUrlsProvider = StateProvider<Map<String, String>>((ref) => {});

final tmdbVideoFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  final ytService = ref.watch(youtubeServiceProvider);
  
  // Fetch from both providers in parallel
  final results = await Future.wait([
    tmdbService.getTrendingWithVideos(),
    ytService.getCinematicVideos(),
  ]);

  final List<Map<String, dynamic>> combinedVideos = [
    ...results[0],
    ...results[1],
  ];

  // Randomize the feed
  return combinedVideos..shuffle();
});
