import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeService {
  final _yt = YoutubeExplode();

  Future<List<Map<String, dynamic>>> getCinematicVideos() async {
    try {
      // Search for high-quality cinematic content
      final searchList = await _yt.search.search(
        'official movie trailers 4K',
        filter: TypeFilters.video,
      );

      final List<Map<String, dynamic>> results = [];
      
      // Take first 10 results to avoid over-fetching
      for (final video in searchList.take(10)) {
        results.add({
          'id': video.id.value,
          'tmdb_id': video.id.value, // Compatibility
          'title': video.title,
          'overview': video.description,
          'video_key': video.id.value,
          'poster_path': null, // Use thumbnail instead
          'backdrop_path': video.thumbnails.highResUrl,
          'thumbnail_url': video.thumbnails.highResUrl,
          'accent_color': Colors.blueAccent,
          'platform': video.author,
          'platforms': [video.author],
          'original_language_name': 'YouTube',
          'is_youtube_direct': true,
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('YouTube Service Error: $e');
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }
}
