import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMDBService {
  Dio get _dio {
    final key = dotenv.get('TMDB_API_KEY', fallback: '').trim();
    
    return Dio(BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      queryParameters: {
        'api_key': key,
        'language': 'fr-FR',
      },
    ));
  }

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<List<dynamic>> getTrending() async {
    try {
      final response = await _dio.get('/trending/all/day');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['status_message'] ?? e.message;
        throw Exception('TMDB API Error: $msg');
      }
      throw Exception('Failed to fetch trending: $e');
    }
  }

  Future<List<dynamic>> getPopularMovies() async {
    try {
      final response = await _dio.get('/movie/popular');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch popular movies: $e');
    }
  }

  Future<List<dynamic>> getPopularTVShows() async {
    try {
      final response = await _dio.get('/tv/popular');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch TV shows: $e');
    }
  }

  Future<List<dynamic>> getAnimes() async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_genres': '16', // Animation
      });
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch animes: $e');
    }
  }

  Future<List<dynamic>> getMusicContent() async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_genres': '10402', // Music
      });
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch music content: $e');
    }
  }

  Future<List<dynamic>> search(String query) async {
    try {
      final response = await _dio.get('/search/multi', queryParameters: {'query': query});
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to search: $e');
    }
  }

  Future<Map<String, dynamic>> getDetails(int id, String type) async {
    try {
      final response = await _dio.get('/$type/$id', queryParameters: {
        'append_to_response': 'videos,watch/providers',
      });
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingWithVideos() async {
    try {
      final trending = await getTrending();
      final List<Map<String, dynamic>> resultsWithVideos = [];

      // Fetch videos for the top 15 trending items to avoid too many requests
      for (var item in trending.take(15)) {
        final id = item['id'];
        final type = item['media_type'] ?? 'movie';
        
        try {
          final details = await getDetails(id, type);
          final videos = details['videos']?['results'] as List<dynamic>?;
          
          if (videos != null && videos.isNotEmpty) {
            // Find the best video (Trailer on YouTube)
            final trailer = videos.firstWhere(
              (v) => v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
              orElse: () => videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null),
            );

            if (trailer != null) {
              // Extract the first available streaming provider (FR region)
              final providers = details['watch/providers']?['results']?['FR']?['flatrate'] as List<dynamic>?;
              String? platformName;
              if (providers != null && providers.isNotEmpty) {
                platformName = providers.first['provider_name'];
              }

              resultsWithVideos.add({
                ...item,
                'video_key': trailer['key'],
                'platform': platformName ?? 'Netflix', // Default for demo if not found
                'accent_color': _getAccentColorForGenre(item['genre_ids']?.first),
              });
            }
          }
        } catch (e) {
          debugPrint('Error fetching videos for $id: $e');
          continue;
        }
      }
      return resultsWithVideos;
    } catch (e) {
      throw Exception('Failed to fetch trending with videos: $e');
    }
  }

  Color _getAccentColorForGenre(int? genreId) {
    if (genreId == null) return const Color(0xFF00D2FF); // Cyan
    
    // Map some genre IDs to colors
    switch (genreId) {
      case 28: return const Color(0xFFFF0000); // Action -> Red
      case 12: return const Color(0xFFFFA500); // Adventure -> Orange
      case 16: return const Color(0xFFFF2E93); // Animation -> Fuchsia
      case 35: return const Color(0xFFFFFF00); // Comedy -> Yellow
      case 80: return const Color(0xFF8B0000); // Crime -> Dark Red
      case 18: return const Color(0xFF9D44FF); // Drama -> Purple
      case 14: return const Color(0xFF00D2FF); // Fantasy -> Cyan
      case 27: return const Color(0xFF4A4A4A); // Horror -> Grey
      case 10749: return const Color(0xFFFF69B4); // Romance -> Pink
      case 878: return const Color(0xFF007BFF); // Science Fiction -> Blue
      default: return const Color(0xFF00D2FF);
    }
  }
}
