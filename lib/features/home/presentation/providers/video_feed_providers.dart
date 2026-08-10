import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';

final tmdbVideoFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final videos = await service.getTrendingWithVideos();
  // Randomize the feed
  return videos..shuffle();
});
