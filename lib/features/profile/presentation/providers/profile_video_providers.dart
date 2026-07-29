import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';

final profileVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final popular = await service.getPopularMovies();
  final List<Map<String, dynamic>> resultsWithVideos = [];

  for (var item in popular.take(12)) {
    try {
      final details = await service.getDetails(item['id'], 'movie');
      final videos = details['videos']?['results'] as List<dynamic>?;
      
      if (videos != null && videos.isNotEmpty) {
        final trailer = videos.firstWhere(
          (v) => v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
          orElse: () => videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null),
        );

        if (trailer != null) {
          resultsWithVideos.add({
            ...item,
            'video_key': trailer['key'],
            'accent_color': const Color(0xFFFF2E93),
          });
        }
      }
    } catch (_) {
      continue;
    }
  }
  return resultsWithVideos;
});
